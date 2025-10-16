
const fs = require("fs");
const tar = require("tar");
const glob = require("glob");

async function createTarball(name, version) {
    const tarball_path = `/tmp/${name}-${version}.tgz`;


    let ignore = ["./cache/**", "./node_modules/**", "./.git/**", ".gitignore", "@evmpack"];

    if (fs.existsSync('.gitignore')) {
        const gitignore = fs.readFileSync('.gitignore', 'utf8').split('\n').filter(Boolean);
        ignore = ignore.concat(gitignore);
    }

    const files = [
        ...glob.sync('./*', { ignore }),
        ...glob.sync('./artifacts/**', { ignore }),
        ...glob.sync('evmpack.json', { ignore }),
        ...glob.sync('release.json', { ignore }),
        ...glob.sync('package.json', { ignore }),
        ...glob.sync('*.js', { ignore }),
        ...glob.sync("./*.md", { ignore }),
        ...glob.sync("./*.sol", { ignore }),
        ...glob.sync("./contracts/**", { ignore }),
        ...glob.sync("./test/**", { ignore })
    ];

    await tar.create(
        { file: tarball_path, gzip: true },
        files
    );

    return tarball_path;
}

async function extractTarball(sourcePath, destPath) {
    if (!fs.existsSync(destPath)) {
        fs.mkdirSync(destPath, { recursive: true });
    }
    return tar.extract({ file: sourcePath, cwd: destPath });
}

module.exports = {
    createTarball,
    extractTarball
}