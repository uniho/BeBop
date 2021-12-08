# BeBop framework v1.0 documentation

## util ~ Utilities Module

### `util.UTF8Decode(utf8)`
* `utf8` \<ArrayBuffer>
* Returns: \<string>

Converts utf8\<ArrayBuffer> to utf16\<string>.

see:
https://www.freepascal.org/docs-html/rtl/system/utf8decode.html
https://docwiki.embarcadero.com/Libraries/Sydney/en/System.UTF8Decode

### `util.UTF8Encode(utf16)`
* `utf16` \<string>
* Returns: \<ArrayBuffer>

Converts utf16\<string> to utf8\<ArrayBuffer>.

see:
https://www.freepascal.org/docs-html/rtl/system/utf8encode.html
https://docwiki.embarcadero.com/Libraries/Sydney/en/System.UTF8Encode

### `util.SetCodePage(target, mscodepage)`
* `target` \<string> | \<ArrayBuffer>
* `mscodepage` \<integer>
* Returns: \<ArrayBuffer> | \<string>

Sets the codepage of target \<string> or \<ArrayBuffer>.

see:
https://lazarus-ccr.sourceforge.io/docs/rtl/system/setcodepage.html
https://docwiki.embarcadero.com/Libraries/Sydney/en/System.SetCodePage
https://docs.microsoft.com/en-us/windows/win32/intl/code-page-identifiers?redirectedfrom=MSDN

### `util.GetSystemDefaultLCID()`
* Returns: \<integer>

Windows only.

see:
https://docs.microsoft.com/ja-jp/windows/win32/api/winnls/nf-winnls-getsystemdefaultlcid

### `util.CreateUUID()`
* Returns: \<string>

Creates Unique Identifier.

see:
https://www.freepascal.org/docs-html/rtl/sysutils/createguid.html
