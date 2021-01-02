/**
 * Generate an unique id.
 * @returns {string}
 */
function uid() {
    let a = new Uint32Array(3);
    window.crypto.getRandomValues(a);
    return (performance.now().toString(36)+Array.from(a).map(A => A.toString(36)).join("")).replace(/\\./g,"");
}

/**
 * Callback event handler for error when loading an image.
 */
function handleImageError() {
    console.error("error loading image from ", this.src, this);
    if (this.src.indexOf("file://") === 0) {
        // Process only local images.
        if (!this.id) {
            this.id = 'I' + uid(); // Assign a uid.
        }
        window.webkit.messageHandlers.imageExtensionHandler.postMessage({src: this.src, id: this.id});
    }
}

/**
 * Replace the src image with the embedded data.
 */
function replaceImageSrc(result) {
    const img = document.getElementById(result.id);
    if (img) {
        img.src = result.data;
        return true;
    } else {
        return false;
    }
}

// Register the onerror handler.
for (let image of document.images) {
    image.onerror = handleImageError;
}
