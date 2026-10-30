# Run after building: python3 tests/mermaid-cli.py /path/to/QLMarkdown.app
import pathlib
import json
import gzip
import shutil
import subprocess
import sys
import tempfile
from html.parser import HTMLParser


class DiagramSource(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.inside = False
        self.source = ''

    def handle_starttag(self, tag, attrs):
        if tag == 'div' and ('class', 'mermaid') in attrs:
            self.inside = True
        elif self.inside:
            raise AssertionError('Diagram source became an HTML element: ' + tag)

    def handle_endtag(self, tag):
        if tag == 'div':
            self.inside = False

    def handle_data(self, data):
        if self.inside:
            self.source += data


app = pathlib.Path(sys.argv[1]).resolve()
cli = app / 'Contents/Resources/qlmarkdown_cli'
for renderer, version in [('pele', '1.12.0'), ('mermaid', '12.0.0')]:
    output = subprocess.check_output([
        str(cli), '--app', str(app), '--show-settings', '--mermaid', 'embed', '--mermaid-renderer', renderer
    ], text=True)
    assert f'--mermaid: embedded ({version})' in output
    print('PASS embedded settings reflect selected renderer:', renderer)
source = 'flowchart LR\nA["First<br/>Second &amp; <b>Bold</b>"] --> B["</code></pre><img src=x>"]\n'
with tempfile.TemporaryDirectory() as directory:
    markdown = pathlib.Path(directory) / 'labels.md'
    fake_app = pathlib.Path(directory) / 'MissingRenderer.app' / 'Contents'
    fake_resources = fake_app / 'Resources'
    fake_resources.mkdir(parents=True)
    shutil.copy2(app / 'Contents/Info.plist', fake_app / 'Info.plist')
    for resource in (app / 'Contents/Resources').iterdir():
        if resource.name != 'mermaid-renderer.js':
            (fake_resources / resource.name).symlink_to(resource, target_is_directory=resource.is_dir())
    markdown.write_text('```mermaid\ngraph LR\nA-->B\n```\n')
    for mode in ['link', 'embed']:
        html = subprocess.check_output([
            str(cli), '--app', str(fake_app.parent), '--mermaid', mode, '--mermaid-renderer', 'pele',
            '--syntax-highlight', 'off', '--math', 'off', '--about', 'off', str(markdown)
        ], text=True)
        assert 'Pele is unavailable' in html and 'mermaid.initialize(' not in html
        print('PASS missing Pele renderer reports error without fallback:', mode)

    markdown.write_text('```mermaid\n' + source + '```\n')
    for highlight in ['on', 'off']:
        for renderer in ['pele', 'mermaid']:
            html = subprocess.check_output([
                str(cli), '--app', str(app), '--mermaid', 'embed', '--mermaid-renderer', renderer,
                '--syntax-highlight', highlight, '--math', 'off', '--about', 'off', str(markdown)
            ], text=True)
            parser = DiagramSource()
            parser.feed(html)
            assert parser.source == source, (highlight, renderer, parser.source)
            if renderer == 'mermaid':
                assert len(html) > 5_000_000, 'Native Mermaid must remain embedded'
            print('PASS preserved diagram source:', renderer, 'syntax-highlight=' + highlight)

    ordinary = '```mermaid\ngraph LR\nA-->B\n```\n'
    cases = [
        ('ordinary diagram', ordinary),
        ('diagram formula', '```mermaid\ngraph LR\nA["$$x^2$$"]\n```\n'),
    ]
    for mode in ['link', 'embed']:
        for name, content in cases:
            markdown.write_text(content)
            html = subprocess.check_output([
                str(cli), '--app', str(app), '--mermaid', mode, '--mermaid-renderer', 'pele',
                '--raw-html', 'on', '--math', 'off', '--about', 'off', str(markdown)
            ], text=True)
            payload = html.split('const qlmarkdownMathOptions = ', 1)[1]
            options, end = json.JSONDecoder().raw_decode(payload)
            assert '<' not in payload[:end], 'Embedded data must not terminate the script element'
            math_keys = {key for key in options if key.startswith('math')}
            expected = {'mathURL', 'mathIntegrity', 'mathCSS'}
            if mode == 'embed':
                expected.add('mathCode')
            assert math_keys == expected, (mode, name, math_keys)
            assert 'data:font/woff2;base64,' in options['mathCSS']
            assert not {'allowFallback', 'nativeCode', 'nativeURL', 'nativeIntegrity'} & options.keys()
            if mode == 'embed':
                resources = pathlib.Path(__file__).resolve().parent.parent / 'Resources'
                assert options['mathCode'] == gzip.decompress((resources / 'temml.min.js.gz').read_bytes()).decode('utf-8')
                assert len(html) < 2_000_000, 'Embedded Pele must not contain Mermaid'
            print('PASS math resources ready for browser-side loading:', mode, name)
