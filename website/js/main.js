var $ = window.jsrender;
const router = new Navigo('/');
const app = document.getElementById('app');
const templates = {}; // Cache for compiled templates

// --- Preload all templates ---
async function preloadTemplates(paths) {
    for (const path of paths) {
        try {
            const response = await fetch(`templates/${path}.html`);
            const templateString = await response.text();
            templates[path] = $.templates(templateString);
        } catch (error) {
            console.error(`Failed to load template: ${path}`, error);
        }
    }
}

// --- Page-specific rendering logic ---
function renderFeatures() {
    const featureData = [
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
    if (templates['feature'] && document.getElementById('featuresContainer')) {
        const featuresHtml = templates['feature'].render(featureData);
        document.getElementById('featuresContainer').innerHTML = featuresHtml;
    }
}

// --- Routes Configuration ---
const routes = {
    '/': {
        title: 'EVMPack - Home',
        template: 'layouts/main',
        onAfterRender: renderFeatures
    }
};

// --- Global functions (must be on window object to be called from HTML) ---
window.copyCode = function() {
    const code = document.querySelector('.code-snippet pre code').innerText;
    navigator.clipboard.writeText(code).then(() => {
        alert('Code copied to clipboard!');
    }, (err) => {
        alert('Failed to copy code.');
    });
}

// --- Main execution block ---
document.addEventListener("DOMContentLoaded", async () => {
    await preloadTemplates(['layouts/main', 'feature']);

    // Set up router
    for (const path in routes) {
        const route = routes[path];
        router.on(path, () => {
            document.title = route.title;
            if (templates[route.template]) {
                const layoutHtml = templates[route.template].render();
                app.innerHTML = layoutHtml;
                if (route.onAfterRender) {
                    route.onAfterRender();
                }
            } else {
                 app.innerHTML = `<p class="text-center text-danger">Error: Layout template for ${path} not found.</p>`;
            }
        });
    }

    router.notFound(() => {
        document.title = '404 Not Found';
        app.innerHTML = '<h2 class="text-center py-5">404 Not Found</h2>';
    }).resolve();
});