import {screen, mainform, browser} from '/~/bebop'

mainform.caption = 'DEMO デモですよ'

const w = 800
const h = 600
const l = (await screen.workAreaWidth - w) / 2 + await screen.workAreaLeft
const t = (await screen.workAreaHeight - h) / 2 + await screen.workAreaTop
// mainform.left = l
// mainform.top = t
// mainform.width = w
// mainform.height = h
await mainform.setBounds(l, t, w, h, true)

if (__argv.indexOf('-autostart') >= 0) {
  location.href = 'download.html'
} else if (__argv.indexOf('-testlua') >= 0) {
  location.href = 'testlua.html'
} else if (__argv.indexOf('-test_path') >= 0) {
  location.href = 'test_path.html'
} else if (__argv.indexOf('-test_process') >= 0) {
  location.href = 'test_process.html'
} else if (__argv.indexOf('-test_fs') >= 0) {
  location.href = 'test_fs.html'
} else if (__argv.indexOf('-test_util') >= 0) {
  location.href = 'test_util.html'
} else if (__argv.indexOf('-test_rest') >= 0) {
  location.href = 'test_rest.html'
} else if (__argv.indexOf('-test_web') >= 0) {
  location.href = 'test_web.html'
} else {
  location.href = 'sample01.html'
}

// browser.showDevTools()

mainform.visible = true
// You can set visible property sync:  
// * await mainform.set.visible(true)
//   or 
// * await mainform.show()

