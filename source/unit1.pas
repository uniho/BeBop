unit Unit1;

{.$DEFINE CEF_SINGLE_PROCESS} // Define for debug only.

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, messages, StdCtrls,
  uCEFChromium, uCEFWindowParent, uCEFTypes, uCEFInterfaces;

type

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    CEFWindowParent: TCEFWindowParent;
    InformationPanel: TPanel;
    InformationText: TStaticText;
    FCanClose: boolean;
    procedure ChromiumAfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure ChromiumBeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure ChromiumClose(Sender: TObject; const browser: ICefBrowser; var aAction : TCefCloseBrowserAction);
    procedure ChromiumLoadStart(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; transitionType: TCefTransitionType);
    procedure ChromiumLoadEnd(Sender: TObject; const Browser: ICefBrowser;
     const Frame: ICefFrame; httpStatusCode: Integer);
    procedure ChromiumLoadError(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; errorCode: TCefErrorCode; const errorText, failedUrl: ustring);
    procedure ChromiumPreKeyEvent(Sender: TObject;
      const browser: ICefBrowser; const event: PCefKeyEvent; osEvent: TCefEventHandle;
      out isKeyboardShortcut: Boolean; out Result: Boolean);
    procedure ChromiumKeyEvent(Sender: TObject;
      const browser: ICefBrowser; const event: PCefKeyEvent; osEvent: TCefEventHandle;
      out Result: Boolean);
    procedure ChromiumBeforeBrowse(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; user_gesture, isRedirect: Boolean; out Result: Boolean);
    procedure ChromiumProcessMessageReceived(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId; const message: ICefProcessMessage; out Result: Boolean);
    procedure ChromiumGetResourceHandler(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; var Result: ICefResourceHandler);
    procedure ChromiumGetResourceRequestHandler(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; is_navigation, is_download: boolean; const request_initiator: ustring; var disable_default_handling: boolean; var aExternalResourceRequestHandler : ICefResourceRequestHandler);
    procedure FormShowEvent(Data: PtrInt);
    procedure BrowserCreated(Data: PtrInt);
    procedure BrowserDestroy(Data: PtrInt);
    procedure ChromiumLoadEndEvent(Data: PtrInt);
    procedure ChromiumLoadErrorEvent(Data: PtrInt);
    procedure ChromiumKeyDownEvent(Data: PtrInt);
    procedure ChromiumConsoleMessage(Sender: TObject; const browser: ICefBrowser; level: TCefLogSeverity; const message, source: ustring; line: Integer; out Result: Boolean);
    procedure ChromiumBeforeContextMenu(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams; const model: ICefMenuModel);
  public
    Chromium: TChromium;
  end;

var
  Form1: TForm1;

procedure InitGlobalCEFApp;

implementation
uses
  LCLIntf, variants, LCLType, LazFileUtils,
  uCEFConstants, uCEFApplication, uCEFResourceHandler,
  uCEFMiscFunctions,
  unit_js, unit_global, unit_thread, unit_rest;

{$R *.lfm}

type

  { TThreadWakeupCef }

  TThreadWakeupCef = class(TThread)
  private
    wakeup: boolean;
    procedure Check1;
    procedure Check2;
  protected
    procedure Execute; override;
  public
    constructor Create; overload;
    destructor Destroy; override;
  end;

  { TThreadShutdownCef }

  TThreadShutdownCef = class(TThread)
  private
    canClose: boolean;
    procedure Check;
  protected
    procedure Execute; override;
  public
    constructor Create; overload;
    destructor Destroy; override;
  end;

var
  ThreadWakeupCef: TThreadWakeupCef;
  ThreadShutdownCef: TThreadShutdownCef;


procedure InitGlobalCEFApp;
begin
  execPath:= ExtractFilePath(ParamStr(0));
  //GlobalCEFApp.FrameworkDirPath:= UTF8Decode(execPath + 'Release');
  //GlobalCEFApp.ResourcesDirPath:= UTF8Decode(execPath + 'Resources');
  //GlobalCEFApp.LocalesDirPath:= GlobalCEFApp.ResourcesDirPath + '/locales';

  GlobalCEFApp.OnWebKitInitialized := @WebKitInitializedEvent;
  GlobalCEFApp.OnContextCreated:= @ContextCreatedEvent;
  GlobalCEFApp.OnContextReleased:= @ContextReleasedEvent;
  GlobalCEFApp.OnProcessMessageReceived:= @ProcessMessageReceivedEvent;

{$IFDEF CEF_SINGLE_PROCESS}
  GlobalCEFAPP.SingleProcess:= True;
{$ENDIF}

  GlobalCEFApp.cache:= 'cache';
  GlobalCEFApp.LogFile:= 'debug.log';
  GlobalCEFApp.LogSeverity:= LOGSEVERITY_INFO;
  GlobalCEFApp.EnablePrintPreview:= True;
  GlobalCEFApp.DisableWebSecurity:= True;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
const
  dogrootDefault = 'dogroot';
  restrootDefault = '~rest';
var
  s, s1: string;
  i: integer;
  sl: TStringList;
begin
  Caption:= '';

  sl:= TStringList.Create;
  try
    try
      sl.LoadFromFile(ChangeFileExt(ParamStr(0), '.cfg'));

      s:= dogrootDefault;
      i:= sl.IndexOfName('dogroot');
      if i >= 0 then sl.GetNameValue(i, s1, s);
      dogroot:= IncludeTrailingPathDelimiter(CreateAbsolutePath(s, execPath));

      restroot:= restrootDefault;
      i:= sl.IndexOfName('restroot');
      if i >= 0 then sl.GetNameValue(i, s1, restroot);

      s:= GetDefaultCEFUserAgent;
      i:= sl.IndexOfName('UserAgent');
      if i >= 0 then sl.GetNameValue(i, s1, s);
      GlobalCEFApp.UserAgent:= UTF8Decode(s);
    except
      dogroot:= IncludeTrailingPathDelimiter(CreateAbsolutePath(dogrootDefault, execPath));
      s:= GetDefaultCEFUserAgent;
      GlobalCEFApp.UserAgent:= UTF8Decode(s);
    end;
  finally
    sl.Free;
  end;

  CEFWindowParent:= TCEFWindowParent.Create(Self);
  CEFWindowParent.Parent:= Self;
  CEFWindowParent.Align:= alClient;

  Chromium:= TChromium.Create(Self);
  Chromium.DefaultUrl:= 'http://0.0.0.0/index.html';
  Chromium.MultiBrowserMode := false;
  Chromium.WebRTCIPHandlingPolicy:= hpDisableNonProxiedUDP;
  Chromium.WebRTCMultipleRoutes:= STATE_DISABLED;
  Chromium.WebRTCNonproxiedUDP:= STATE_DISABLED;
  Chromium.OnAfterCreated:= @ChromiumAfterCreated;
  Chromium.OnClose:= @ChromiumClose;
  Chromium.OnBeforeClose:= @ChromiumBeforeClose;
  Chromium.OnLoadStart:= @ChromiumLoadStart;
  Chromium.OnLoadEnd:= @ChromiumLoadEnd;
  Chromium.OnLoadError:= @ChromiumLoadError;
  Chromium.OnPreKeyEvent:= @ChromiumPreKeyEvent;
  Chromium.OnKeyEvent:= @ChromiumKeyEvent;
  Chromium.OnBeforeBrowse:= @ChromiumBeforeBrowse;
  Chromium.OnProcessMessageReceived:= @ChromiumProcessMessageReceived;
  Chromium.OnGetResourceHandler:= @ChromiumGetResourceHandler;
  //Chromium.OnGetResourceRequestHandler_ReqHdlr:= @ChromiumGetResourceRequestHandler;
  Chromium.OnConsoleMessage:= @ChromiumConsoleMessage;
  Chromium.OnBeforeContextMenu:= @ChromiumBeforeContextMenu;

  InformationPanel:= TPanel.Create(Self);
  InformationPanel.Parent:= Self;
  InformationPanel.Align:= alClient;
  InformationPanel.Color:= clBlack;
  InformationPanel.BevelInner:= bvNone;
  InformationPanel.BevelOuter:= bvNone;
  InformationPanel.Hide;

  InformationText:= TStaticText.Create(Self);
  InformationText.Parent:= InformationPanel;
  InformationText.Align:= alClient;
  InformationText.BorderSpacing.Around:= 32;
  InformationText.Font.Size:= 14;
  InformationText.Color:= clBlack;
  InformationText.Font.Color:= clLime;

  Self.DoubleBuffered:= False;

  ThreadWakeupCef:= TThreadWakeupCef.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  ThreadWakeupCef.Free;
  ThreadShutdownCef.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Application.QueueAsyncCall(@FormShowEvent, 0);
end;

procedure TForm1.FormShowEvent(Data: PtrInt);
begin
  //
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FCanClose:= False;
  ThreadShutdownCef:= TThreadShutdownCef.Create;
  Form1.Chromium.CloseAllBrowsers;
end;

procedure TForm1.ChromiumAfterCreated(Sender: TObject;
  const browser: ICefBrowser);
begin
  Application.QueueAsyncCall(@BrowserCreated, 0);
end;

procedure TForm1.BrowserCreated(Data: PtrInt);
begin
  CEFWindowParent.UpdateSize;
  FreeAndNil(ThreadWakeupCef);
end;

procedure TForm1.ChromiumBeforeClose(Sender: TObject; const browser: ICefBrowser
  );
begin
  // The main browser is being destroyed
  FCanClose := Chromium.BrowserId = 0;
end;

procedure TForm1.ChromiumClose(Sender: TObject; const browser: ICefBrowser;
  var aAction: TCefCloseBrowserAction);
begin
  if (browser <> nil) and
     (Chromium.BrowserId = browser.Identifier) and
     (CEFWindowParent <> nil) then begin
    Application.QueueAsyncCall(@BrowserDestroy, 0);
    aAction := cbaDelay;
  end;
end;

procedure TForm1.BrowserDestroy(Data: PtrInt);
begin
  FreeAndNil(CEFWindowParent);
end;

procedure TForm1.ChromiumLoadStart(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; transitionType: TCefTransitionType);
begin
  InformationPanel.Hide;
end;

procedure TForm1.ChromiumLoadEnd(Sender: TObject; const Browser: ICefBrowser;
  const Frame: ICefFrame; httpStatusCode: Integer);
begin
  if (Frame = nil) or not Frame.IsValid then Exit;
  if Frame.IsMain then begin
    Application.QueueAsyncCall(@ChromiumLoadEndEvent, 0);
  end;
end;

procedure TForm1.ChromiumLoadEndEvent(Data: PtrInt);
begin
  //
end;

type
  TChromiumLoadErrorData = class
    errorText, failedUrl: string;
    errorCode: TCefErrorCode;
  end;

procedure TForm1.ChromiumLoadError(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; errorCode: TCefErrorCode; const errorText,
  failedUrl: ustring);
var
  data: TChromiumLoadErrorData;
begin
  if (errorCode = ERR_ABORTED) then Exit;
  data:= TChromiumLoadErrorData.Create;
  data.errorText:= UTF8Encode(errorText);
  data.failedUrl:= UTF8Encode(failedUrl);
  data.errorCode:= errorCode;
  Application.QueueAsyncCall(@ChromiumLoadErrorEvent, PtrInt(data));
end;

procedure TForm1.ChromiumLoadErrorEvent(Data: PtrInt);
var
  s: string;
begin
  Chromium.GoBack;

  s:= UTF8Encode(IntToStr(TChromiumLoadErrorData(data).errorCode) + #$0d +
   TChromiumLoadErrorData(data).errorText + #$0d#$0d +
   TChromiumLoadErrorData(data).failedUrl);
  TChromiumLoadErrorData(data).Free;
  Application.MessageBox(PChar(s), nil);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  kev: TCefKeyEvent;
begin
  case Key of
    VK_BACK, VK_F5, VK_F12: begin
      kev.windows_key_code:= Key;
      kev.native_key_code:= Key;
      kev.focus_on_editable_field:= 0;
      kev.is_system_key:= 1;
      kev.kind:= KEYEVENT_KEYDOWN;
      Chromium.SetFocus(True);
      Chromium.SendKeyEvent(@kev);
      //Application.QueueAsyncCall(@ChromiumKeyDownEvent, Key);
    end;
    else Exit;
  end;
  Key:= 0;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
//var
//  kev: TCefKeyEvent;
begin
  //case Key of
  //  VK_BACK, VK_F5, VK_F12: begin
  //    kev.windows_key_code:= Key;
  //    kev.focus_on_editable_field:= 1;
  //    kev.is_system_key:= 0;
  //    kev.kind:= KEYEVENT_KEYUP;
  //    Chromium.Browser.GetHost.SendKeyEvent(@kev);
  //    //Application.QueueAsyncCall(@ChromiumKeyDownEvent, Key);
  //  end;
  //  else Exit;
  //end;
  //Key:= 0;
end;

procedure TForm1.ChromiumPreKeyEvent(Sender: TObject;
  const browser: ICefBrowser; const event: PCefKeyEvent; osEvent: TCefEventHandle;
  out isKeyboardShortcut: Boolean; out Result: Boolean);

begin
  Result:= False;
  isKeyboardShortcut:= (event <> nil) and
   (event^.kind in [KEYEVENT_RAWKEYDOWN, KEYEVENT_KEYDOWN, KEYEVENT_KEYUP]) and
   ((event^.windows_key_code = VK_BACK) or
    (event^.windows_key_code = VK_F5) or (event^.windows_key_code = VK_F12));
end;

procedure TForm1.ChromiumKeyEvent(Sender: TObject; const browser: ICefBrowser;
  const event: PCefKeyEvent; osEvent: TCefEventHandle; out Result: Boolean);
begin
  Result := False;
  if not Assigned(event) then Exit;
  case event^.kind of
    KEYEVENT_KEYUP: begin
      case event^.windows_key_code of
        VK_BACK, VK_F5, VK_F12: begin
          Result:= True;
        end;
      end;
    end;
    KEYEVENT_RAWKEYDOWN, KEYEVENT_KEYDOWN: begin
      case event^.windows_key_code of
        VK_BACK, VK_F5, VK_F12: begin
          Application.QueueAsyncCall(@ChromiumKeyDownEvent, event^.windows_key_code);
          Result:= True;
        end;
      end;
    end;
  end;
end;

procedure TForm1.ChromiumKeyDownEvent(Data: PtrInt);
begin
  case Data of
    VK_BACK: Chromium.GoBack;
    VK_F5: Chromium.ReloadIgnoreCache;
    VK_F12: Chromium.showDevTools(Point(0, 0));
  end;
end;

procedure TForm1.ChromiumBeforeBrowse(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const request: ICefRequest; user_gesture, isRedirect: Boolean; out Result: Boolean);
begin
  Result:= False;
  case request.TransitionType of
    TT_LINK: begin
      if Pos('http://0.0.0.0/', request.Url) = 1 then Exit;
      OpenURL(UTF8Encode(request.Url));
    end else
      Exit;
  end;
  Result:= True;
end;

procedure TForm1.ChromiumProcessMessageReceived(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  sourceProcess: TCefProcessId; const message: ICefProcessMessage; out
  Result: Boolean);

  //
  procedure context_created;
  var
    argv: string;
    us: ustring;
    i: integer;
  begin
    argv:= '[';
    for i:= 0 to ParamCount do begin
      argv:= argv + StringPasToJS2(ParamStr(i)) + ',';
    end;
    argv:= argv + ']';

    us:= UTF8Decode(''
     + '{'
     + 'const v=window.' + G_VAR_IN_JS_NAME + '={};'
     + 'v._ipc={};'
     + 'window.__dogroot = ' + StringPasToJS(dogroot) + ';'
     + 'window.__restroot = ' + StringPasToJS(restroot) + ';'
     + 'window.__execPath = ' + StringPasToJS(execPath) + ';'
     + 'window.__argv = ' + argv + ';'
     + '}'
    );
    Chromium.ExecuteJavaScript(us, 'about:blank');
  end;

  //
  procedure promise_thread_start;
  var
    params: ICefListValue;
    thread: TPromiseThread;
    i: integer;
  begin
    params:= message.ArgumentList;
    i:= ThreadClassList.IndexOf(UTF8Encode(params.GetString(1)));
    if i < 0 then
      raise SysUtils.Exception.Create(UTF8Encode('You forgot to add "' + params.GetString(1) + '" thread to ThreadClassList.'));
    thread:= TPromiseThreadClass(ThreadClassList.Objects[i]).Create();
    thread.UID:= UTF8Encode(params.GetString(0));
    thread.Frame:= frame;
    thread.Args:= params.GetList(2).Copy;
    thread.CefObject:= params.GetValue(3).Copy;
    thread.CefLocal:= params.GetValue(4).Copy;
    ThreadList.AddObject(thread.UID, thread);
    thread.Start;
  end;

//
begin
  Result:= False;
  case message.name of
    'context_created': context_created;
    'promise_thread_start': promise_thread_start;
  end;
  Result:= True;
end;

procedure TForm1.ChromiumConsoleMessage(Sender: TObject; const browser: ICefBrowser;
  level: TCefLogSeverity; const message, source: ustring; line: Integer; out
  Result: Boolean);
var
  s: string;
begin
  if level = LOGSEVERITY_ERROR then begin
    s:= Format('%s'#$0d'file: %s'#$0d'line: %d',
      [message, normalizeResourceName(UTF8Encode(source)), line]);
    InformationText.Caption:= s;
    InformationPanel.BringToFront;
    InformationPanel.Show;
    Self.Show;
  end;
end;

procedure TForm1.ChromiumBeforeContextMenu(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const params: ICefContextMenuParams; const model: ICefMenuModel);
begin
  model.Clear; // Disable the context menu
end;

type

  { TCustomResourceHandler }

  TCustomResourceHandler = class(TCefResourceHandlerOwn)
  private
    FStatus: integer;
    FStatusText: string;
    FFileName: string;
    FStream: TStream;
    isREST: boolean;
  protected
    function  open(const request: ICefRequest; var handle_request: boolean; const callback: ICefCallback): boolean; override;
    function  skip(bytes_to_skip: int64; var bytes_skipped: Int64; const callback: ICefResourceSkipCallback): boolean; override;
    function  read(const data_out: Pointer; bytes_to_read: Integer; var bytes_read: Integer; const callback: ICefResourceReadCallback): boolean; override;
    procedure GetResponseHeaders(const response: ICefResponse; out responseLength: Int64; out redirectUrl: ustring); override;
  public
    constructor Create(const browser: ICefBrowser; const frame: ICefFrame; const schemeName: ustring; const request: ICefRequest); reintroduce;
    destructor Destroy; override;
  end;

function TCustomResourceHandler.open(const request: ICefRequest;
  var handle_request: boolean; const callback: ICefCallback): boolean;
var
  body: string;
begin
  FFileName:= UTF8Encode(request.Url);
  FFileName:= normalizeResourceName(FFileName);

  if Pos(restroot + '/', FFileName) = 1 then begin
    isREST:= True;
    FFileName:= Copy(FFileName, 7, Length(FFileName));
    Result:= False;
    try
      body:= GetFromRestApi(FFileName, request, FStatus, FStatusText);
      if (FStatus >= 200) and (FStatus <= 299) then begin
        FStream:= TStringStream.Create(body);
        if Assigned(callback) then callback.Cont;
        Result:= True;
      end;
    except
      FStatus:= 404; // HTTP_NOTFOUND
      FStatusText:= 'Not Found';
    end;
    Exit;
  end;

  FFileName:= CreateAbsolutePath(FFileName, dogRoot);
  Result:= False;
  try
    FStream:= TFileStream.Create(FFileName, fmOpenRead);
    if Assigned(callback) then callback.Cont;
    Result:= True;
  except
    FStatus:= 404; // HTTP_NOTFOUND
    FStatusText:= 'Not Found';
  end;
end;

function TCustomResourceHandler.skip(bytes_to_skip: int64;
  var bytes_skipped: Int64; const callback: ICefResourceSkipCallback): boolean;
begin
  Result:= False;
  try
    bytes_skipped:= FStream.Seek(bytes_to_skip, soBeginning);
    if Assigned(callback) then callback.Cont(bytes_skipped);
    Result:= True;
  except
  end;
end;

function TCustomResourceHandler.read(const data_out: Pointer;
  bytes_to_read: Integer; var bytes_read: Integer;
  const callback: ICefResourceReadCallback): boolean;
begin
  Result:= False;
  try
    bytes_read:= FStream.Read(data_out^, bytes_to_read);
    if Assigned(callback) then callback.Cont(bytes_read);
    Result:= True;
  except
  end;
end;

procedure TCustomResourceHandler.GetResponseHeaders(
  const response: ICefResponse; out responseLength: Int64; out
  redirectUrl: ustring);
var
  ext: string;
begin
  if (response <> nil) then begin
    response.Status:= FStatus;
    response.StatusText:= UTF8Decode(FStatusText);

    if isREST then begin
      response.MimeType:= 'application/json';
    end else begin
      ext:= ExtractFileExt(FFileName);
      if ext = '' then ext:= '.html';
      Delete(ext, 1, 1);
      response.MimeType:= CefGetMimeType(UTF8Decode(ext));
    end;
  end;

  responseLength:= FStream.Size;
end;

constructor TCustomResourceHandler.Create(const browser: ICefBrowser;
  const frame: ICefFrame; const schemeName: ustring; const request: ICefRequest);
begin
  FStatus:= 200;
  FStatusText:= 'OK';
  inherited Create(browser, frame, schemeName, request);
end;

destructor TCustomResourceHandler.Destroy;
begin
  if Assigned(FStream) then FStream.Free;
  inherited Destroy;
end;

procedure TForm1.ChromiumGetResourceHandler(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const request: ICefRequest; var Result: ICefResourceHandler);
begin
  if (Pos('://', request.Url) > 0) and (Pos('http://0.0.0.0/', request.Url) = 0) then Exit;
  Result:= TCustomResourceHandler.Create(browser, frame, '', request);
end;

procedure TForm1.ChromiumGetResourceRequestHandler(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const request: ICefRequest; is_navigation, is_download: boolean;
  const request_initiator: ustring; var disable_default_handling: boolean;
  var aExternalResourceRequestHandler: ICefResourceRequestHandler);
begin
  //disable_default_handling:= True;
end;

{ TThreadWakeupCef }

constructor TThreadWakeupCef.Create;
begin
  FreeOnTerminate:= False;
  inherited Create(False);
end;

destructor TThreadWakeupCef.Destroy;
begin
  inherited Destroy;
end;

procedure TThreadWakeupCef.Check1;
begin
  wakeup:= Form1.Chromium.CreateBrowser(Form1.CEFWindowParent, '');
end;

procedure TThreadWakeupCef.Check2;
begin
  wakeup:= Form1.Chromium.Initialized;
end;

procedure TThreadWakeupCef.Execute;
begin
  wakeup:= false;
  Synchronize(@Check1);
  while not wakeup and not Terminated do begin
    sleep(100);
    Synchronize(@Check1);
    if wakeup then Synchronize(@Check2);
  end;
end;

{ TThreadShutdownCef }

constructor TThreadShutdownCef.Create;
begin
  FreeOnTerminate:= False;
  inherited Create(False);
end;

destructor TThreadShutdownCef.Destroy;
begin
  inherited Destroy;
end;

procedure TThreadShutdownCef.Check;
begin
  canClose := Form1.FCanClose;
end;

procedure TThreadShutdownCef.Execute;
begin
  canClose:= false;
  while not canClose do Synchronize(@Check);
end;

end.

