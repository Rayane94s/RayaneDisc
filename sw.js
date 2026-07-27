// Update this version number whenever you make changes to force cache refresh
const CACHE_VERSION = '1.0.12';
const CACHE_NAME = `rayane-tracker-v${CACHE_VERSION}`;
const coreUrlsToCache = [
  './',
  './index.html',
  './manifest.json',
  './apple-touch-icon.png',
  './icon-192.png',
  './icon-512.png'
];
// The app uses the system font stack, so there is nothing external to cache.
const optionalUrlsToCache = [];

// Listen for skip-waiting message from the page
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Install event - cache resources
self.addEventListener('install', event => {
  console.log('[SW] Installing new version:', CACHE_VERSION);
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      console.log('[SW] Caching app shell');
      // Cache core assets — failure here aborts install intentionally
      return cache.addAll(coreUrlsToCache).then(() => {
        // Cache optional external resources; ignore failures so SW install succeeds
        return Promise.allSettled(
          optionalUrlsToCache.map(url =>
            fetch(url, { mode: 'no-cors' }).then(resp => cache.put(url, resp)).catch(() => {})
          )
        );
      });
    })
  );
  // Force the waiting service worker to become the active service worker
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  console.log('[SW] Activating new version:', CACHE_VERSION);
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('[SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  // Take control of all pages immediately
  return self.clients.claim();
});

// Fetch event - Network first for HTML, cache first for assets
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // For same-origin requests (our app)
  if (url.origin === location.origin) {
    // Network first strategy for HTML to always get latest version
    if (request.headers.get('accept')?.includes('text/html')) {
      event.respondWith(
        fetch(request)
          .then(response => {
            // Update cache with fresh version
            const responseClone = response.clone();
            caches.open(CACHE_NAME).then(cache => {
              cache.put(request, responseClone);
            });
            return response;
          })
          .catch(() => {
            // Fallback to cache if offline
            return caches.match(request);
          })
      );
      return;
    }
  }

  // Cache first for everything else (CSS, JS, images, fonts)
  event.respondWith(
    caches.match(request)
      .then(response => {
        if (response) {
          return response;
        }

        return fetch(request).then(response => {
          // Don't cache non-successful responses
          if (!response || response.status !== 200) {
            return response;
          }

          const responseClone = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(request, responseClone);
          });

          return response;
        }).catch(() => {
          return new Response('Offline - but your tracker data is saved locally!', {
            headers: { 'Content-Type': 'text/plain' }
          });
        });
      })
  );
});
