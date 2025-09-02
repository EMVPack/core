const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
const axios = require('axios');

async function uploadFile(file) {
    try {
        const form = new FormData();
        if (Buffer.isBuffer(file)) {
            form.append('file', file, { filename: 'artifact.json' });
        } else {
            form.append('file', fs.createReadStream(file));
        }

        const response = await axios.post(process.env.STORAGE_ENDPOINT+'/upload', form, {
            headers: {
                'x-api-key': process.env.STORAGE_API_KEY,
                ...form.getHeaders(),
            },
        });

        return response.data.cid;
    } catch (error) {
        console.error(error.response ? error.response.data : error.message)
        throw new Error(`Error uploading file ${file}`,);
    }
}

async function downloadFile(cid, filename, dest) {
    try {
        const destPath = path.join(dest, filename);
        const writer = fs.createWriteStream(destPath);

        const response = await axios({
            method: 'get',
            url: `${process.env.STORAGE_ENDPOINT}/file/${cid}`,
            responseType: 'stream',
            headers: {
                'x-api-key': process.env.STORAGE_API_KEY
            }
        });

        response.data.pipe(writer);

        return new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
        });
    } catch (error) {
        console.error(error.response ? error.response.data : error.message);
        throw new Error(`Error downloading file ${cid}`);
    }
}



async function downloadFileContent(cid) {
    try {
        const response = await axios({
            method: 'get',
            url: `${process.env.STORAGE_ENDPOINT}/file/${cid}`,
            responseType: 'arraybuffer',
            headers: {
                'x-api-key': process.env.STORAGE_API_KEY
            }
        });

        return Buffer.from(response.data);
    } catch (error) {
        console.error(error.response ? error.response.data : error.message);
        throw new Error(`Error downloading file content ${cid}`);
    }
}

module.exports = {
    uploadFile,
    downloadFile,
    downloadFileContent
}