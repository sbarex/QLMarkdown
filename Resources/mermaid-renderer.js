async function renderMermaidDiagrams() {
    const nodes = document.querySelectorAll('.mermaid');
    let mathProbe;

    // Like the Playground, measure MathML in the document before placing it in SVG.
    function typesetMath(tex, size) {
        if (!mathProbe) {
            mathProbe = document.createElement('div');
            mathProbe.style.cssText = 'position:absolute;left:-9999px;top:0;visibility:hidden;display:inline-block;white-space:nowrap';
            document.body.appendChild(mathProbe);
        }
        mathProbe.style.fontSize = size + 'px';
        mathProbe.innerHTML = temml.renderToString(tex, { displayMode: true, throwOnError: true, trust: false });
        const expression = mathProbe.querySelector('math');
        if (!expression) throw new Error('Unable to typeset formula');
        const { width, height } = expression.getBoundingClientRect();
        return { html: expression.outerHTML, width, height };
    }

    // Only diagrams with formulas wait for Temml; unrelated diagrams can render immediately.
    await Promise.all(Array.from(nodes, async (node, index) => {
        const source = node.textContent;
        const id = 'qlmarkdown-diagram-' + index;
        try {
            if (!window.pele) throw new Error('Pele is unavailable');
            if (source.includes('$$')) await loadTemml();
            const style = getComputedStyle(node);
            const width = node.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
            const result = pele.render(source, {
                idPrefix: id,
                fontFamily: style.getPropertyValue('--pele-font').trim() || style.fontFamily,
                fontFamilyMono: style.getPropertyValue('--pele-font-mono').trim() || undefined,
                fontSize: parseFloat(style.fontSize) || 16,
                maxWidth: width > 0 ? width : undefined,
                icons: peleIcon,
                math: source.includes('$$') ? typesetMath : undefined,
                links: false,
                images: true
            });
            node.innerHTML = result.svg;
            node.dataset.renderer = 'pele';
        } catch (error) {
            showError(node, source, error);
        }
    }));
    mathProbe?.remove();

    function showError(node, source, error) {
        node.textContent = source + '\n\nUnable to render diagram: ' + error.message;
        node.style.whiteSpace = 'pre-wrap';
        node.dataset.renderer = 'error';
    }

}
