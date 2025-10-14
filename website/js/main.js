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
    // Preload all templates we need
    await preloadTemplates(['layouts/main', 'pages/home', 'feature']);

    // Set up router from config
    for (const path in config.routes) {
        const route = config.routes[path];
        router.on(path, () => {
            document.title = route.title;

            const layoutTemplate = templates[route.layout];
            const pageTemplate = templates[route.page];

            if (layoutTemplate && pageTemplate) {
                // 1. Render the main layout and put it in the app
                const layoutHtml = layoutTemplate.render();
                app.innerHTML = layoutHtml;

                // 2. Find the content placeholder inside the newly rendered layout
                const pageContentContainer = document.getElementById('page-content');

                // 3. Render the page template and put it in the placeholder
                if (pageContentContainer) {
                    const pageHtml = pageTemplate.render(route.data, { templates: templates });
                    pageContentContainer.innerHTML = pageHtml;
                }
            } else {
                 app.innerHTML = `<p class="text-center text-danger">Error: Template for ${path} not found.</p>`;
            }
        });
    }

    router.notFound(() => {
        document.title = '404 Not Found';
        app.innerHTML = '<h2 class="text-center py-5">404 Not Found</h2>';
    }).resolve();
});