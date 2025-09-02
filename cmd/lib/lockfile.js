const fs = require('fs');
const path = require('path');

const LOCKFILE_NAME = 'evmpack-lock.json';
const LOCKFILE_PATH = path.join(process.cwd(), LOCKFILE_NAME);

function readLockfile() {
    if (!fs.existsSync(LOCKFILE_PATH)) {
        return null;
    }
    const content = fs.readFileSync(LOCKFILE_PATH, 'utf-8');
    return JSON.parse(content);
}

function writeLockfile(packages) {
    const lockfileData = {
        lockfileVersion: 1,
        packages: packages,
    };
    fs.writeFileSync(LOCKFILE_PATH, JSON.stringify(lockfileData, null, 2));
}

module.exports = { readLockfile, writeLockfile };
