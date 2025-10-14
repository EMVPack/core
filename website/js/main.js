var $ = window.jsrender;

function copyCode() {
    const code = document.querySelector('.code-snippet pre code').innerText;
    navigator.clipboard.writeText(code).then(() => {
        alert('Code copied to clipboard!');
    }, (err) => {
        alert('Failed to copy code.');
    });
}

document.addEventListener("DOMContentLoaded", async function() {
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

    try {
        // 1. Fetch the main layout
        const layoutResponse = await fetch('templates/layouts/main.html');
        const layoutHtml = await layoutResponse.text();

        // 2. Render the main layout into the #app div
        document.getElementById("app").innerHTML = layoutHtml;

        // 3. Fetch the feature template
        const featureTmplResponse = await fetch('templates/feature.html');
        const featureTmplString = await featureTmplResponse.text();

        // 4. Compile the feature template
        const template = $.templates(featureTmplString);

        // 5. Render the features
        const htmlOutput = template.render(features);

        // 6. Insert the rendered features into the container
        document.getElementById("featuresContainer").innerHTML = htmlOutput;

    } catch (error) {
        console.error('Failed to load templates:', error);
        document.getElementById("app").innerHTML = '<p class="text-center text-danger">Error loading page content.</p>';
    }
});