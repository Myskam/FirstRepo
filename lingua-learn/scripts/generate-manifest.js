import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dir = path.resolve(__dirname, '../public/german-tutor');
const SUPPORTED = /\.(jpg|jpeg|png|webp|gif|pdf)$/i;

if (!fs.existsSync(dir)) {
  console.error('Directory not found: public/german-tutor/');
  console.error('Create it and copy your German Tutor images/PDFs there first.');
  process.exit(1);
}

const files = fs
  .readdirSync(dir)
  .filter(f => SUPPORTED.test(f) && !f.startsWith('.'))
  .sort();

const manifest = { files };
fs.writeFileSync(path.join(dir, 'manifest.json'), JSON.stringify(manifest, null, 2));
console.log(`✅ manifest.json written — ${files.length} file(s):`);
files.forEach(f => console.log(`   ${f}`));
