const CACHE_NAME = 'lingua-learn-v1';

const PRECACHE_URLS = ['/', '/manifest.json'];

// These external origins must always hit the network — never intercept them.
const BYPASS_ORIGINS = new Set([
  'api.anthropic.com',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
]);

// ── Install ──────────────────────────────────────────────────────────────────
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
  // Take control immediately so updates apply without waiting for all tabs to close.
  self.skipWaiting();
});

// ── Activate ─────────────────────────────────────────────────────────────────
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  );
});

// ── Fetch ─────────────────────────────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
  const { request } = event;

  // Skip non-GET (POST to Claude API etc.)
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  // Skip external origins entirely — let them go straight to the network.
  if (url.origin !== self.location.origin) {
    if (BYPASS_ORIGINS.has(url.hostname)) return;
    return;
  }

  if (request.mode === 'navigate') {
    // Navigation: network-first so fresh index.html is always used when online,
    // falling back to the cached app shell when offline.
    event.respondWith(
      fetch(request)
        .then((response) => {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() =>
          caches.match('/').then(
            (cached) =>
              cached ||
              new Response('Offline — open LinguaLearn while connected first.', {
                status: 503,
                headers: { 'Content-Type': 'text/plain' },
              })
          )
        )
    );
    return;
  }

  // All other same-origin requests (hashed JS/CSS, icons, fonts, PDFs):
  // cache-first so the app loads instantly offline.
  // Assets are cached on first network access and served from cache thereafter.
  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;

      return fetch(request)
        .then((response) => {
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
          return response;
        })
        .catch(() => new Response('', { status: 503 }));
    })
  );
});
