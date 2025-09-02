
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

function findFile(dir, fileName) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            const foundPath = findFile(filePath, fileName);
            if (foundPath) {
                return foundPath;
            }
        } else if (file === fileName) {
            return filePath;
        }
    }
    return false;
}

function convertDeps(deps){
    const convert_deps = [];
    for (const name in deps) {
        if (Object.prototype.hasOwnProperty.call(deps, name)) {
            const version = deps[name];
            convert_deps.push({name,version})
        }
    }

    return convert_deps;
}

/**
 * Creates a hidden directory inside the user's home directory in a cross-platform way.
 * Handles recursive creation and correctly hides the top-level directory on Windows.
 *
 * @param {string} dirName The name of the directory or path to create (e.g., '.my-app/cache').
 * @returns {string} The full path to the created directory structure.
 */
function createHiddenDirInHome(dirName) {
  // 1. Формируем полный путь
  const fullPath = path.join(os.homedir(), dirName);

  if(fs.existsSync(fullPath)){
    return fullPath;
  }
  // 2. Рекурсивно создаем директорию
  try {
    // Используем { recursive: true }
    fs.mkdirSync(fullPath, { recursive: true });
    console.log(`Directory structure ensured: ${fullPath}`);
  } catch (err) {
    if (err.code === 'EEXIST') {
      // This case is often handled by recursive mkdir, but we'll keep it for robustness.
      console.log(`Directory structure already exists: ${fullPath}`);
    } else {
      throw err;
    }
  }

  // 3. Если мы на Windows, устанавливаем атрибут "Скрытый" для папки ВЕРХНЕГО уровня
  if (process.platform === 'win32') {
    // Получаем имя первой папки в пути (например, '.myapp' из '.myapp/cache/logs')
    const topLevelDirName = dirName.split(path.sep)[0];
    const pathToHide = path.join(os.homedir(), topLevelDirName);

    try {
      execSync(`attrib +h "${pathToHide}"`);
      console.log(`Hidden attribute set for: ${pathToHide}`);
    } catch (err) {
      console.error(`Failed to set hidden attribute on Windows for ${pathToHide}:`, err);
    }
  }

  return fullPath;
}


/**
 * Creates a symbolic link in a cross-platform manner, correctly handling files and directories.
 *
 * On Windows, it uses 'junction' for directories to avoid requiring administrator rights,
 * and 'file' for files (which may require elevated rights or Developer Mode).
 * On other platforms, it creates a standard symlink.
 *
 * @param {string} target The path to the original file or directory.
 * @param {string} linkPath The path where the symbolic link should be created.
 * @returns {Promise<void>} A promise that resolves when the link is created, or rejects on error.
 */
async function createSymlink(target, linkPath) {
  const fs = require('fs/promises');
  const absoluteTarget = path.resolve(target);
  const absoluteLinkPath = path.resolve(linkPath);

  try {
    const stats = await fs.stat(absoluteTarget);
    const type = (process.platform === 'win32')
      ? (stats.isDirectory() ? 'junction' : 'file')
      : (stats.isDirectory() ? 'dir' : 'file'); // 'type' is ignored on non-Windows, but we set it for clarity.

    await fs.symlink(absoluteTarget, absoluteLinkPath, type);
    // console.log(`Symlink created: ${absoluteLinkPath} -> ${absoluteTarget}`);
  } catch (err) {
    if (err.code === 'EEXIST') {
      // If the link already exists, do nothing.
      // You might want to add more sophisticated handling here,
      // like checking if the existing link points to the correct target.
      return;
    }
    console.error(`Error creating symlink from ${absoluteLinkPath} to ${absoluteTarget}:`, err.message);
    if (err.code === 'EPERM' && process.platform === 'win32') {
      console.error('On Windows, creating file symlinks might require Administrator rights or Developer Mode.');
    }
    // Re-throw the error to allow the caller to handle it.
    throw err;
  }
}

module.exports = {
    findFile,
    convertDeps,
    createHiddenDirInHome,
    createSymlink
};