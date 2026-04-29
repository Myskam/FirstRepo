import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SRC  = path.resolve(__dirname, '../public/favicon.svg');
const DEST = path.resolve(__dirname, '../public/icons');

if (!fs.existsSync(DEST)) fs.mkdirSync(DEST, { recursive: true });

const sizes = [
  { name: 'icon-192.png',          size: 192, maskable: false },
  { name: 'icon-512.png',          size: 512, maskable: false },
  { name: 'icon-192-maskable.png', size: 192, maskable: true  },
  { name: 'icon-512-maskable.png', size: 512, maskable: true  },
  { name: 'apple-touch-icon.png',  size: 180, maskable: false },
];

for (const { name, size, maskable } of sizes) {
  const dest = path.join(DEST, name);

  if (maskable) {
    // Place icon at 80% scale centred on a solid green background.
    // The maskable safe zone is the inner 80% circle.
    const padding  = Math.round(size * 0.1);
    const iconSize = size - padding * 2;

    const resizedSvg = await sharp(SRC)
      .resize(iconSize, iconSize)
      .png()
      .toBuffer();

    await sharp({
      create: {
        width: size, height: size, channels: 4,
        background: { r: 88, g: 204, b: 2, alpha: 1 }, // #58cc02
      },
    })
      .composite([{ input: resizedSvg, top: padding, left: padding }])
      .png()
      .toFile(dest);
  } else {
    await sharp(SRC).resize(size, size).png().toFile(dest);
  }

  console.log(`✅ ${name} (${size}x${size})`);
}

console.log(`\nIcons written to public/icons/`);
