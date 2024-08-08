#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

/**
 * Synchronously retrieves a list of files in the specified directory along with their modification dates.
 *
 * @param {string} directoryPath - The path of the directory to retrieve files from.
 * @return {Array<{filePath: string, dateModified: Date}>} An array of objects containing the file path and modification date for each file in the directory.
 */
function getFilesWithDateSync(directoryPath) {
  const fileList = [];
  const files = fs.readdirSync(directoryPath);

  for (const file of files) {
    const filePath = path.join(directoryPath, file);
    const stats = fs.statSync(filePath);
    const dateModified = new Date(stats.mtime);

    if (file !== '@eaDir') {
      fileList.push({ filePath, dateModified });
    }
  }

  return fileList;
}

/**
 * Creates a directory structure based on the year and month of the provided ISO date.
 *
 * @param {string} isoDate - The ISO date to extract the year and month from.
 * @param {string} path - The base path to create the directory structure in.
 */
function createDirectoryStructure(isoDate, path) {
  const date = new Date(isoDate);
  const year = date.getFullYear();
  const month = date.toLocaleString('default', { month: '2-digit' });

  const yearPath = `${path}/${year}`;
  const monthPath = `${yearPath}/${month}`;

  if (!fs.existsSync(yearPath)) {
    fs.mkdirSync(yearPath);
  }

  if (!fs.existsSync(monthPath)) {
    fs.mkdirSync(monthPath);
  }

  return monthPath;
}

/**
 * Extracts the filename from a given file path.
 *
 * @param {string} filePath - The path containing the filename.
 * @return {string} The extracted filename from the path.
 */
function getFilenameFromPath(filePath) {
  return filePath.split('/').pop();
}

/**
 * Moves a file from the specified file path to the specified destination path synchronously.
 *
 * @param {string} filePath - The path of the file to be moved.
 * @param {string} destinationPath - The path where the file should be moved to.
 */
function moveFileSync(file, destinationPath) {
  try {
    const { filePath, dateModified } = file;
    const destinatonFilePath = path.join(
      destinationPath,
      getFilenameFromPath(filePath)
    );
    fs.copyFileSync(filePath, destinatonFilePath);
    fs.utimesSync(
      destinatonFilePath,
      new Date(dateModified),
      new Date(dateModified)
    );
    fs.rmSync(filePath);
  } catch (error) {
    console.error('Error moving file:', error);
  }
}

/**
 * Example usage
 * ./process-files.sh ./incoming/folder ./processed
 */
const incoming = process.argv[2];
const processed = process.argv[3];

if (incoming && processed) {
  const files = getFilesWithDateSync(incoming);

  if (files.length) {
    files.forEach((file) => {
      const location = createDirectoryStructure(
        file.dateModified.toISOString().substring(0, 7),
        processed
      );

      moveFileSync(file, location);
    });

    return console.log(`Moved ${files.length} files to ${processed}`);
  }

  return console.log('No files found');
}
