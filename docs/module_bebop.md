# BeBop framework v1.0 documentation

## bebop ~ BeBop project Module

### `bebop.app.showMessage(message)`
* `message` \<string> The message of the message box.
* Returns: \<Promise>

Show the application's message box.

### `bebop.app.terminate()`
* Returns: \<Promise>

Terminate the application.

### `bebop.browser.reload()`
* Returns: \<Promise>

Reload current html file.

### `bebop.browser.showDevTools()`
* Returns: \<Promise>

### `bebop.mainform.show()`
* Returns: \<Promise>

### `bebop.mainform.hide()`
* Returns: \<Promise>

### `bebop.mainform.setBounds(left, top, width, height, outer)`
* `left` \<integr>
* `top` \<integr>
* `width` \<integr>
* `height` \<integr>
* `outer` \<bool>
* Returns: \<Promise>

Sets the `left`, `top`, `width`, and `height` properties all at once.

### `bebop.mainform.left getter`
* Returns: \<Promise> Fulfills with a \<integer>

### `bebop.mainform.left setter`
* Returns: Nothing

### `bebop.mainform.top getter`
* Returns: \<Promise> Fulfills with a \<integer>

### `bebop.mainform.top setter`
* Returns: Nothing

### `bebop.mainform.width getter`
* Returns: \<Promise> Fulfills with a \<integer>

### `bebop.mainform.width setter`
* Returns: Nothing

### `bebop.mainform.height getter`
* Returns: \<Promise> Fulfills with a \<integer>

### `bebop.mainform.height setter`
* Returns: Nothing

### `bebop.mainform.caption getter`
* Returns: \<Promise> Fulfills with a \<string>

### `bebop.mainform.caption setter`
* Returns: Nothing

### `bebop.mainform.visible getter`
* Returns: \<Promise> Fulfills with a \<boolean>

### `bebop.mainform.visible setter`
* Returns: Nothing

### `bebop.screen.workAreaWidth getter`
* Returns: \<Promise> Fulfills with a \<integer>

Get width of the screen's work area.

### `bebop.screen.workAreaHeight getter`
* Returns: \<Promise> Fulfills with a \<integer>

Get height of the screen's work area.
