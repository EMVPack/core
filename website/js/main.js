var $ = window.jsrender;
const router = new Navigo('/');
const app = document.getElementById('app');
const templates = {}; // Cache for compiled templates
const converter = new showdown.Converter({tables:true, tablesHeaderId: true});

router.hooks({
  before(done, match) {
    const delayTime = (window.location.host === "localhost:3000" && config.emulateLocalLoading) ? 1500 : 0; // 1.5 seconds delay if emulateDelay is true

    if(delayTime && document.getElementById("preloader"))
        setTimeout(() => {
              done();
        }, delayTime);
    else
         done();
    
  
  }
});

// --- Preload and Process Config ---
async function preloadTemplates(paths) {
    for (const path of paths) {
        try {

            let template = `/templates/${path}`;
            let isMarkdown = false;
            if(path.split(".md").length == 2){
                isMarkdown = true;
            }

            if(!isMarkdown)
                template += ".html";

            const response = await fetch(template);
            let templateString = await response.text();

            if(isMarkdown){
                templateString = converter.makeHtml(templateString)
            }   

            templates[path] = $.templates(templateString);
        } catch (error) {
            console.error(`Failed to load template: ${path}`, error);
        }
    }
}

function processRoutes(routes, parentPath = '') {
    for (const path in routes) {
        const route = routes[path];
        // Create the full, absolute path for the route
        const fullPath = `${parentPath}${path}`;
        route.fullPath = (fullPath === '/') ? '/' : fullPath.replace(/\/$/, '');

        if (route.children) {
            processRoutes(route.children, route.fullPath);
        }
    }
}

// --- Main execution block ---
document.addEventListener("DOMContentLoaded", async () => {

    // 1. Process routes to add fullPath property
    processRoutes(config.routes);

    // 2. Dynamically build the list of templates to load from config
    const templatePaths = new Set(config.templates || []);
    function collectTemplates(routes) {
        for (const path in routes) {
            const route = routes[path];
            if (route.layout) templatePaths.add(route.layout);
            if (route.page) templatePaths.add(route.page);
            if (route.children) collectTemplates(route.children);
        }
    }
    collectTemplates(config.routes);

    
    await preloadTemplates(Array.from(templatePaths));

    // 3. Recursive Router Setup
    function registerRoutes(routes) {
        for (const path in routes) {
            const route = routes[path];
            router.on(route.fullPath, () => {
                document.title = route.title;
                const layoutTemplate = templates[route.layout];
                if (layoutTemplate) {
                    const finalHtml = layoutTemplate.render(route.data, {
                        templates: templates,
                        config: config,
                        currentPage: route.page,
                        currentRoute: route // Pass current route for context
                    });

                    app.innerHTML = finalHtml;
                    Prism.highlightAll();
                } else {
                    app.innerHTML = `<p class="text-center text-danger">Layout template for ${route.fullPath} not found.</p>`;
                }
            });
            if (route.children) {
                registerRoutes(route.children);
            }
        }
    }

    registerRoutes(config.routes);

    router.notFound(() => {
        document.title = '404 Not Found';
        app.innerHTML = '<h2 class="text-center py-5">404 Not Found</h2>';
    }).resolve();
});