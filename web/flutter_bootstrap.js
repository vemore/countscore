{{flutter_js}}
{{flutter_build_config}}

// The stock template, with two changes.
//
// 1. The engine fetches the fonts it falls back to (Roboto on every start, then a Noto font
// for a glyph Nunito lacks — Chinese, Arabic, Devanagari, emoji...) from
// fontFallbackBaseUrl, which defaults to fonts.gstatic.com. scripts/build_web.sh mirrors
// those files into build/web/fallback-fonts/, so they are served by whoever serves the PWA
// and no browser asks Google for them. The path is relative, so it follows --base-href.
// .llmwiki/Web.md, "Self-hosted web resources".
//
// 2. The loader gets no service-worker settings: Flutter's own flutter_service_worker.js
// is a stub that unregisters itself, and registering it would replace ours (one
// registration per scope). CountScore's worker is web/service_worker.js, registered below.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: "fallback-fonts/",
  },
});

// CountScore's service worker (web/service_worker.js): offline after one online visit, and
// a reload offered when a deploy has a new build waiting. scripts/build_web.sh turns this
// on in the build it makes; a debug run or a bare `flutter build web` registers nothing.
// .llmwiki/Web.md, "Offline and updates".
const countscoreServiceWorker = false; // @service-worker
(function () {
  // Read by lib/services/pwa_update_web.dart. The app sets onUpdateReady once it is on
  // screen; applyUpdate activates the waiting build, and every open page reloads onto it.
  const pwa = (window.countscorePwa = {
    updateReady: false,
    onUpdateReady: null,
    applyUpdate: function () {},
  });
  if (!countscoreServiceWorker || !("serviceWorker" in navigator)) return;
  const sw = navigator.serviceWorker;
  const hadController = !!sw.controller;
  let reloading = false;

  // First visit: the page loaded CanvasKit and some fonts before the worker controlled it;
  // tell the worker which, so the next start needs no network.
  function reportLoaded() {
    if (!sw.controller) return;
    const urls = performance.getEntriesByType("resource").map((e) => e.name);
    sw.controller.postMessage({ type: "cache-loaded", urls: urls });
  }

  sw.addEventListener("controllerchange", function () {
    if (!hadController) return reportLoaded();
    // A new build took over: reload onto it rather than run on with the old one's code.
    if (!reloading) {
      reloading = true;
      window.location.reload();
    }
  });

  function offer(worker) {
    pwa.applyUpdate = function () {
      worker.postMessage({ type: "skip-waiting" });
    };
    if (pwa.onUpdateReady) {
      pwa.updateReady = true;
      pwa.onUpdateReady();
    } else {
      // The app is not on screen yet, so there is nothing to lose: take the new build now.
      pwa.applyUpdate();
    }
  }

  async function register() {
    try {
      // Relative, so it follows the base href: the scope is PWA_BASE_PATH + "/".
      const reg = await sw.register("service_worker.js", { updateViaCache: "none" });
      if (reg.waiting && sw.controller) offer(reg.waiting);
      reg.addEventListener("updatefound", function () {
        const worker = reg.installing;
        if (!worker) return;
        worker.addEventListener("statechange", function () {
          if (worker.state === "installed" && sw.controller) offer(worker);
        });
      });
      reportLoaded();
      // An installed PWA can stay open for days: look for a new build when it comes back.
      document.addEventListener("visibilitychange", function () {
        if (document.visibilityState === "visible") reg.update().catch(function () {});
      });
    } catch (e) {
      console.warn("CountScore: service worker registration failed", e);
    }
  }
  if (document.readyState === "complete") register();
  else window.addEventListener("load", register);
})();
