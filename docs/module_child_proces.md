# BeBop framework v1.0 documentation

## child_process ~ Child process Module

### `child_process.execFile(file[, args][, options])`
* `file` \<string> The name or path of the executable file to run.
* `args` \<string[]> List of string arguments.
* `options` \<Object>
  * `codePage` \<integer> Default: `0`
    see: https://docs.microsoft.com/en-us/windows/win32/intl/code-page-identifiers?redirectedfrom=MSDN
  * `windowsHide` \<boolean> Hide the subprocess console window that would normally be created on Windows systems. Default: `true`
  * (ToDo: signal \<AbortSignal> allows aborting an in-progress.)
* Returns: \<Promise> Fulfills with a \<SubProcess> object.

Execute external programs.

see:
https://wiki.lazarus.freepascal.org/Executing_External_Programs

### `subprocess.read([options])`
* `options` \<Object>
  * `wait` \<integer> Default: `1000`
* Returns: \<Promise> Fulfills with a \<object> which has `stdout` \<string>, `stderr` \<string>, and `status` \<integer>.

Read stdout and stderr from the pipe of the subprocess.

### `subprocess.isRunning()`
* Returns: \<Promise> Fulfills with a \<boolean> .

Check the subprocess is running.

### `subprocess.close()`
* Returns: \<Promise>.

Close the subprocess.