## Next version

* Not yet

## v1.1.1+103.0.8

* CEF 103.0.8 / Lazarus 2.2.2 / FPC 3.2.2
* [web_util module] Add `web_util.scraping()`.

## v1.1.0+102.0.10

* CEF 102.0.10 / Lazarus 2.2.2 / FPC 3.2.2
* 🚀 Launch BeBop for MacOS!
* Add icon.
* [bebop module] Add `mainform.setBounds()`.
* [fs module] Add `fs.cp()`.
* [child_process module] Add `cwd` option.
* [child_process module] Add `env` option.
* Add web_util module.
* Set `require()` deprecated.
  Please use [`import statement`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import) instead.  

## v1.0.2+101.0.18

* CEF 101.0.18 / Lazarus 2.2.2 / FPC 3.2.2
* `browser.loadURL()` has been deprecated. Please use `window.location.href = newURL` instead.
* `browser.goBack()` and `browser.goForward()` have been deprecated. Please use [`window.history.back()`](https://developer.mozilla.org/en-US/docs/Web/API/History/back) and [`window.history.forward()`](https://developer.mozilla.org/en-US/docs/Web/API/History/forward) instead.

## v1.0.1+96.0.18

* CEF v96.0.16 -> v96.0.18
* Set `requireSync()` deprecated.
  Please use [Top-level await](https://github.com/tc39/proposal-top-level-await) instead.  
* Fix many issues for GTK2 on Linux.
* Fix a issue for 64bit CPU.
