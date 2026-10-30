(() => {
    const article = document.querySelector('.markdown-body');
    let pending = Array.from(document.querySelectorAll('.toc-sidebar > ul > li > a'), link => ({
        link, heading: document.getElementById(link.getAttribute('href').slice(1))
    })).filter(({ heading }) => heading?.querySelector('.hl.math'));
    if (!article || !pending.length) return;

    // Mirror finished math, rather than executing heading macros and labels twice.
    function copy(node, target) {
        if (node.nodeType === Node.TEXT_NODE) {
            target.appendChild(node.cloneNode());
        } else if (node.nodeType === Node.ELEMENT_NODE && node.matches('.hl.math')) {
            const clone = node.cloneNode(true);
            clone.classList.remove('hl', 'math');
            clone.removeAttribute('data-math-renderer');
            for (const number of clone.querySelectorAll('.tml-eqn')) {
                number.textContent = '(' + number.id.replace('tml-eqn-', '') + ')';
                number.classList.remove('tml-eqn');
            }
            for (const element of [clone, ...clone.querySelectorAll('*')]) {
                element.removeAttribute('id');
                element.removeAttribute('tabindex');
                element.removeAttribute('aria-labelledby');
                element.removeAttribute('aria-describedby');
                element.classList.remove('tml-label', 'tml-tageqn');
            }
            // The enclosing TOC link owns navigation, including reference formulas.
            clone.querySelectorAll('a').forEach(link => link.replaceWith(...link.childNodes));
            target.appendChild(clone);
        } else if (node.nodeType === Node.ELEMENT_NODE && !node.matches('script, style')) {
            node.childNodes.forEach(child => copy(child, target));
        }
    }

    function update() {
        pending = pending.filter(({ link, heading }) => {
            const math = Array.from(heading.querySelectorAll('.hl.math'));
            if (!math.every(node => node.dataset.mathRenderer === 'error' || node.querySelector('math, mjx-container'))) return true;
            const label = document.createDocumentFragment();
            heading.childNodes.forEach(node => copy(node, label));
            link.replaceChildren(label);
            return false;
        });
        if (!pending.length) observer.disconnect();
    }
    const observer = new MutationObserver(update);
    observer.observe(article, { childList: true, subtree: true });
    update();
})();
