# 🎧 BeBop framework

## The Next Generation of `S+E+L+F` Development

BeBop framework is a development tool to create cross-platform desktop applications using JavaScript, HTML, and CSS.

Yes, it is like [Electron](https://www.electronjs.org/), but based on [Lazarus](https://www.lazarus-ide.org/) and [FPC (Free Pascal Compiler)](https://www.freepascal.org/) instead of [Node.JS](https://nodejs.org/).

Node.JS is a great library, but will you make things like air planes or motor vehicles?
More isn't always better, either for the customer or for the engineer.
We should cut our coat according to our cloth.

BeBop framework aims at `S+E+L+F` development that means SIMPLE, EASY, LIGHT, and FAST.

Lazarus is a free cross-platform visual integrated development environment (IDE) for rapid application development (RAD) using FPC, and for a number of different platforms, including MacOS, Chromebook, Linux, and Windows.

Lazarus with FPC generate very fast small native binaries even though they provide an easy-to-use development, and thus it makes frontend engineers release from the many issues, including the excuse for legitimatery slacking off: "My code's compiling."

## 🎼 Get started

### ♪ Windows 32bit / 64bit

1. Download the latest version of BeBop framework from [Releases page in this repository](../../releases).
   * You can take `bebop.exe` from `bebop-v1.x.x+x.x.x-win32.zip` or `bebop-v1.x.x+x.x.x-win64.zip`.
   * Also, `bebop.cfg`, `bebop.ico` and some files put in `dogroot` directory from `sample-v1.x.x+x.x.x.zip`.
1. Download the CEF binarie files from [CEF Automated Builds](https://cef-builds.spotifycdn.com/index.html).
   * [For Windows 32bit](https://cef-builds.spotifycdn.com/index.html#windows32:102.0.10)
   * [For Windows 64bit](https://cef-builds.spotifycdn.com/index.html#windows64:102.0.10)

   Current supported CEF version is `102.0.10`, and "Minimal" type is recommended.
  
   If you cannot find it, click `Show All Builds` or `Show more builds` link at the bottom.
1. Out of the CEF binarie files, we just need directories named `Release` and `Resources`. Other directories are unnessesary.
1. Dive into directory named `Resources`. 
1. You will see 1 dir (named `locales`) and 4 files (`chrome_100_percent.pak`, `chrome_200_percent.pak`, `icudtl.dat`, and `resources.pak`). Copy these 5 items (1 dir + 4 files) into `Release` directory.
1. `Resources` directory is no longer nessesary. `Release` directory left, which is the place you run the application on. Copy `bebop.exe`, `bebop.cfg`, `bebop.ico` and `dogroot` directory to the `Release` directory.
1. Click the `bebop.exe`, and a new app will be your new best friend.

### ♪ Linux 64bit

1. Download the latest version of BeBop framework from [Releases page in this repository](../../releases).
   * You can take `bebop` from `bebop-v1.x.x+x.x.x-linux64.zip`.
   * Also, `bebop.cfg`, `bebop.ico` and some files put in `dogroot` directory from `sample-v1.x.x+x.x.x.zip`.
1. Download the CEF binarie files from [CEF Automated Builds (Linux 64-bit)](https://cef-builds.spotifycdn.com/index.html#linux64:102.0.10).

   Current supported CEF version is `102.0.10`, and "Minimal" type is recommended.
  
   If you cannot find it, click `Show All Builds` or `Show more builds` link at the bottom.
1. Out of the CEF binarie files, we just need directories named `Release` and `Resources`. Other directories are unnessesary.
1. Dive into directory named `Resources`. 
1. You will see 1 dir (named `locales`) and 4 files (`chrome_100_percent.pak`, `chrome_200_percent.pak`, `icudtl.dat`, and `resources.pak`). Copy these 5 items (1 dir + 4 files) into `Release` directory.
1. `Resources` directory is no longer nessesary. `Release` directory left, which is the place you run the application on. Copy `bebop`, `bebop.cfg`, `bebop.ico` and `dogroot` directory to the `Release` directory.
1. Click the `bebop`, and a new app will be your new best friend.


### ♪ MacOS 64bit
1. Download the latest version of BeBop framework from [Releases page in this repository](../../releases).
   * You can take `bebop` and `bebop.app` from `bebop-v1.x.x+x.x.x-macosx64.zip`.
   * Also, `bebop.cfg` and some files put in `dogroot` directory from `sample-v1.x.x+x.x.x.zip`.
1. Put `bebop.app`, `bebop`, `bebop.cfg` and `dogroot` directory into a same directory. (`bebop.app` is a kind of [bundle file](https://en.wikipedia.org/wiki/Bundle_(macOS)), so you can handle it like a directory.)

```
<Your Dir>
  ├ <dogroot>
  ├ <bebop.app>
  ├ bebop
  └ bebop.cfg
```

3. Download the CEF binarie files from [CEF Automated Builds (MacOS 64-bit)](https://cef-builds.spotifycdn.com/index.html#macosx64:102.0.10).

   Current supported CEF version is `102.0.10`, and "Minimal" type is recommended.
  
   If you cannot find it, click `Show All Builds` or `Show more builds` link at the bottom.
1. Out of the CEF binarie files, we just need `/Release/Chromium Embedded Framework.framework` directory. Other directories are unnessesary.
1. Copy `Chromium Embedded Framework.framework` directory into `bebop.app/Contents/Frameworks` directory. `bebop.app` is a kind of [bundle file](https://en.wikipedia.org/wiki/Bundle_(macOS)), so you can handle it like a directory.

```
<bebop.app>
   └ <Contents>
       ├ <Frameworks>
       │    ├ <Chromium Embedded Framework.framework> 👈👈👈
       │    │    ├ <Libraries>
       │    │    │     └ ... 
       │    │    ├ <Resources>
       │    │    │     └ ... 
       │    │    └ Chromium Embedded Framework
       │    ├ bebop Helper.app
       │    ├ bebop Helper(GPU).app
       │    ├ bebop Helper(Renderer).app
       │    └ bebop Helper(Plugin).app
       ├ <MacOS>
       │    └ 🔗bebop
       ├ <Resources>
       │    ├ 🔗<dogroot>
       │    └ 🔗bebop.cfg
       ├ info.plist
       └ PkgInfo

🔗:Symbolic Link
```

Your Directory again.
```
<Your Dir>
  ├ <dogroot>
  ├ <bebop.app>
  ├ bebop
  └ bebop.cfg
```

6. Click the `bebop.app` then a new app will be your new best friend.

### ♪ Chromebook
COMING SOON MAYBE. Any help is welcome.

## 👶 First steps
See samples `.html` and `.js` source codes put in `dogroot` directory.
`index.html` is the beginning of everything.

If you have built websites with JavaScript / HTML / CSS, and desktop applications with C++ / C# / Delphi / VB / etc., you should be able to create new desktop applications soon.

Default key mappings:
* `F5` Reload current html page.
* `F12` Show the Developer's Tool.
* `Backspace` Go back page.

These samples use [ReactJS](https://reactjs.org/), but you don't really need it.
You can use your favorite JS framework - [jQuery](https://jquery.com/), [AngularJS](https://angularjs.org/), [VueJS](https://vuejs.org/), [SolidJS](https://www.solidjs.com/), etc., or even just pure vanilla JavaScript.

Further documents are in the `/docs` directory.

## 🚀 Next steps
You can create your own native modules and in-process REST API. See source files, `/source/unit_mod_xxxxx.pas` and `/source/unit_rest_xxxxx.pas`. 
1. Clone this repository. Don't forget to update submodules.
1. Download the Lazarus IDE.
1. Run Lazarus IDE.
1. Click `Project` -> `Open Project`, and select `/source/bebop.lpi`
1. Click `Run` -> `Build`

## 🤔 Simple? Easy?
BeBop is a development tool for general desktop applications. Unlike a kind of system batch process in the cool black window, we have to create an application with the user-friendly interface for our users.  
The user-friendly interface needs asyncronus process no lagging, so you need to figure the `Promise` in JavaScript out.
YOU CAN DO IT! 

## 🛺 Light? Fast?
[Lazarus](https://www.lazarus-ide.org/) and [FPC (Free Pascal Compiler)](https://www.freepascal.org/) can build native binaries without depending on any runtime environment (Though the Linux family OS needs GTK or QT framework, they are almost a part of their OS Systems). 
As it is known, FPC can even link object files of C langauge.

## 🌱 Ecosystem

### ♪ Chromium Embedded Framework (CEF)
BeBop framework gets power from CEF (Chromium Embedded Framework).

[CEF (Chromium Embedded Framework)](https://bitbucket.org/chromiumembedded/cefhttps://bitbucket.org/chromiumembedded/cef) is a simple framework for embedding Chromium-based browsers in other applications.
Unlike the [Chromium project](https://www.chromium.org/) itself, which focuses mainly on Google Chrome application development, CEF focuses on facilitating embedded browser use cases in third-party applications.

### ♪ salvadordf / CEF4Delphi
BeBop framework gets power from CEF through CEF4Delphi.

[CEF4Delphi](https://github.com/salvadordf/CEF4Delphi) is an open source project to embed Chromium-based browsers in applications made with Delphi or Lazarus/FPC for Windows, Linux and MacOS.

### ♪ synopse / mORMot

BeBop framework has a powerful in-process REST API based on mORMot.

[mORMot](https://github.com/synopse/mORMot) is an Open Source Client-Server Object-relational mapping (ORM) / Service-Oriented Architecture (SOA) / Model-View-Controller (MVC) framework for Delphi and Lazarus/FPC, targeting Windows/Linux for servers, and any platform for clients.

mORMot is a huge library / framework, but FPC links just the necessary part.

### ♪ Lazarus and FPC
We are using below.

#### Windows (win32/win64)
Lazarus 2.2.2 + FPC 3.2.2

#### Linux (x86_64-linux-gtk2)
Lazarus 2.2.2 + FPC 3.2.2
  
#### MacOS (x86_64-darwin-cocoa)
Lazarus 2.2.2 + FPC 3.2.2


## 🎵 Code of conduct
This project is learning from [The Rust's Code of conduct](https://www.rust-lang.org/policies/code-of-conduct):
* We are committed to providing a friendly, safe and welcoming environment for all, regardless of level of experience, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, nationality, or other similar characteristic.
* Please avoid using overtly sexual aliases or other nicknames that might detract from a friendly, safe and welcoming environment for all.
* Please be kind and courteous. There’s no need to be mean or rude.
* Respect that people have differences of opinion and that every design or implementation choice carries a trade-off and numerous costs. There is seldom a right answer.
* Please keep unstructured critique to a minimum. If you have solid ideas you want to experiment with, make a fork and see how it works.
* We will exclude you from interaction if you insult, demean or harass anyone. That is not welcome behavior. We interpret the term “harassment” as including the definition in the Citizen Code of Conduct; if you have any lack of clarity about what might be included in that concept, please read their definition. In particular, we don’t tolerate behavior that excludes people in socially marginalized groups.
* Private harassment is also unacceptable. No matter who you are, if you feel you have been or are being harassed or made uncomfortable by a community member, please contact one of the channel ops or any of the Rust moderation team immediately. Whether you’re a regular contributor or a newcomer, we care about making this community a safe place for you and we’ve got your back.
* Likewise any spamming, trolling, flaming, baiting or other attention-stealing behavior is not welcome.

## 👏 Contribution
### ♪ By PR (Pull Request)
Feel free to open a pull-request.
### ♪ As a Coraborater
Coraboraters are welcome!
### ♪ As a Supporter
😻I like beers🍺

## 📝 Licence
The MIT License.

You should check the license of Lazarus, FPC, Cef4Delphi, mORMot, and CEF.  
