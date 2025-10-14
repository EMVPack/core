var $ = window.jsrender;
const router = new Navigo('/');
const app = document.getElementById('app');
const templates = {}; // Cache for compiled templates

// --- Preload all templates ---
async function preloadTemplates(paths) {
    for (const path of paths) {
        try {
            const response = await fetch(`/templates/${path}.html`);
            const templateString = await response.text();
            templates[path] = $.templates(templateString);
        } catch (error) {
            console.error(`Failed to load template: ${path}`, error);
        }
    }
}

// --- Global functions ---
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
    // Dynamically build the list of templates to load from config
    const templatePaths = new Set(config.templates || []);
    for (const path in config.routes) {
        const route = config.routes[path];
        if (route.layout) templatePaths.add(route.layout);
        if (route.page) templatePaths.add(route.page);
    }
    await preloadTemplates(Array.from(templatePaths));

    // Set up router from config
    for (const path in config.routes) {
        const route = config.routes[path];
        router.on(path, () => {
            document.title = route.title;
            const layoutTemplate = templates[route.layout];

            if (layoutTemplate) {
                // The layout template is responsible for everything.
                // We pass it the route-specific data, and all global templates/config as helpers.
                const finalHtml = layoutTemplate.render(route.data, {
                    templates: templates,
                    config: config,
                    currentPage: route.page // Tell the layout which page to render
                });
                app.innerHTML = finalHtml;
            } else {
                 app.innerHTML = `<p class="text-center text-danger">Error: Layout template for ${route.layout} not found.</p>`;
            }
        });
    }

    router.notFound(() => {
        document.title = '404 Not Found';
        app.innerHTML = '<h2 class="text-center py-5">404 Not Found</h2>';
    }).resolve();
});