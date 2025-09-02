const { execSync } = require('child_process');
const axios = require('axios');
const inquirer = require('inquirer');
const fs = require('fs');
const { saveConfig } = require("./config"); // Use saveConfig

async function initFromNPM(__name) {


    const output = execSync(`npm view ${__name} --json`);
    const package = JSON.parse(output.toString());

    if(__name[0] == "@"){
        __name = __name.substring(1);
    }
    const [_name] = __name.split("@");
    const name = _name.replace("/", "@");
    const create_package = execSync(`wget ${package.dist.tarball} -O ${name}-${package.version}.tgz &&  tar -xzf ${name}-${package.version}.tgz && rm ${name}-${package.version}.tgz && mkdir ${name}-${package.version} && mv package/* ${name}-${package.version}/ && rmdir package`);
    console.log(create_package.toString());

    const evmpack = {
        name: name,
        title: package.title || package.description,
        description: package.description,
        type: "library",
        author: package.author,
        license: package.license,
        tags: package.keywords,
        git: package.repository.url,
        homepage: package.homepage
    };

    const release = {
        version: package.version
    };

    saveConfig(`${name}-${package.version}/evmpack.json`, evmpack);
    saveConfig(`${name}-${package.version}/release.json`, release);
    const { owner, repo } = parseGitHubUrl(package.repository.url);

    try {
        const response = await axios.get(`https://api.github.com/repos/${owner}/${repo}/releases/tags/v${package.version}`);
        const releaseNotes = `Tag: ${response.data.tag_name}\n\n${response.data.body}`;
        fs.writeFileSync(`${name}-${package.version}/release_note.md`, releaseNotes);
    } catch (error) {
        console.error('Failed to fetch release notes from GitHub.');

        try {
            console.log("Gemini auto generate release_note.md")
            const output = execSync(`gemini -y -p "Create release_note.md based on all of files in current directory, if you see natspec comment, create from them documentation"`)
            console.log("Gemini answer", output.toString())
            release_note = fs.readFileSync(release_note_path, 'utf8');
        } catch {

            const answers = await inquirer.default.prompt([
                {
                    type: 'editor',
                    name: 'releaseNotes',
                    message: 'Could not fetch release notes. Please provide them manually (in markdown format).',
                    default: `# Release notes for ${name} v${package.version}\n\n`
                }
            ]);
            fs.writeFileSync(`${name}-${package.version}/release_note.md`, answers.releaseNotes);
        }
    }
}

module.exports = {
    initFromNPM
};

function parseGitHubUrl(gitUrl) {
    // Убираем префиксы и суффиксы
    const cleanUrl = gitUrl
        .replace(/^git\+/, '')
        .replace(/\.git$/, '');

    // Используем регулярное выражение
    const match = cleanUrl.match(new RegExp("github\\.com[:/]([^/]+)/([^/]+)"));

    if (match && match.length >= 3) {
        return {
            owner: match[1],
            repo: match[2]
        };
    }

    return null;
}