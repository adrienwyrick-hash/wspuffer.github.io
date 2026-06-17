const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const resDir = path.join(__dirname, '..', 'resources');

async function run() {
  await sharp(path.join(resDir, 'icon.svg'))
    .resize(1024, 1024)
    .png()
    .toFile(path.join(resDir, 'icon.png'));
  console.log('wrote resources/icon.png (1024x1024)');

  await sharp(path.join(resDir, 'splash.svg'))
    .resize(2732, 2732)
    .png()
    .toFile(path.join(resDir, 'splash.png'));
  console.log('wrote resources/splash.png (2732x2732)');

  // dark splash = same as light (single ocean theme)
  fs.copyFileSync(path.join(resDir, 'splash.png'), path.join(resDir, 'splash-dark.png'));
  console.log('wrote resources/splash-dark.png');
}

run().catch(e => { console.error(e); process.exit(1); });
