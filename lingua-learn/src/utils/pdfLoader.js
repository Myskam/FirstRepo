import * as pdfjsLib from 'pdfjs-dist';

// Worker is served as a static file from public/
pdfjsLib.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';

const SCALE_NORMAL = 2.0;
const SCALE_LARGE  = 1.5; // fallback for PDFs with many pages

/**
 * Fetch a PDF by URL and render each page to a PNG data-URL.
 * Returns an array of { name, type, data } — same shape UploadScreen produces.
 */
export async function pdfToPageImages(pdfUrl, onProgress) {
  const pdf = await pdfjsLib.getDocument(pdfUrl).promise;
  const scale = pdf.numPages > 20 ? SCALE_LARGE : SCALE_NORMAL;
  const baseName = pdfUrl.split('/').pop();
  const results = [];

  for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
    onProgress?.(pageNum, pdf.numPages);
    const page     = await pdf.getPage(pageNum);
    const viewport = page.getViewport({ scale });
    const canvas   = document.createElement('canvas');
    canvas.width   = viewport.width;
    canvas.height  = viewport.height;
    await page.render({ canvasContext: canvas.getContext('2d'), viewport }).promise;
    results.push({
      name: `${baseName}_p${pageNum}.png`,
      type: 'image/png',
      data: canvas.toDataURL('image/png'),
    });
  }

  return results;
}
