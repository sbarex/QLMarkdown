// Run with: node --test tests/mermaid-renderer.test.mjs
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { gunzipSync } from 'node:zlib';
import { createHash } from 'node:crypto';
import vm from 'node:vm';
import test from 'node:test';

const resource = name => readFileSync(new URL('../Resources/' + name, import.meta.url));
const peleCode = gunzipSync(resource('pele.global.js.gz')).toString();
const temmlCode = gunzipSync(resource('temml.min.js.gz')).toString();
const icons = resource('pele-icons.js').toString();
const renderer = resource('mermaid-renderer.js').toString();
const mathRenderer = resource('math-renderer.js').toString();

function startRender(sources, { pele = true, failPeleRender = false, failMathLoad = false, delayMathLoad = false, embedded = false, bodySources = [] } = {}) {
    const nodes = sources.map(textContent => ({ textContent, dataset: {}, style: {}, clientWidth: 800 }));
    const scripts = [];
    const bodyNodes = bodySources.map(textContent => ({ textContent, tagName: 'SPAN', dataset: {} }));
    let finishMathLoad;
    const context = vm.createContext({
        console, URL,
        getComputedStyle: () => ({ fontFamily: 'sans-serif', fontSize: '16px', paddingLeft: '0px', paddingRight: '0px', getPropertyValue: () => '' }),
        document: {
            compatMode: 'CSS1Compat',
            fonts: { load: async () => [] },
            body: { appendChild() {} },
            querySelectorAll: selector => selector === '.mermaid' ? nodes : bodyNodes,
            createElement: tag => ({
                tagName: tag, style: {}, remove() {},
                querySelector() {
                    const math = this.innerHTML.match(/<math[\s\S]*<\/math>/)?.[0];
                    return math ? { outerHTML: math, getBoundingClientRect: () => ({ width: 40, height: 25 }) } : null;
                }
            }),
            getElementById: () => null,
            head: {
                appendChild(script) {
                    if (script.tagName === 'style') return;
                    scripts.push(script);
                    if (script.src?.includes('temml') || script.textContent === temmlCode) {
                        finishMathLoad = () => {
                            if (failMathLoad) return script.onerror();
                            vm.runInContext(temmlCode, context);
                            if (!script.textContent) script.onload();
                        };
                        if (!delayMathLoad) finishMathLoad();
                        return;
                    }
                    throw new Error('Unexpected script load');
                }
            }
        }
    });
    context.window = context;
    if (pele) vm.runInContext(peleCode, context);
    if (failPeleRender) context.pele = { ...context.pele, render() { throw new Error('Layout failed'); } };
    context.qlmarkdownMathOptions = {
        nonce: 'test-nonce',
        mathURL: 'https://example.com/temml.js', mathIntegrity: 'sha384-math', mathCSS: '',
        mathCode: embedded ? temmlCode : undefined
    };
    vm.runInContext(mathRenderer + '\n' + icons + '\n' + renderer, context);
    const finished = Promise.all([context.renderTemmlMath(), context.renderMermaidDiagrams()]);
    return { nodes, bodyNodes, scripts, finished, finishMathLoad: () => finishMathLoad() };
}

async function render(sources, options) {
    const run = startRender(sources, options);
    await run.finished;
    return run;
}

test('bundled libraries match the pinned integrity', () => {
    const settings = readFileSync(new URL('../QLMarkdown/Settings.swift', import.meta.url), 'utf8');
    const hash = 'sha384-' + createHash('sha384').update(peleCode).digest('base64');
    assert.ok(settings.includes('static let peleHash = "' + hash + '"'));
    assert.ok(settings.includes('static let temmlHash = "sha384-' + createHash('sha384').update(temmlCode).digest('base64') + '"'));
});

test('normal fixtures render with Pele without loading Mermaid', async () => {
    const fixture = readFileSync(new URL('../examples/test-mermaid.md', import.meta.url), 'utf8');
    const sources = Array.from(fixture.matchAll(/```mermaid\n([\s\S]*?)```/g), match => match[1]);
    for (const embedded of [false, true]) {
        const { nodes, scripts } = await render(sources, { embedded });
        assert.equal(scripts.length, 0); // Temml and Mermaid stay unused, even when embedded.
        assert.ok(nodes.every(node => node.dataset.renderer === 'pele' && node.innerHTML.includes('<svg')));
    }
});

test('Chinese labels, custom styles and flat subgraphs', async () => {
    const source = 'flowchart TD\nsubgraph 服务\nA[开始] --> B[完成]\nend\nstyle A fill:#ff0000';
    const { nodes, scripts } = await render([source, source]);
    assert.equal(scripts.length, 0);
    for (const node of nodes) {
        assert.match(node.innerHTML, /开始/);
        assert.match(node.innerHTML, /#ff0000/);
    }
});

test('SVG definitions use distinct IDs across diagrams', async () => {
    const { nodes } = await render(['sankey-beta\nA,B,10', 'sankey-beta\nA,B,10']);
    const ids = nodes.map(node => Array.from(node.innerHTML.matchAll(/\sid="([^"]+)"/g), match => match[1]));
    assert.ok(ids.every(list => list.length > 0));
    assert.ok(ids[0].every(id => !ids[1].includes(id)));
});

test('nested subgraphs, configuration, HTML, icons and images stay on Pele', async () => {
    const sources = [
        'flowchart TD\nsubgraph outer\nsubgraph inner\nA-->B\nend\nend',
        'flowchart TD; subgraph outer; subgraph inner; A-->B; end; end',
        '%%{init: {"theme":"forest"}}%%\ngraph LR\nA-->B',
        '---\nconfig:\n  theme: forest\n---\ngraph LR\nA-->B',
        'graph LR\nA["<span>HTML</span>"]-->B',
        'graph LR\nA["fa:fa-car"]-->B',
        'flowchart LR\nA@{ img: "https://example.com/image.png" }',
        'graph LR\nA["fa:fa-unknown-icon"]-->B'
    ];
    const { nodes, scripts } = await render(sources);
    assert.equal(scripts.length, 0);
    assert.ok(nodes.every(node => node.dataset.renderer === 'pele'));
    assert.match(nodes[5].innerHTML, /<circle/); // Lucide car wheels, not just a text label.
    assert.match(nodes[6].innerHTML, /<image[^>]+href="https:\/\/example.com\/image.png"/);
});

test('Pele parse errors are displayed verbatim without loading Mermaid, later diagrams still render', async () => {
    const source = 'graph LR\nA[broken';
    const context = vm.createContext({});
    vm.runInContext(peleCode, context);
    let message;
    try {
        context.pele.render(source);
    } catch (error) {
        message = error.message;
    }
    assert.ok(message);
    const { nodes, scripts } = await render([source, 'graph LR\nB-->C']);
    assert.equal(nodes[0].dataset.renderer, 'error');
    assert.equal(nodes[0].textContent, source + '\n\nUnable to render diagram: ' + message);
    assert.equal(nodes[0].innerHTML, undefined);
    assert.equal(nodes[1].dataset.renderer, 'pele');
    assert.equal(scripts.length, 0);
});

for (const embedded of [false, true]) {
    test('math uses Temml once and stays on Pele (' + (embedded ? 'embedded' : 'linked') + ')', async () => {
        const { nodes, scripts } = await render(['graph LR\nA["$$x^2$$"]', 'graph LR\nB["$$\\frac{a}{b}$$"]'], { embedded });
        assert.equal(scripts.length, 1);
        assert.equal(scripts[0].nonce, 'test-nonce');
        assert.equal(scripts[0].src, embedded ? undefined : 'https://example.com/temml.js');
        for (const node of nodes) {
            assert.equal(node.dataset.renderer, 'pele');
            assert.match(node.innerHTML, /<foreignObject/);
            assert.match(node.innerHTML, /<math/);
        }
        assert.match(nodes[0].innerHTML, /<msup/);
        assert.match(nodes[1].innerHTML, /<mfrac/);
    });
}

for (const failMathLoad of [false, true]) {
    test('slow math loading does not block other diagrams (' + (failMathLoad ? 'failure' : 'success') + ')', async () => {
        const run = startRender([
            'graph LR\nA["$$x^2$$"]', 'unsupportedDiagram', 'graph LR\nB-->C', 'graph LR\nD["$$y^2$$"]'
        ], { delayMathLoad: true, failMathLoad });
        await new Promise(resolve => setImmediate(resolve));
        try {
            assert.equal(run.nodes[0].dataset.renderer, undefined);
            assert.equal(run.nodes[3].dataset.renderer, undefined);
            assert.equal(run.nodes[2].dataset.renderer, 'pele');
            assert.equal(run.nodes[1].dataset.renderer, 'error');
        } finally {
            run.finishMathLoad();
            await run.finished;
        }
        assert.equal(run.scripts.filter(script => script.src?.includes('temml')).length, 1);
        for (const index of [0, 3]) assert.equal(run.nodes[index].dataset.renderer, failMathLoad ? 'error' : 'pele');
    });
}

test('math load and typesetting errors are displayed without falling back or affecting ordinary diagrams', async () => {
    for (const failMathLoad of [false, true]) {
        const { nodes, scripts } = await render(['graph LR\nA["$$\\notACommand$$"]', 'graph LR\nB-->C'], { failMathLoad });
        assert.equal(nodes[0].dataset.renderer, 'error');
        assert.match(nodes[0].textContent, /Unable to render diagram:/);
        assert.equal(nodes[1].dataset.renderer, 'pele');
        assert.equal(scripts.length, 1); // Only Temml was requested.
    }
});

for (const embedded of [false, true]) {
    test('unavailable Pele never loads Mermaid (' + (embedded ? 'embedded' : 'linked') + ')', async () => {
        const { nodes, scripts } = await render(['graph LR\nA-->B'], { pele: false, embedded });
        assert.equal(scripts.length, 0);
        assert.equal(nodes[0].dataset.renderer, 'error');
        assert.match(nodes[0].textContent, /Pele is unavailable/);
    });

    test('unsupported types show Pele errors without loading Mermaid (' + (embedded ? 'embedded' : 'linked') + ')', async () => {
        const source = 'zenuml\nAlice->Bob: Hi';
        const context = vm.createContext({});
        vm.runInContext(peleCode, context);
        let message;
        try { context.pele.render(source); } catch (error) { message = error.message; }
        assert.ok(message);
        const { nodes, scripts } = await render([source, 'graph LR\nA-->B'], { embedded });
        assert.equal(scripts.length, 0);
        assert.equal(nodes[0].dataset.renderer, 'error');
        assert.equal(nodes[0].textContent, source + '\n\nUnable to render diagram: ' + message);
        assert.equal(nodes[1].dataset.renderer, 'pele');
    });
}

test('a Pele layout failure displays its error without loading Mermaid', async () => {
    const { nodes, scripts } = await render(['graph LR\nA-->B'], { failPeleRender: true });
    assert.equal(scripts.length, 0);
    assert.equal(nodes[0].dataset.renderer, 'error');
    assert.match(nodes[0].textContent, /Unable to render diagram: Layout failed$/);
});

test('one invalid diagram does not prevent later diagrams from rendering', async () => {
    const { nodes } = await render(['bad', 'graph LR\nA-->B', 'another']);
    assert.equal(nodes[0].dataset.renderer, 'error');
    assert.equal(nodes[0].innerHTML, undefined);
    assert.match(nodes[0].textContent, /^bad\n\nUnable to render diagram:/);
    assert.equal(nodes[1].dataset.renderer, 'pele');
    assert.equal(nodes[2].dataset.renderer, 'error');
});

test('diagram source cannot emit active markup or clickable links', async () => {
    const { nodes } = await render(['graph LR\nA["&lt;script&gt;alert(1)&lt;/script&gt;"]\nclick A "javascript:alert(1)"']);
    assert.equal(nodes[0].dataset.renderer, 'pele');
    assert.doesNotMatch(nodes[0].innerHTML, /<script|href="javascript:/);
});

test('enabling images still applies Pele URL filtering', async () => {
    const { nodes } = await render([
        'flowchart LR\nA@{ img: "javascript:alert(1)" }',
        'flowchart LR\nA@{ img: "data:image/svg+xml,<svg></svg>" }',
        'graph LR\nA["fa:fa-constructor"]'
    ]);
    assert.ok(nodes.every(node => node.dataset.renderer === 'pele'));
    assert.doesNotMatch(nodes[0].innerHTML, /<image/);
    assert.doesNotMatch(nodes[1].innerHTML, /<image/);
    assert.doesNotMatch(nodes[2].innerHTML, /function Object/);
});


test('body and Pele share a failed Temml load without loading MathJax', async () => {
    const { nodes, bodyNodes, scripts } = await render([
        'graph LR\nA["$$x^2$$"]', 'graph LR\nB-->C'
    ], { failMathLoad: true, bodySources: ['$x^2$', '$y^2$'] });
    assert.equal(scripts.length, 1);
    assert.equal(nodes[0].dataset.renderer, 'error');
    assert.equal(nodes[1].dataset.renderer, 'pele');
    for (const node of bodyNodes) {
        assert.equal(node.dataset.mathRenderer, 'error');
        assert.match(node.textContent, /^\$[xy]\^2\$\nUnable to render formula: Unable to load Temml$/);
    }
});
