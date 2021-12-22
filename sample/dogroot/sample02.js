
//
export const main = async props => {

  //
  const Page = props => {

    const refDesktop = React.useRef()
    const refTarget = React.useRef()

    React.useEffect(() => {

      // Moveable is Draggable, Resizable, Scalable, Rotatable, Warpable, Pinchable, Groupable, Snappable
      // https://github.com/daybrush/moveable
      const moveable = new Moveable(document.body, {
        target: refTarget.current,
        // If the container is null, the position is fixed. (default: parentElement(document.body))
        container: refDesktop.current,
        draggable: true,
        resizable: true,
        scalable: true,
        // rotatable: true,
        // warpable: true,
        // Enabling pinchable lets you use events that
        // can be used in draggable, resizable, scalable, and rotateable.
        // pinchable: true, // ["resizable", "scalable", "rotatable"]
        // origin: true,
        // keepRatio: true,
        // Resize, Scale Events at edges.
        edge: false,
        throttleDrag: 0,
        throttleResize: 0,
        throttleScale: 0,
        throttleRotate: 0,
      });
    
      /* draggable */
      moveable.on("dragStart", ({ target, clientX, clientY }) => {
        console.log("onDragStart", target);
      }).on("drag", ({
        target, transform,
        left, top, right, bottom,
        beforeDelta, beforeDist, delta, dist,
        clientX, clientY,
      }) => {
        console.log("onDrag left, top", left, top);
        target.style.left = `${left}px`;
        target.style.top = `${top}px`;
        // console.log("onDrag translate", dist);
        target.style.transform = transform;
      }).on("dragEnd", ({ target, isDrag, clientX, clientY }) => {
        console.log("onDragEnd", target, isDrag);
      });

      /* resizable */
      moveable.on("resizeStart", ({ target, clientX, clientY }) => {
        console.log("onResizeStart", target);
      }).on("resize", ({ target, width, height, dist, delta, clientX, clientY }) => {
        console.log("onResize", target);
        delta[0] && (target.style.width = `${width}px`);
        delta[1] && (target.style.height = `${height}px`);
      }).on("resizeEnd", ({ target, isDrag, clientX, clientY }) => {
        console.log("onResizeEnd", target, isDrag);
      });

      /* scalable */
      moveable.on("scaleStart", ({ target, clientX, clientY }) => {
        console.log("onScaleStart", target);
      }).on("scale", ({
        target, scale, dist, delta, transform, clientX, clientY,
      }) => {
        console.log("onScale scale", scale);
        target.style.transform = transform;
      }).on("scaleEnd", ({ target, isDrag, clientX, clientY }) => {
        console.log("onScaleEnd", target, isDrag);
      });

    }, [])

    return html`
      <div class="h-screen w-full flex flex-col" ref=${refDesktop}>

        <p class="m-4">
          ＜
          <a href="javascript:void(0)" onClick=${e => {
            window.history.back()
          }}>Back</a>
        </p>
        
        <div class="w-60 h-32 m-4 p-4" ref=${refTarget}>You can move this!</div>

      </div>  
    `
  }

  //
  const App = props => {
    return React.createElement(Page)
  }

  //
  ReactDOM.render(React.createElement(App), document.getElementById('App'))

  injectGlobal`
  body {
    font-size: 16px;  /* = 1rem */
    font-family: "Open Sans", Verdana, Roboto, "Droid Sans", "ヒラギノ角ゴ ProN W3", "Hiragino Kaku Gothic ProN", "メイリオ", Meiryo, sans-serif;
    color: rgba(0,0,0,.87);
    background-color: white;
  }
  `
} 
