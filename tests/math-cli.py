# Run after building: python3 tests/math-cli.py /path/to/QLMarkdown.app
import gzip
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

app = pathlib.Path(sys.argv[1]).resolve()
cli = app / 'Contents/Resources/qlmarkdown_cli'


def run(*args, bundle=app):
    return subprocess.check_output([
        str(cli), '--app', str(bundle), '--syntax-highlight', 'off', '--about', 'off',
        '--debug', 'off', '--mermaid-renderer', 'pele', *args
    ], text=True)


def options(html):
    payload = html.split('const qlmarkdownMathOptions = ', 1)[1]
    value, end = json.JSONDecoder().raw_decode(payload)
    assert '<' not in payload[:end], 'Library text must not close the script'
    return value


for renderer, version in [('temml', '0.14.0'), ('mathjax', '4.1.3')]:
    output = run('--show-settings', '--math-renderer', renderer, '--math', 'embed')
    assert f'--math-renderer: {renderer}' in output
    assert f'--math: embedded ({version})' in output
invalid = subprocess.run([str(cli), '--math-renderer', 'invalid'], capture_output=True)
assert invalid.returncode != 0

with tempfile.TemporaryDirectory() as directory:
    source = pathlib.Path(directory) / 'math.md'
    source.write_text(r'''Prices: $1.50 and $7.89. Code: `$x$`.

Inline: $x^2$ and $a < b$.

$$\frac{a}{b}$$

```math
\sqrt{x}
```
''')
    body = source.read_text()
    diagram = '\n```mermaid\ngraph LR\nA["$$x^2$$"] --> B\n```\n'
    for renderer in ['temml', 'mathjax']:
        for mode in ['link', 'embed']:
            html = run('--math-renderer', renderer, '--math', mode, '--mermaid', 'off', str(source))
            assert '$1.50 and $7.89' in html and '<code>$x$</code>' in html
            if renderer == 'temml':
                assert 'MathJax-script' not in html and 'MathJax =' not in html
                assert '<span class=\'hl math\'>$x^2$</span>' in html
                assert 'renderTemmlMath();' in html
                config = options(html)
                assert ('mathCode' in config) == (mode == 'embed')
                if mode == 'embed':
                    expected = gzip.decompress((app / 'Contents/Resources/temml.min.js.gz').read_bytes()).decode()
                    assert config['mathCode'] == expected
            else:
                assert 'MathJax-script' in html and 'MathJax =' in html
                assert '<span class=\'hl math\'>\\(x^2\\)</span>' in html
                assert 'const qlmarkdownMathOptions' not in html
            print('PASS body renderer and mode:', renderer, mode)

    source.write_text(body + diagram)
    for math_mode in ['off', 'link', 'embed']:
        for diagram_mode in ['off', 'link', 'embed']:
            html = run('--math-renderer', 'temml', '--math', math_mode, '--mermaid', diagram_mode, str(source))
            active = math_mode != 'off' or diagram_mode != 'off'
            assert html.count('const qlmarkdownMathOptions = ') == int(active)
            assert 'MathJax-script' not in html
            assert ('renderTemmlMath();' in html) == (math_mode != 'off')
            if active:
                assert ('mathCode' in options(html)) == ('embed' in (math_mode, diagram_mode))
    html = run('--math-renderer', 'mathjax', '--math', 'embed', '--mermaid', 'embed', str(source))
    assert 'MathJax-script' in html and 'renderTemmlMath();' not in html
    assert options(html)['mathCode']
    assert "elements: ['span.hl.math, div.hl.math']" in html
    print('PASS independent body/diagram switches and shared Temml loading modes')

    for content in ['Prices: $1.50 and $7.89. Code: `$x$`.', 'Just text.']:
        source.write_text(content)
        html = run('--math-renderer', 'temml', '--math', 'embed', '--mermaid', 'off', str(source))
        assert 'const qlmarkdownMathOptions' not in html and 'MathJax-script' not in html
    source.write_text(body)
    html = run('--math-renderer', 'temml', '--math', 'embed', '--render-as-code', 'on', str(source))
    assert 'const qlmarkdownMathOptions' not in html and 'MathJax-script' not in html
    print('PASS currency/code/plain text do not load a math engine')

    fake = pathlib.Path(directory) / 'MissingMathRenderer.app' / 'Contents'
    resources = fake / 'Resources'
    resources.mkdir(parents=True)
    shutil.copy2(app / 'Contents/Info.plist', fake / 'Info.plist')
    for resource in (app / 'Contents/Resources').iterdir():
        if resource.name != 'math-renderer.js':
            (resources / resource.name).symlink_to(resource, target_is_directory=resource.is_dir())
    html = run('--math-renderer', 'temml', '--math', 'embed', '--mermaid', 'off', str(source), bundle=fake.parent)
    assert 'Unable to render formula: Temml is unavailable' in html
    assert 'MathJax-script' not in html and 'MathJax =' not in html
    print('PASS missing Temml renderer reports an error without MathJax fallback')
