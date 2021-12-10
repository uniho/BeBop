
export const main = async props => {

  const {app, screen, mainform, browser} = await require('bebop')
  const util = await require('util')

  const w = 800
  const h = 600
  mainform.left = (await screen.workAreaWidth - w) / 2
  mainform.top = (await screen.workAreaHeight - h) / 2
  mainform.width = w
  mainform.height = h
  mainform.caption = 'DEMO デモですよ'

  if (__argv.indexOf('-autostart') >= 0) {
    browser.loadURL('download.html')
  } else if (__argv.indexOf('-testlua') >= 0) {
    browser.loadURL('testlua.html')
  } else if (__argv.indexOf('-test_path') >= 0) {
    browser.loadURL('test_path.html')
  } else if (__argv.indexOf('-test_process') >= 0) {
    browser.loadURL('test_process.html')
  } else if (__argv.indexOf('-test_fs') >= 0) {
    browser.loadURL('test_fs.html')
  } else if (__argv.indexOf('-test_util') >= 0) {
    browser.loadURL('test_util.html')
  } else if (__argv.indexOf('-test_rest') >= 0) {
    browser.loadURL('test_rest.html')
  } else {
    browser.loadURL('sample01.html')
  }
  
  // browser.showDevTools()
  
  mainform.visible = true
  // You can set visible property sync:  
  // * await mainform.set.visible(true)
  //   or 
  // * await mainform.show()
  
}
