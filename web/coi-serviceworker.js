/* coi-serviceworker v0.1.7 - Cross-Origin Isolation via Service Worker */
/* Necesario para que SharedArrayBuffer funcione en GitHub Pages con SQLite WASM */

if (typeof window === 'undefined') {
  // Contexto: Service Worker
  self.addEventListener('install', () => self.skipWaiting());
  self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

  self.addEventListener('fetch', (e) => {
    const request = e.request;
    if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') return;

    e.respondWith(
      fetch(request)
        .then((r) => {
          const headers = new Headers(r.headers);
          headers.set('Cross-Origin-Opener-Policy', 'same-origin');
          headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
          headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
          return new Response(r.body, {
            status: r.status,
            statusText: r.statusText,
            headers,
          });
        })
        .catch((e) => console.error('[coi-sw] fetch error:', e))
    );
  });

} else {
  // Contexto: página principal — registra el service worker
  (() => {
    if (self.crossOriginIsolated) return; // Ya aislado, nada que hacer

    if (!('serviceWorker' in navigator)) {
      console.warn('[coi-sw] Service workers no disponibles.');
      return;
    }

    const params = new URLSearchParams(location.search);
    if (params.has('coi-reloaded')) {
      console.warn('[coi-sw] No se pudo activar cross-origin isolation.');
      return;
    }

    navigator.serviceWorker
      .register(document.currentScript.src)
      .then((reg) => {
        const reload = () => {
          const url = new URL(location.href);
          url.searchParams.set('coi-reloaded', '1');
          location.replace(url.toString());
        };

        if (reg.active) {
          reload();
          return;
        }
        navigator.serviceWorker.addEventListener('controllerchange', reload);
      })
      .catch((err) => console.error('[coi-sw] Error al registrar:', err));
  })();
}