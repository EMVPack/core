var $ = window.jsrender;

function copyCode() {
    const code = document.querySelector('.code-snippet pre code').innerText;
    navigator.clipboard.writeText(code).then(() => {
        alert('Code copied to clipboard!');
    }, (err) => {
        alert('Failed to copy code.');
    });
}

document.addEventListener("DOMContentLoaded", function() {
    const features = [
        {
            icon: '&#128230;',
            title: 'On-chain Package Manager',
            description: 'Manage your smart contract packages directly on the blockchain.'
        },
        {
            icon: '&#128273;',
            title: 'Secure and Reliable',
            description: 'Ensures integrity and provenance of smart contract packages.'
        },
        {
            icon: '&#128279;',
            title: 'Seamless Integration',
            description: 'Works with your existing developer tools like Hardhat and Foundry.'
        }
    ];

    const template = $.templates("#featureTemplate");
    const htmlOutput = template.render(features);
    document.getElementById("featuresContainer").innerHTML = htmlOutput;
});
