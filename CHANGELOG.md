## Next version

* `browser.loadURL()` has been deprecated. Please use `window.location.href = newURL` instead.

* `browser.reload()` has been deprecated.
Please use [`location.reload()`](https://developer.mozilla.org/en-US/docs/Web/API/Location/reload)  or `window.location.href = window.location.href` (with clear cache, called Super Reload) instead.

* `browser.goBack()` and `browser.goForward()` have been deprecated. Please use [`window.history.back()`](https://developer.mozilla.org/en-US/docs/Web/API/History/back) and [`window.history.forward()`](https://developer.mozilla.org/en-US/docs/Web/API/History/forward) instead.

## v1.0.1+96.0.18

* CEF v96.0.16 -> v96.0.18
* Set `requireSync()` deprecated.
  Please use [Top-level await](https://github.com/tc39/proposal-top-level-await) instead.  
* Fix many issues for GTK2 on Linux.
* Fix a issue for 64bit CPU.
