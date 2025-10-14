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

const config = {
    // Global templates that are not pages or layouts themselves
    templates: ['feature', 'menu', 'menu-item', 'components/sidebar'],

    routes: {
        '/': {
            title: 'EVMPack - Home',
            layout: 'layouts/main',
            page: 'pages/home',
            data: { features: featureData },
            menuTitle: 'Home'
        },
        '/about': {
            title: 'About EVMPack',
            layout: 'layouts/main',
            page: 'pages/about',
            data: {},
            menuTitle: 'About'
        },
        '/settings': {
            title: 'Settings',
            layout: 'layouts/sidebar', // Changed from settings to sidebar
            page: 'pages/settings/overview',
            menuTitle: 'Settings',
            children: {
                '/profile': {
                    title: 'Settings - Profile',
                    // layout property removed to allow inheritance
                    page: 'pages/settings/profile',
                    menuTitle: 'Profile'
                }
            }
        }
    }
};