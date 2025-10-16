const featureData = [
    {
        icon: '&#128187;',
        title: 'Powerful CLI for dApp Assembly',
        description: 'Interact with the smart contract backend of your dApps efficiently. The EVMPack CLI offers commands like `evmpack init` for project setup, `evmpack register` for implementation registration, and `evmpack use` for assembling and updating your dApp\'s core from available packages, streamlining complex operations.'
    },
    {
        icon: '&#128273;',
        title: 'Reuseble',
        description: 'Define, manage, and share your smart contract packages, whether they are libraries or implementations. EVMPack allows you to install, link, and manage versions of these packages, ensuring consistent and reproducible builds for the foundational layer of your decentralized applications.'
    },
    {
        icon: '&#128230;',
        title: 'Version Control and Release Management',
        description: 'Maintain stability and clarity for your dApp\'s smart contract packages. EVMPack integrates semantic versioning SemVer and facilitates easy management of package releases using `evmpack release`, ensuring clear version tracking and compatibility across your dApp ecosystem.'
    }
];

const config = {
    emulateLocalLoading: true,
    templates: ['components/feature', 'components/menu', 'components/menu-item', 'components/sidebar', 'components/hero'],
    routes: {
        '/': {
            title: 'EVMPack - Home',
            layout: 'layouts/main',
            page: 'pages/home',
            data: { features: featureData, github: "https://github.com/EMVPack/core/" },
            menuTitle: 'Home'
        },
        '/about': {
            title: 'About EVMPack',
            layout: 'layouts/sidebar',
            page: 'pages/about.md',
            data: {},
            menuTitle: 'About'
        },
        '/roadmap': {
            title: 'Roadmap',
            layout: 'layouts/sidebar',
            page: 'pages/roadmap.md',
            data: {},
            menuTitle: 'Roadmap'
        },        
        '/documentation': {
            title: '🚀 Getting Started',
            layout: 'layouts/sidebar', 
            page: 'pages/documentation/overview.md',
            menuTitle: '🚀 Getting Started',
            children: {
                '/init': {
                    title: 'Init package',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/init.md',
                    menuTitle: 'Init package'
                },
                '/install_dependencies': {
                    title: 'Install dependencies',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/install_dependencies.md',
                    menuTitle: 'Install dependencies'
                },
                '/write_implementation': {
                    title: 'Write implementation contract ',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/write_implementation.md',
                    menuTitle: 'Write implementation'
                },
                '/register_implementation': {
                    title: 'Register implementation contract',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/register_implementation.md',
                    menuTitle: 'Register implementation'
                },
                '/add_release': {
                    title: 'Add release implementation contract',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/add_release.md',
                    menuTitle: 'Add new release'
                },
                '/use_cli': {
                    title: 'Use package implementation by CLI',
                    layout: 'layouts/sidebar', 
                    page: 'pages/documentation/use_cli.md',
                    menuTitle: 'Use implementation'
                }                                       
            }
        }
    }
};