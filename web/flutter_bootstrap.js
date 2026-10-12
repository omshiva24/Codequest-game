// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap (kept in a file, not inline, so our Content-Security-Policy
// can forbid inline scripts). Removes the loading screen once Flutter starts.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    const loading = document.getElementById('loading');
    if (loading) loading.remove();
    await appRunner.runApp();
  },
});
