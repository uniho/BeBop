import {screen, mainform, browser} from '/~/bebop'

export const main = async props => {

  mainform.caption = 'DEMO デモですよ'

  const w = 800
  const h = 600
  // mainform.left = (await screen.workAreaWidth - w) / 2
  // mainform.top = (await screen.workAreaHeight - h) / 2
  // mainform.width = w
  // mainform.height = h
  await mainform.setBounds(
    (await screen.workAreaWidth - w) / 2, (await screen.workAreaHeight - h) / 2,
    w, h
  )

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
  } else {
    location.href = 'sample01.html'
  }
  
  // browser.showDevTools()
  
  mainform.visible = true
  // You can set visible property sync:  
  // * await mainform.set.visible(true)
  //   or 
  // * await mainform.show()
  
}
