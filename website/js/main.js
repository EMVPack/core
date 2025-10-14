function copyCode() {
    const code = document.querySelector('.code-snippet pre code').innerText;
    navigator.clipboard.writeText(code).then(() => {
        alert('Code copied to clipboard!');
    }, (err) => {
        alert('Failed to copy code.');
    });
}