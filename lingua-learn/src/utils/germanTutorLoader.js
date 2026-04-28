import { analyzeImage } from './claude';
import { buildCourse }  from './courseBuilder';
import { pdfToPageImages } from './pdfLoader';

const LS_KEY = 'll_german_course';

export function loadCachedGermanCourse() {
  const raw = localStorage.getItem(LS_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function clearGermanCourseCache() {
  localStorage.removeItem(LS_KEY);
}

function blobToDataUrl(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload  = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

/**
 * Fetches manifest.json from public/german-tutor/, loads every image and PDF,
 * calls analyzeImage() per page, builds the course, and caches it.
 */
export async function buildGermanCourse(apiKey, onStatus) {
  onStatus('Fetching file list…');

  const manifestRes = await fetch('/german-tutor/manifest.json');
  if (!manifestRes.ok) {
    throw new Error(
      'manifest.json not found. Run: npm run generate-manifest'
    );
  }

  const { files } = await manifestRes.json();
  if (!files?.length) {
    throw new Error('No files in manifest.json — add images/PDFs to public/german-tutor/');
  }

  // Expand each file into { name, type, data } items
  const items = [];
  for (const filename of files) {
    const url = `/german-tutor/${filename}`;
    if (/\.pdf$/i.test(filename)) {
      onStatus(`Rendering PDF: ${filename}…`);
      const pages = await pdfToPageImages(url, (p, total) =>
        onStatus(`Rendering ${filename}: page ${p} of ${total}…`)
      );
      items.push(...pages);
    } else {
      const res = await fetch(url);
      if (!res.ok) { console.warn(`Skipping ${filename} — fetch failed`); continue; }
      const blob    = await res.blob();
      const dataUrl = await blobToDataUrl(blob);
      items.push({ name: filename, type: blob.type || 'image/jpeg', data: dataUrl });
    }
  }

  if (items.length === 0) {
    throw new Error('No readable files found in public/german-tutor/');
  }

  // Analyse each page with Claude
  const pages = [];
  for (let i = 0; i < items.length; i++) {
    onStatus(`Scanning page ${i + 1} of ${items.length}…`);
    try {
      const extracted = await analyzeImage(
        apiKey,
        items[i].data.split(',')[1],
        items[i].type,
      );
      pages.push(extracted);
    } catch (err) {
      console.warn(`Skipped page ${i + 1}: ${err.message}`);
    }
  }

  if (pages.length === 0) {
    throw new Error('Could not extract any content from German Tutor files');
  }

  onStatus('Building course…');
  const course = buildCourse(pages);
  localStorage.setItem(LS_KEY, JSON.stringify(course));
  return course;
}
