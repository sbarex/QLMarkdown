let temmlLoading;

// Body formulas and Pele share the library, stylesheet and font readiness.
function loadTemml() {
    if (!temmlLoading) {
        temmlLoading = new Promise((resolve, reject) => {
            const style = document.createElement('style');
            style.textContent = qlmarkdownMathOptions.mathCSS;
            document.head.appendChild(style);
            const script = document.createElement('script');
            script.nonce = qlmarkdownMathOptions.nonce;
            script.onerror = () => reject(new Error('Unable to load Temml'));
            const ready = () => {
                if (!window.temml) {
                    reject(new Error('Temml is unavailable'));
                    return;
                }
                document.fonts.load('16px Temml').then(resolve, reject);
            };
            if (qlmarkdownMathOptions.mathCode) {
                script.textContent = qlmarkdownMathOptions.mathCode;
                document.head.appendChild(script);
                ready();
            } else {
                script.src = qlmarkdownMathOptions.mathURL;
                script.integrity = qlmarkdownMathOptions.mathIntegrity;
                script.crossOrigin = 'anonymous';
                script.onload = ready;
                document.head.appendChild(script);
            }
        });
    }
    return temmlLoading;
}

async function renderTemmlMath() {
    // cmark has already identified math; scanning dollar signs again would match currency.
    const nodes = Array.from(document.querySelectorAll('span.hl.math, div.hl.math'));
    if (!nodes.length) return;
    function showError(node, source, error) {
        node.textContent = source + '\nUnable to render formula: ' + error.message;
        node.dataset.mathRenderer = 'error';
    }
    try {
        await loadTemml();
    } catch (error) {
        nodes.forEach(node => showError(node, node.textContent, error));
        return;
    }
    const macros = {};
    const sources = nodes.map(node => node.textContent);
    for (const [index, node] of nodes.entries()) {
        const source = sources[index];
        const displayMode = node.tagName === 'DIV';
        const delimiter = displayMode ? '$$' : '$';
        try {
            if (!source.startsWith(delimiter) || !source.endsWith(delimiter)) {
                throw new Error('Missing math delimiters');
            }
            temml.render(source.slice(delimiter.length, -delimiter.length), node, {
                displayMode, macros, throwOnError: true, trust: false
            });
            node.dataset.mathRenderer = 'temml';
        } catch (error) {
            showError(node, source, error);
        }
    }
    const root = document.querySelector('.markdown-body') || document.body;
    // Match Temml 0.14's numbered/tagged label owners before its single document pass.
    const labels = new Set();
    for (const number of root.querySelectorAll('.tml-eqn')) {
        for (let row = number; row && row.localName !== 'mtable'; row = row.parentElement) {
            if (row.querySelector('.tml-label')) {
                if (row.hasAttribute('id')) labels.add(row.id);
                break;
            }
        }
    }
    for (const row of root.querySelectorAll('.tml-tageqn')) {
        if (row.hasAttribute('id') && row.querySelector('.tml-label') && row.querySelector('.tml-tag')) labels.add(row.id);
    }
    // Temml's plain-object tag table cannot store this key, even with a matching label.
    labels.delete('__proto__');
    for (const [index, node] of nodes.entries()) {
        for (const reference of node.querySelectorAll('.tml-ref')) {
            const label = reference.getAttribute('href').slice(1);
            if (labels.has(label)) continue;
            const command = reference.classList.contains('tml-eqref') ? '\\eqref' : '\\ref';
            const message = document.createElementNS('http://www.w3.org/1998/Math/MathML', 'mtext');
            message.textContent = command + '{' + label + '} (unresolved reference)';
            reference.replaceWith(message);
            node.dataset.mathRenderer = 'error';
            node.title = sources[index];
        }
    }
    temml.postProcess(root);
}
