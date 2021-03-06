
// Emotion is a performant and flexible CSS-in-JS library. 
// https://github.com/emotion-js/emotion
import {css, injectGlobal} from 'https://cdn.skypack.dev/@emotion/css?min'
import * as process from '/~/process'

const targetURI = 
  // 'https://www.youtube.com/watch?v=XVYqWcbPAUk'
  'https://www.youtube.com/playlist?list=PL590L5WQmH8cGD7hVGK_YvAUWdXKfGLJ1'

const autoStart = __argv.indexOf('-autostart') >= 0
let autoClose = autoStart

//
export default props => {

  const [stateShowProcess, setStateShowProcess] = React.useState(false);
  const [stateDownloading, setStateDownLoading] = React.useState(false)
  const [stateCanceling, setStateCanceling] = React.useState(false)
  const [stateFileList, setStateFileList] = React.useState([])
  const userAbort = React.useRef(false)

  //
  const start = async (uri) => {
    try {
      const res = await fetch(uri)

      if (res.ok) {
        const text = await res.text()
        const listJsonText = text.match(/({\s*?"responseContext":\s*?{.+}\s*?]\s*?,\s*?"trackingParams":\s*?"[^"]+"\s*?}\s*?}\s*?});/)
        
        const fileList = []

        if (!listJsonText) {
          fileList.push({name: uri, status: ''})
          setStateFileList(fileList)
          await download(uri, 0, updateFileList, checkAbort, !stateShowProcess)
          setStateDownLoading(false)
          return
        }

        const listJson = await JSON.parse(listJsonText[1])
        const list = listJson.contents.twoColumnBrowseResultsRenderer.tabs[0].
          tabRenderer.content.sectionListRenderer.contents[0].
          itemSectionRenderer.contents[0].
          playlistVideoListRenderer.contents

        for (const item of list) {
          fileList.push({name: item.playlistVideoRenderer.videoId, status: ''})
        }

        setStateFileList(fileList)

        for (let i = 0; i < list.length; i++) {
          if (userAbort.current) break;
          const ok = await download('https://www.youtube.com/watch?v=' + fileList[i].name, i, updateFileList, checkAbort, !stateShowProcess)
          if (!ok) break;
        }
      }
    } finally {
      setStateDownLoading(false)
      setStateCanceling(false)
      if (autoClose) {
        const bebop = await import('/~/bebop')
        bebop.app.terminate()
      }
    }  
  }

  //
  const updateFileList = (index, data) => {
    if (index >= 0 && data) {
      setStateFileList(state => {
        const list = [...state]
        list[index] = {...list[index], ...data}
        return list
      })
    }  
  }

  //
  const checkAbort = () => userAbort.current;

  //
  const refStartButton = React.useRef()
  React.useEffect(() => {
    if (autoStart) {
      // Auto Start!
      refStartButton.current.click()
    }
  }, [])

  //
  return html`
  <div class=${style1}>
    <div>Target URI:</div>
    <a href=${targetURI}>${targetURI}</a>
    
    <div>
      <button ref=${refStartButton} disabled=${stateCanceling} onClick=${e => {
        if (stateCanceling) return;
        if (stateDownloading) {
          userAbort.current = true
          setStateCanceling(true)
        } else {
          setStateDownLoading(true)
          setStateFileList([])
          userAbort.current = false
          start(targetURI)
        }
      }}>
        ${stateCanceling ? 'Canceling...' : 
          (stateDownloading ? 'Stop Download' : 'Start Download')}
      </button>
      
      ${
        process.platform == 'win32' ? html`
        <label>
          <input type="checkbox" disabled=${stateDownloading} onChange=${e => {
            setStateShowProcess(state => !state)
          }} />
          Show Process
        </label>
        ` : null
      }
    </div>

    ${function _() {
      const fileList = stateFileList.map((item, index) => {
        return html`
        <div class="item" key=${index}>
          <div>${item.status == 'NOW' ? '???' : item.status}</div>
          <div>${item.name + (item.size ? ' - ' + item.size : '')}</div>
        </div>
        `
      })
    
      if (stateDownloading) {
        return html`
        <div class="filelist">
          ${stateFileList.length ? fileList : 'Now Loading...'}
        </div>`
      }
    
      return html`
      <div class="filelist">
        ${stateFileList.length ? fileList : null}
      </div>`
    }()}    
  </div>
  `
}

//
const download = async (uri, index, updateFunc, checkAbortFunc, windowsHide) => {
  
  const ffmpeg = await checkFFMPEG()
  if (!ffmpeg) return false;

  const res = await fetch(uri)

  const fs = await import('/~/fs')
  const path = await import('/~/path')
  const {execFile} = await import('/~/child_process')
  const util = await import('/~/util')
  
  if (res.ok) {
    const text = await res.text()

    const [, title] = text.match(/<meta\s*?property="og:title"\s*?content="([^"]+)"\s*?>/)
    const [, jsonText] = text.match(/"streamingData":\s*?({.+}),\s*"playbackTracking":\s*{/)
    const json = await JSON.parse(jsonText)  
    // console.log(json.formats)
    // console.log(json.adaptiveFormats)
    updateFunc(index, {name: json.formats[0].url, status: ''})
    
    const fileName = unescapeHTML(title).replace(/\:|\?|\.|"|<|>|\||\\|\//g, '_') + ".m4a"
    updateFunc(index, {name: fileName, status: 'NOW'})

    let saveName
    if (process.platform == 'win32' || process.platform == 'linux') {
      saveName = path.join(__execPath, 'downloads', fileName)
      await fs.mkdir(path.dirname(saveName), {recursive: true})
    } else {
      // darwin
      saveName = path.join(process.env['HOME'], 'Downloads', fileName)
    }
  
    const tempName = path.join(path.dirname(saveName), '_tmp.' + util.CreateUUID() + '.m4a')

    const fileExits = await fs.stat(saveName)
      .then(() => true)
      .catch(() => false)

    if (!fileExits) {
      try {
        const options = {
          windowsHide,
        }
        if (util.GetSystemDefaultLCID() == 1041/*ja*/) {
          // Just to be sure
          options.codePage = 932/*SJIS*/
        }
      
        const exec = await execFile(ffmpeg, [
          '-y', '-hide_banner',
          '-loglevel', 'info',
          '-i', json.formats[0].url,
          '-absf', 'aac_adtstoasc',
          '-acodec', 'copy',
          tempName,
        ], options)

        let status = 0
        if (windowsHide) {
          // Use pipes
          let size = ''
          while (await exec.isRunning() && !checkAbortFunc()) {
            const read = await exec.read()
            status = read.status
            if (status != 0) {
              break;
            }
            if (read.stderr.match(/.*HTTP error.*/)) {
              status = -1
              break;
            }
            const match = read.stderr.match(/size=\s*(.+)\stime=/)
            if (match && match[1] != size) {
              size = match[1]
              updateFunc(index, {size})
            }
          }
          await exec.close()
        } else {
          // Cannot use pipes
          status = exec.status
        }

        if (checkAbortFunc()) {
          updateFunc(index, {status: 'CXL'})
        } else if (status == 0) {
          await fs.rename(tempName, saveName)
          updateFunc(index, {status: 'OK'})
        } else {
          updateFunc(index, {status: 'NG'})
        }
      } finally {
        await fs.rm(tempName)
      }
    } else {
      updateFunc(index, {status: 'SKIP'})
    }
  }
  return true
}

//
const checkFFMPEG = async() => {

  if (process.platform != 'win32') {
    return 'ffmpeg' 
  }

  const path = await import("/~/path")
  const fs = await import("/~/fs")

  const ffmpeg = path.join(__execPath, 'ffmpeg.exe')

  const fileExists = await fs.stat(ffmpeg)
    .then(() => true)
    .catch(() => false)

  if (fileExists) {
    return ffmpeg
  }
    
  const {app} = await import("/~/bebop")
  app.showMessage(`You have to put ${path.basename(ffmpeg)} in "${path.dirname(ffmpeg)}" folder.`)
  return false
}

//  
const unescapeHTML = html => {
  const escapeEl = window.document.createElement("textarea");
  escapeEl.innerHTML = html;
  return escapeEl.textContent;
}

//
const style1 = css`

  & {
    padding: 30px 30px;
    background-color: black;
    color: white;
  }
  
  button {
    background: palevioletred;
    color: white;
    border-radius: 3px;
    border: 2px solid palevioletred;
    margin: 1rem 1rem;
    padding: 0.25rem 1rem;
  }

  a {
    color: white;
  }

  .filelist {
    margin: 1rem 2rem;    
    display: flex;
    flex-direction: column;

    .item {
      display: flex;
    }
    .item > *:first-child {
      width: 3rem;
      margin-right: 1rem;    
    }
  }
`

injectGlobal`
  body {
    font-size: 16px;  /* = 1rem */
    font-family: "Open Sans", Verdana, Roboto, "Droid Sans", "?????????????????? ProN W3", "Hiragino Kaku Gothic ProN", "????????????", Meiryo, sans-serif;
    color: rgba(0,0,0,.87);
    background-color: white;
  }
`
