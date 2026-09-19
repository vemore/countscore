'use strict';

// CountScore's service worker: the PWA opens and works with no network after one online
// visit. .llmwiki/Web.md, "Offline and updates".
//
// - The build's shell is precached at install, into a cache named after the build.
//   scripts/build_web.sh replaces the three constants below: BUILD_ID is a hash of the
//   whole build, PRECACHE and ON_DEMAND map each path to its SHA-256. Every response is
//   checked against that digest before it is cached, so a cache never holds a file from
//   another build, even when a deploy lands in the middle of an install.
// - ON_DEMAND is CanvasKit: the browser loads one variant of several, so a variant is
//   cached once the page reports having used it (the "cache-loaded" message), and an update
//   fetches the variants the previous build had cached.
// - The engine's fallback fonts (fallback-fonts/, 725 files) are never precached: each is
//   cached when fetched, in a cache shared by every build (their paths are versioned).
// - A new build installs beside the old one and waits. The page (web/flutter_bootstrap.js)
//   offers a reload; "skip-waiting" activates it, the old caches go, and every open page
//   reloads onto the new build. Nothing is served from two builds at once.
//
// Unbuilt (flutter run, a bare flutter build web) the constants keep these values, and
// flutter_bootstrap.js does not register the worker at all.

const BUILD_ID = 'unbuilt'; // @build-id
const PRECACHE = {}; // @precache
const ON_DEMAND = {}; // @on-demand

const BUILD_PREFIX = 'countscore-build-';
const SHELL = BUILD_PREFIX + BUILD_ID;
const FONTS = 'countscore-fonts';
const SCOPE = self.registration.scope; // the base href: PWA_BASE_PATH + '/', or /<repo>/
const SCOPE_PATH = new URL(SCOPE).pathname;

const urlOf = (path) => new URL(path, SCOPE).href;

async function sha256(buffer) {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', buffer));
  return Array.from(digest, (b) => b.toString(16).padStart(2, '0')).join('');
}

// A cacheable copy of the response, if its body is the one this build names. The headers
// are kept: a cached index.html still carries the Content-Security-Policy it was served with.
async function verified(response, path) {
  if (!response.ok) return null;
  const body = await response.arrayBuffer();
  if ((await sha256(body)) !== (PRECACHE[path] || ON_DEMAND[path])) return null;
  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

async function fetchVerified(path) {
  // no-cache: revalidate, so an HTTP cache (GitHub Pages sends max-age=600) cannot hand
  // back the previous build's copy.
  const response = await fetch(urlOf(path), { cache: 'no-cache' });
  return verified(response, path);
}

async function previousBuilds() {
  const names = await caches.keys();
  return names.filter((n) => n.startsWith(BUILD_PREFIX) && n !== SHELL);
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(SHELL);
      const previous = await Promise.all((await previousBuilds()).map((n) => caches.open(n)));
      const paths = [...Object.keys(PRECACHE), ...Object.keys(ON_DEMAND)];
      await Promise.all(
        paths.map(async (path) => {
          const key = urlOf(path);
          if (await cache.match(key)) return; // verified by an earlier, interrupted install
          // A file the last build already had, unchanged, is copied rather than downloaded.
          let usedBefore = false;
          for (const old of previous) {
            const hit = await old.match(key);
            if (!hit) continue;
            usedBefore = true;
            const copy = await verified(hit, path);
            if (copy) return cache.put(key, copy);
          }
          // The shell always; a CanvasKit variant only if this browser used it before.
          if (!(path in PRECACHE) && !usedBefore) return;
          const fresh = await fetchVerified(path);
          // A file that does not match means the server holds another build already: fail
          // the install, and the browser tries again with the worker of that build.
          if (!fresh) throw new Error(`${path} is not the file of build ${BUILD_ID}`);
          await cache.put(key, fresh);
        }),
      );
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      await Promise.all((await previousBuilds()).map((n) => caches.delete(n)));
      await self.clients.claim();
    })(),
  );
});

// The path of a same-origin URL inside the scope, relative to it; null for anything else
// (the API, a backend on another host, the privacy page next to a Pages build...).
function pathInScope(url) {
  const u = new URL(url);
  if (u.origin !== self.location.origin || !u.pathname.startsWith(SCOPE_PATH)) return null;
  try {
    return decodeURIComponent(u.pathname.slice(SCOPE_PATH.length));
  } catch (e) {
    return null;
  }
}

async function fromShell(path, request) {
  const cache = await caches.open(SHELL);
  const hit = await cache.match(urlOf(path));
  if (hit) return hit;
  if (path in ON_DEMAND) {
    const fresh = await fetchVerified(path);
    if (fresh) {
      await cache.put(urlOf(path), fresh.clone());
      return fresh;
    }
    // The server has another build: never hand this page a file of it. Look for the new
    // worker; the page applies it at once, since the app could not start.
    self.registration.update().catch(() => {});
    return Response.error();
  }
  return fetch(request);
}

async function fromFonts(request, path) {
  const cache = await caches.open(FONTS);
  const hit = await cache.match(urlOf(path));
  if (hit) return hit;
  const response = await fetch(request);
  if (response.ok) await cache.put(urlOf(path), response.clone());
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (BUILD_ID === 'unbuilt' || request.method !== 'GET') return;
  const path = pathInScope(request.url);
  if (path === null) return;
  if (request.mode === 'navigate') {
    // The hash URL strategy: the app itself is only ever the scope's root.
    if (path === '' || path === 'index.html') event.respondWith(fromShell('index.html', request));
    return;
  }
  if (path in PRECACHE || path in ON_DEMAND) {
    event.respondWith(fromShell(path, request));
  } else if (path.startsWith('fallback-fonts/')) {
    event.respondWith(fromFonts(request, path));
  }
});

// Files the page loaded before this worker controlled it (the first visit): CanvasKit and
// the fallback fonts it used, which no fetch event ever showed this worker.
async function cacheLoaded(urls) {
  const shell = await caches.open(SHELL);
  const fonts = await caches.open(FONTS);
  for (const url of urls) {
    const path = pathInScope(url);
    if (path === null) continue;
    try {
      if (path in ON_DEMAND && !(await shell.match(urlOf(path)))) {
        const fresh = await fetchVerified(path);
        if (fresh) await shell.put(urlOf(path), fresh);
      } else if (path.startsWith('fallback-fonts/') && !(await fonts.match(urlOf(path)))) {
        const response = await fetch(urlOf(path));
        if (response.ok) await fonts.put(urlOf(path), response);
      }
    } catch (e) {
      // Offline, or gone from the server: it is cached the next time it is fetched.
    }
  }
}

self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'skip-waiting') {
    self.skipWaiting();
  } else if (data.type === 'cache-loaded' && Array.isArray(data.urls)) {
    event.waitUntil(cacheLoaded(data.urls));
  }
});
