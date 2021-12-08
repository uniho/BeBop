# BeBop framework v1.0 documentation

## fs ~ File System Module

### `fs.readFile(file[, options])`
* `file` \<string> The name of a file to read.
* `options` \<Object>
  * `codePage` \<integer> Default: `65001`(utf-8)
    Return \<ArrayBuffer> if it is 0, otherwise \<string>.
    see: https://docs.microsoft.com/en-us/windows/win32/intl/code-page-identifiers?redirectedfrom=MSDN
  * (ToDo: signal \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise> Fulfills with a \<string> | \<ArrayBuffer> A Read data.

Reads the entire contents of a file.
Mainly reads a small size text file.

### `fs.writeFile(file, buffer[, options])`
* `file` \<string>  The name of a file to write.
* `buffer` \<string> | \<ArrayBuffer>
* `options` \<Object>
  * (ToDo: `signal` \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise>

Writes data to a file, replacing the file if it already exists. Mainly writes a small size text file in utf8.

### `fs.mkdir(path[, options])`
* `path` \<string>
* `options` \<Object>
  * `recursive` \<boolean> Default: false.
* Returns: \<Promise>

Creates a directory.
see https://nodejs.org/api/fs.html#fspromisesmkdirpath-options

### `fs.rm(path[, options])`
* `path` \<string>
* `options` \<Object>
  * `recursive` \<boolean> If true, perform a recursive directory removal. Default: false.
* Returns: \<Promise>

Removes files and directories.
see https://nodejs.org/api/fs.html#fspromisesrmpath-options

### `fs.rename(oldPath, newPath)`
* `oldPath` \<string>
* `newPath` \<string>
* Returns: \<Promise>

Renames oldPath to newPath.
see https://nodejs.org/api/fs.html#fspromisesrenameoldpath-newpath

### `fs.readdir(path[, options])`
* `path` \<string>
* `options` \<Object>
  * (ToDo: signal \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise> Fulfills with <fs.Dirent> objects.

Reads the contents of a directory.
see https://nodejs.org/api/fs.html#fspromisesreaddirpath-options

### `fs.stat(path)`
* `path` \<string>
* Returns: \<Promise> Fulfills with <fs.Stats> objects.

see https://nodejs.org/api/fs.html#fspromisesstatpath-options

### `fs.open(file[, options])`
* `file` \<string> The name of a file to open.
* `flags` \<string>
  * `r` | `r+` | `w` | `w+` Default: `r`. see: https://nodejs.org/api/fs.html#file-system-flags
* Returns: \<Promise> Fulfills with a \<fs.FileHandle> object.

Opens a /<fs.FileHandle>.

### `filehandle.read([length][, options])`
* `length` \<integer> The number of bytes to read. Default: 16384.
* `options` \<Object>
  * (ToDo: signal \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise> Fulfills with a \<ArrayBuffer> A Read data | <null> When the number of bytes read is zero

### `filehandle.write(buffer[, options])`
* `buffer` \<ArrayBuffer> | \<string>
* `options` \<Object>
  * (ToDo: `signal` \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise>

### `filehandle.size()`
* Returns: \<Promise> Fulfills with a \<integer>

### `filehandle.seek([offset][, origin])`
* `offset` \<integer> | (ToDo:\<BigInt>) The number of bytes from origin. Default: `0`.
* `origin` \<integer> `0`: From the beginning, `1`: From current position, `2`: From the end Default: `0`.
* Returns: \<Promise> Fulfills with a \<integer> New position | `-1`.

see:
  https://www.freepascal.org/docs-html/rtl/sysutils/fileseek.html
  https://docwiki.embarcadero.com/Libraries/Sydney/en/System.SysUtils.FileSeek

### `filehandle.close()`
* Returns: \<Promise>

Closes the file handle.

### `dirent.isDirectory()`
* Returns: \<boolean>

Returns true if the \<fs.Dirent> object describes a file system directory.
see https://nodejs.org/api/fs.html#direntisdirectory
