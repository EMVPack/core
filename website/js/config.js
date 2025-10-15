const featureData = [
    {
        icon: '&#128230;',
        title: 'On-chain Package Manager',
        description: 'Manage your smart contract packages directly on the blockchain.'
    },
    {
        icon: '&#128273;',
        title: 'Reuseble',
        description: 'Use already deployed contracts implementations like ERC20.'
    },
    {
        icon: '&#128279;',
        title: 'Seamless Integration',
        description: 'Works with your existing developer tools like Hardhat and Foundry.'
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
                }
            }
        }
    }
};