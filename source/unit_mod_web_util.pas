unit unit_mod_web_util;

{$mode ObjFPC}{$H+}
{$IF Defined(DARWIN)}
{$ModeSwitch objectivec1}
{$ENDIF}

interface

uses
  Classes, SysUtils;

implementation

uses
  {$IF DEFINED(Windows)}
  DwmApi,
  {$ENDIF}
  {$IF DEFINED(DARWIN)}
  CocoaAll,
  {$ENDIF}
  unit_js, unit_thread,
  uCEFTypes, uCEFInterfaces, unit_global, LazFileUtils, DateUtils, Forms,
  uCEFConstants, uCEFv8Value, uCEFValue, uCefDictionaryValue, uCefListValue,
  uCEFUrlRequestClientComponent, uCEFRequest, uCEFUrlRequest, uCefChromium,
  uCEFMiscFunctions, uCEFRequestContext;

const
  MODULE_NAME = 'web_util'; //////////

//
function importCreate(const name: string): ICefv8Value;
var
  handler: ICefv8Handler;
begin
  Result:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'downloadFile');
  Result.SetValueByKey('downloadFile',
   TCefv8ValueRef.NewFunction('downloadFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'scraping');
  Result.SetValueByKey('scraping',
   TCefv8ValueRef.NewFunction('scraping', handler), V8_PROPERTY_ATTRIBUTE_NONE);
end;

type
  { TV8HandlerCallback }

  TV8HandlerCallback = class(TV8HandlerSafe)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TDownloadFileThread }

  TDownloadFileThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TReadThread }

  TReadThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TCancelThread }

  TCancelThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TScrapingThread }

  TScrapingThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingGetSourceThread }

  TScrapingGetSourceThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingNewFunctionThread }

  TScrapingNewFunctionThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingWaitThread }

  TScrapingWaitThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingPrepareReloadThread }

  TScrapingPrepareReloadThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingCancelThread }

  TScrapingCancelThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TScrapingCloseThread }

  TScrapingCloseThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
  try
    case handler.FuncName of

     'scraping',
     'scraping.getSource',
     'scraping.newFunction',
     'scraping.wait',
     'scraping.prepareReload',
     'scraping.close',
     'scraping.cancel',
     'request.read',
     'request.cancel',
     'downloadFile': begin
        // res = (arg, ...) => new Promise((resolve, reject) => {...})
        retval:= NewV8Promise(name, TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
      end;

      else
        Exit;
    end;
  except
    on e: Exception do begin
      exception:= UTF8Decode(e.message);
    end;
  end;
  Result:= True;
end;

function TV8HandlerCallback.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  // (resolve, reject) => {...}
  Result:= False;
  case FuncName of
    'downloadFile': begin
      StartPromiseThread(TDownloadFileThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'request.read': begin
      StartPromiseThread(TReadThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'request.cancel': begin
      StartPromiseThread(TCancelThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping': begin
      StartPromiseThread(TScrapingThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.getSource': begin
      StartPromiseThread(TScrapingGetSourceThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.newFunction': begin
      StartPromiseThread(TScrapingNewFunctionThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.wait': begin
      StartPromiseThread(TScrapingWaitThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.prepareReload': begin
      StartPromiseThread(TScrapingPrepareReloadThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.close': begin
      StartPromiseThread(TScrapingCloseThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'scraping.cancel': begin
      StartPromiseThread(TScrapingCancelThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;

// downloadFile ////////////////////////////////////////////////////////////////

{ TRequestObject }

type
  TRequestObject = class(TObject)
  public
    obj: TCEFUrlRequestClientComponent;
    url: ustring;
    fileName, error: string;
    fileStream: TFileStream;
    curBytes, totalBytes: NativeUInt;
    cancel, canceled, complete, finished: boolean;
    procedure CreateURLRequestEvent(Sender: TObject);
    procedure RequestCompleteEvent(Sender: TObject; const request: ICefUrlRequest);
    procedure DownloadDataEvent(Sender: TObject; const request: ICefUrlRequest; data: Pointer; dataLength: NativeUInt);
    procedure DownloadProgressEvent(Sender: TObject; const request: ICefUrlRequest; current, total: Int64);
    constructor Create(aObj: TCEFUrlRequestClientComponent);
    destructor Destroy; override;
  end;

constructor TRequestObject.Create(aObj: TCEFUrlRequestClientComponent);
begin
  obj:= aObj;
  cancel:= false; canceled:= false;
  complete:= false;
  finished:= false;
  curBytes:= 0;
  totalBytes:= 0;
end;

destructor TRequestObject.Destroy;
begin
  if not finished then begin
    cancel:= true;
    Sleep(1000);
  end;
  if Assigned(fileStream) then fileStream.Free;
  FreeAndNil(obj);
  inherited Destroy;
end;

procedure TRequestObject.CreateURLRequestEvent(Sender: TObject);
var
  tempReq: ICefRequest;
begin
  tempReq:= TCefRequestRef.New;
  try
    tempReq.URL:= url;
    tempReq.Method:= 'GET';
    tempReq.Flags:= UR_FLAG_ALLOW_STORED_CREDENTIALS;
    TCefUrlRequestRef.New(tempReq, obj.Client, nil);
  finally
    tempReq:= nil;
  end;
end;

procedure TRequestObject.RequestCompleteEvent(Sender: TObject;
  const request: ICefUrlRequest);
begin
  if Assigned(fileStream) then FreeAndNil(fileStream);
  if request.RequestStatus = UR_SUCCESS then begin
    SysUtils.DeleteFile(fileName);
    if RenameFile(fileName + '.tmp', fileName) then complete:= true else error:= 'rename file error';
  end else begin
    SysUtils.DeleteFile(fileName + '.tmp');
  end;
  finished:= true;
end;

procedure TRequestObject.DownloadDataEvent(Sender: TObject;
  const request: ICefUrlRequest; data: Pointer; dataLength: NativeUInt);
begin
  if cancel or unit_global.appClosing then begin
    request.Cancel;
    canceled:= true;
    Exit;
  end;
  try
    if not Assigned(fileStream) then begin
      fileStream:= TFileStream.Create(fileName+'.tmp', fmCreate);
    end;
    fileStream.WriteBuffer(data^, dataLength);
  except
    on e:exception do begin
      request.Cancel;
      error:= e.Message;
    end;
  end;
end;

procedure TRequestObject.DownloadProgressEvent(Sender: TObject;
  const request: ICefUrlRequest; current, total: Int64);
begin
  curBytes:= current;
  totalBytes:= total;
  if cancel or unit_global.appClosing then begin
    request.Cancel;
    canceled:= true;
  end;
end;

{ TDownloadFileThread }

procedure TDownloadFileThread.ExecuteAct;
var
  reqObj: TRequestObject;
  req: TCEFUrlRequestClientComponent;
  option, dic, func: ICefDictionaryValue;
begin
  if Args.GetSize < 2 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);

  req:= TCEFUrlRequestClientComponent.Create(nil);
  //req.ThreadID:= TID_FILE_BACKGROUND; // ?
  //req.ThreadID:= TID_FILE_USER_VISIBLE; // ?
  req.ThreadID:= TID_FILE_USER_BLOCKING; // ?

  reqObj:= TRequestObject.Create(req);
  reqObj.url:= Args.GetString(0);
  reqObj.fileName:= UTF8Encode(Args.GetString(1));
  req.OnCreateURLRequest:= @reqObj.CreateURLRequestEvent;
  req.OnDownloadData:= @reqObj.DownloadDataEvent;
  req.OnRequestComplete:= @reqObj.RequestCompleteEvent;
  req.OnDownloadProgress:= @reqObj.DownloadProgressEvent;
  req.AddURLRequest;

  dic:= NewUserObject(reqObj);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'read');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'request.read');
  dic.SetDictionary('read', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'cancel');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'request.cancel');
  dic.SetDictionary('cancel', func);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetDictionary(dic);
end;

{ TReadThread }

procedure TReadThread.ExecuteAct;
var
  obj: TObject;
  req: TRequestObject;
  option, dic: ICefDictionaryValue;
  wait: integer;
  tickstart: TDateTime;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TRequestObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  req:= TRequestObject(obj);

  try
    option:= nil;
    wait:= 1000;
    if (Args.GetSize > 0) then begin
      option:= Args.GetDictionary(0);
      if option.HasKey('wait') then begin
        wait:= option.GetInt('wait');
      end;
    end;
    if wait < 100 then wait:= 100;

    tickstart:= Now;
    while not Self.Terminated and not req.finished do begin
      if MilliSecondsBetween(Now, tickstart) >= wait then break;
      Sleep(10);
    end;

  finally
    dic:= TCefDictionaryValueRef.New;
    dic.SetBool('complete', req.complete);
    dic.SetBool('canceled', req.canceled);
    dic.SetBool('finished', req.finished);
    dic.SetString('error', UTF8Decode(req.error));
    dic.SetDouble('curBytes', req.curBytes);
    dic.SetDouble('totalBytes', req.totalBytes);
    CefResolve:= TCefValueRef.New;
    CefResolve.SetDictionary(dic);
  end;
end;

procedure TCancelThread.ExecuteAct;
var
  obj: TObject;
  req: TRequestObject;
  dic: ICefDictionaryValue;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TRequestObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  req:= TRequestObject(obj);
  req.cancel:= true;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

// scraping ////////////////////////////////////////////////////////////////////

type

  { TBebopChromium }

  TBebopChromium = class(TChromium)
  private
  protected
  public
    function CreateSubBrowser(const url: ustring; showBrowser: boolean; bounds: Classes.TRect): boolean;
  end;

  { TScrapingObject }

  TScrapingObject = class
    crm: TBebopChromium;
    loaded, canceled, errorOccurred, canClose, gotSource: boolean;
    FSource, FErrorText: ustring;
    destructor Destroy; override;
    procedure ChromiumLoadStart(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; transitionType: TCefTransitionType);
    procedure ChromiumLoadEnd(Sender: TObject; const Browser: ICefBrowser;
     const Frame: ICefFrame; httpStatusCode: Integer);
    procedure ChromiumLoadError(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; errorCode: TCefErrorCode; const errorText, failedUrl: ustring);
    procedure ChromiumProcessMessageReceived(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId; const message: ICefProcessMessage; out Result: Boolean);
    procedure ChromiumTextResultAvailableEvent(Sender: TObject; const aText : ustring);
    procedure ChromiumConsoleMessage(Sender: TObject; const browser: ICefBrowser; level: TCefLogSeverity; const message, source: ustring; line: Integer; out Result: Boolean);
    procedure ChromiumBeforeClose(Sender: TObject; const browser: ICefBrowser);
  end;

{ TBebopChromium }

function TBebopChromium.CreateSubBrowser(const url: ustring; showBrowser: boolean; bounds: Classes.TRect): boolean;
var
  TempNewContext, TempOldContext: ICefRequestContext;
  r: Classes.TRect;
begin
  Result:= False;
  TempNewContext:= nil;
  try
    try
      GetSettings(FBrowserSettings);

      {$IF DEFINED(Windows)}
      CreateClientHandler(not showBrowser{isOSR});
      if showBrowser then begin
        WindowInfoAsPopUp(FWindowInfo, unit_global.MainForm.Handle);
        if (bounds.Width = 0) and (bounds.Height = 0) then begin
          DwmGetWindowAttribute(unit_global.MainForm.Handle, DWMWA_EXTENDED_FRAME_BOUNDS, @r, SizeOf(r));
          FWindowInfo.bounds.x:= r.Left + (r.Width - unit_global.MainForm.ClientWidth) div 2;
          FWindowInfo.bounds.y:= r.Top + (r.Height - unit_global.MainForm.ClientHeight) div 2;
          FWindowInfo.bounds.width:= unit_global.MainForm.ClientWidth;
          FWindowInfo.bounds.height:= unit_global.MainForm.ClientHeight;
        end else begin
          FWindowInfo.bounds.x:= bounds.Left;
          FWindowInfo.bounds.y:= bounds.Top;
          FWindowInfo.bounds.width:= bounds.Width;
          FWindowInfo.bounds.height:= bounds.Height;
        end;
      end else begin
        WindowInfoAsWindowless(FWindowInfo, unit_global.MainForm.Handle);
      end;
      {$ENDIF}

      {$IF DEFINED(Linux)}
      CreateClientHandler(not showBrowser{isOSR});
      if showBrowser then begin
        WindowInfoAsPopUp(FWindowInfo, TCefWindowHandle(0));
        if (bounds.Width = 0) and (bounds.Height = 0) then begin
          r:= unit_global.MainForm.BoundsRect;
          FWindowInfo.bounds.x:= r.Left;
          FWindowInfo.bounds.y:= r.Top;
          FWindowInfo.bounds.width:= r.Width;
          FWindowInfo.bounds.height:= r.Height;
        end else begin
          FWindowInfo.bounds.x:= bounds.Left;
          FWindowInfo.bounds.y:= bounds.Top;
          FWindowInfo.bounds.width:= bounds.Width;
          FWindowInfo.bounds.height:= bounds.Height;
        end;
      end else begin
        WindowInfoAsWindowless(FWindowInfo, unit_global.MainForm.Handle);
      end;
      {$ENDIF}

      {$IF DEFINED(Darwin)}
      // ToDo: Cannot show for now
      CreateClientHandler(true{isOSR});
      WindowInfoAsWindowless(FWindowInfo, TCefWindowHandle(0), '', true);

      //CreateClientHandler(not showBrowser{isOSR});
      //if showBrowser then begin
      //  if (bounds.Width = 0) and (bounds.Height = 0) then begin
      //    r:= unit_global.MainForm.BoundsRect;
      //  end else begin
      //    r:= bounds;
      //  end;
      //  WindowInfoAsChild(FWindowInfo, unit_global.MainForm.Handle, r, '', false);
      //end else begin
      //  WindowInfoAsWindowless(FWindowInfo, TCefWindowHandle(0), '', true);
      //end;
      {$ENDIF}

      CreateResourceRequestHandler;
      CreateMediaObserver;
      CreateDevToolsMsgObserver;
      CreateExtensionHandler;

      TempOldContext:= TCefRequestContextRef.Global();

      TempNewContext:= TCefRequestContextRef.Shared(TempOldContext, FReqContextHandler);

      //if GlobalCEFApp.MultiThreadedMessageLoop then begin
        Result:= CreateBrowserHost(@FWindowInfo, url, @FBrowserSettings, nil, TempNewContext)
      //end else begin
      //  Result:= CreateBrowserHostSync(@FWindowInfo, url, @FBrowserSettings, nil, TempNewContext);
      //end;

    except
      on e : exception do
        if CustomExceptionHandler('CreateSubBrowser', e) then raise;
    end;
  finally
    TempOldContext := nil;
    TempNewContext := nil;
  end;
end;

{ TScrapingObject }

destructor TScrapingObject.Destroy;
begin
  if Assigned(crm) then begin
    if Assigned(crm.Browser) then begin
      crm.Browser.Host.CloseBrowser(true);
      while not canClose do Sleep(10);
    end;
    crm.Free;
  end;
  inherited Destroy;
end;

procedure TScrapingObject.ChromiumLoadStart(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  transitionType: TCefTransitionType);
begin
  loaded:= false;
  errorOccurred:= false;
  gotSource:= false;
end;

procedure TScrapingObject.ChromiumLoadEnd(Sender: TObject;
  const Browser: ICefBrowser; const Frame: ICefFrame; httpStatusCode: Integer);
begin
  if (Frame = nil) or not Frame.IsValid or not Frame.IsMain then Exit;
  loaded:= true;
end;

procedure TScrapingObject.ChromiumLoadError(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; errorCode: TCefErrorCode;
  const errorText, failedUrl: ustring);
begin
  FErrorText:= 'Load Error ' +
   UTF8Decode(IntToStr(errorCode)) + ': ' +
   errorText + #$0d +
   failedUrl;
  errorOccurred:= true;
end;

procedure TScrapingObject.ChromiumProcessMessageReceived(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  sourceProcess: TCefProcessId; const message: ICefProcessMessage; out
  Result: Boolean);

  //
  procedure new_function_re;
  var
    obj: TObjectWithInterface;
  begin
    obj:= TObjectWithInterface.Create;
    obj.cefBaseRefCounted:= message.ArgumentList.GetValue(1);
    SetObjectList(UTF8Encode(message.ArgumentList.GetString(0)), obj);
  end;

//
begin
  Result:= False;
  case message.name of
    'new_function_re': new_function_re;
  end;
  Result:= True;
end;

procedure TScrapingObject.ChromiumTextResultAvailableEvent(Sender: TObject;
  const aText: ustring);
begin
  FSource:= aText;
  gotSource:= true;
end;

procedure TScrapingObject.ChromiumConsoleMessage(Sender: TObject;
  const browser: ICefBrowser; level: TCefLogSeverity; const message,
  source: ustring; line: Integer; out Result: Boolean);
begin
  if level = LOGSEVERITY_ERROR then begin
    FErrorText:= message;
    errorOccurred:= true;
  end;
end;

procedure TScrapingObject.ChromiumBeforeClose(Sender: TObject;
  const browser: ICefBrowser);
begin
  // The main browser is being destroyed
  canClose:= true;
end;

{ TScrapingThread }

procedure TScrapingThread.ExecuteAct;
var
  uobj: TScrapingObject;
  option, dic, func, bounds: ICefDictionaryValue;
  r: TRect;
  tickstart: TDateTime;
  timeout: integer;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);

  uobj:= TScrapingObject.Create;
  uobj.crm:= TBebopChromium.Create(nil);
  uobj.crm.DefaultUrl:= Args.GetString(0);
  uobj.crm.MultiBrowserMode:= false;
  uobj.crm.WebRTCIPHandlingPolicy:= hpDisableNonProxiedUDP;
  uobj.crm.WebRTCMultipleRoutes:= STATE_DISABLED;
  uobj.crm.WebRTCNonproxiedUDP:= STATE_DISABLED;
  uobj.crm.OnLoadStart:= @uobj.ChromiumLoadStart;
  uobj.crm.OnLoadEnd:= @uobj.ChromiumLoadEnd;
  uobj.crm.OnLoadError:= @uobj.ChromiumLoadError;
  uobj.crm.OnTextResultAvailable:= @uobj.ChromiumTextResultAvailableEvent;
  uobj.crm.OnProcessMessageReceived:= @uobj.ChromiumProcessMessageReceived;
  uobj.crm.OnConsoleMessage:= @uobj.ChromiumConsoleMessage;
  uobj.crm.OnBeforeClose:= @uobj.ChromiumBeforeClose;

  option:= nil;
  if (Args.GetSize > 1) then begin
    option:= Args.GetDictionary(1);
  end;

  bounds:= nil;
  r:= Classes.Rect(0, 0, 0, 0);
  if Assigned(option) then begin
    if option.HasKey('bounds') then begin
      bounds:= option.GetDictionary('bounds');
      if bounds.HasKey('left') then r.Left:= bounds.GetInt('left');
      if bounds.HasKey('top') then r.Top:= bounds.GetInt('top');
      if bounds.HasKey('right') then r.Right:= bounds.GetInt('right');
      if bounds.HasKey('bottom') then r.Bottom:= bounds.GetInt('bottom');
      if bounds.HasKey('width') then r.Width:= bounds.GetInt('width');
      if bounds.HasKey('height') then r.Height:= bounds.GetInt('height');
    end;
  end;

  tickstart:= Now;
  timeout:= 15 * 1000;
  while not Terminated and not unit_global.appClosing do begin
    if uobj.crm.CreateSubBrowser(Args.GetString(0), Assigned(bounds), r) then break;
    if MilliSecondsBetween(Now, tickstart) >= timeout then break;
    Sleep(100);
  end;

  dic:= NewUserObject(uobj);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'getSource');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.getSource');
  dic.SetDictionary('getSource', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'newFunction');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.newFunction');
  dic.SetDictionary('newFunction', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'wait');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.wait');
  dic.SetDictionary('wait', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'prepareReload');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.prepareReload');
  dic.SetDictionary('prepareReload', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'close');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.close');
  dic.SetDictionary('close', func);

  func:= TCefDictionaryValueRef.New;
  func.SetString(VTYPE_FUNCTION_NAME, 'cancel');
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'scraping.cancel');
  dic.SetDictionary('cancel', func);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetDictionary(dic);
end;

{ TScrapingGetSourceThread }

procedure TScrapingGetSourceThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
  tickstart: TDateTime;
  timeout: integer;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  uobj:= TScrapingObject(obj);
  if not Assigned(uobj.crm) then Raise Exception.Create('The browser was close.');
  if not Assigned(uobj.crm.Browser) then Raise Exception.Create('The browser was not created.');

  if not uobj.gotSource then begin
    uobj.crm.RetrieveHTML();
    tickstart:= Now;
    timeout:= 30 * 1000;
    while not uobj.gotSource and not uobj.canceled and
     not Terminated and not unit_global.appClosing do begin
      if MilliSecondsBetween(Now, tickstart) >= timeout then break;
      Sleep(10);
    end;
  end;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetString(uobj.FSource);
end;

{ TScrapingNewFunctionThread }

procedure TScrapingNewFunctionThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
  list: ICefListValue;
  i, len: integer;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);

  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  uobj:= TScrapingObject(obj);
  if not Assigned(uobj.crm) then Raise Exception.Create('The browser was close.');
  if not Assigned(uobj.crm.Browser) then Raise Exception.Create('The browser was not created.');

  uobj.errorOccurred:= false;

  list:= TCefListValueRef.New;
  len:= Args.GetSize;
  for i:= 1 to len-1 do list.SetValue(i-1, Args.GetValue(i));
  CefResolve:= newFunctionRe(UTF8Encode(Args.GetString(0)), list, '', true, uobj.crm);
end;

{ TScrapingWaitThread }

procedure TScrapingWaitThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
  tickstart: TDateTime;
  timeout: integer;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  timeout:= 30;
  if Args.GetSize >= 1 then begin
    timeout:= Args.GetInt(0);
    if timeout < 1 then timeout:= 0;
    if timeout > 10000 then timeout:= 10000;
  end;
  timeout:= timeout * 1000;

  uobj:= TScrapingObject(obj);
  tickstart:= Now;
  while true do begin
    if Self.Terminated or unit_global.appClosing or uobj.canceled or
      not Assigned(uobj.crm) or  not Assigned(uobj.crm.Browser) or  uobj.errorOccurred then break;
    if uobj.loaded and not uobj.crm.IsLoading then break;
    if MilliSecondsBetween(Now, tickstart) >= timeout then break;
    Sleep(10);
  end;

  dic:= TCefDictionaryValueRef.New;
  //dic.SetBool('complete', true);
  dic.SetBool('canceled', uobj.canceled);
  //dic.SetBool('finished', true);
  if uobj.errorOccurred then dic.SetString('error', uobj.FErrorText);
  CefResolve:= TCefValueRef.New;
  CefResolve.SetDictionary(dic);
end;

{ TScrapingPrepareReloadThread }

procedure TScrapingPrepareReloadThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  uobj:= TScrapingObject(obj);
  uobj.loaded:= false;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

{ TScrapingCancelThread }

procedure TScrapingCancelThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  uobj:= TScrapingObject(obj);
  uobj.canceled:= true;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

{ TScrapingCloseThread }

procedure TScrapingCloseThread.ExecuteAct;
var
  obj: TObject;
  uobj: TScrapingObject;
  dic: ICefDictionaryValue;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TScrapingObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  uobj:= TScrapingObject(obj);
  if Assigned(uobj.crm.Browser) then begin
    uobj.crm.Browser.Host.CloseBrowser(true);
  end;
  while not uobj.canClose do Sleep(10);
  FreeAndNil(uobj.crm);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["' + MODULE_NAME + '"]';
  _body = _import + '.__init__();' +
     'export const downloadFile=' + _import + '.downloadFile;' +
     'export const scraping=' + _import + '.scraping;' +
     '';

initialization
  {$IF Defined(WINDOWS)}
  InitDwmLibrary;
  {$ENDIF}

  // Regist module handler
  AddModuleHandler(MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TDownloadFileThread);
  AddPromiseThreadClass(MODULE_NAME, TReadThread);
  AddPromiseThreadClass(MODULE_NAME, TCancelThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingGetSourceThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingNewFunctionThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingWaitThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingPrepareReloadThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingCancelThread);
  AddPromiseThreadClass(MODULE_NAME, TScrapingCloseThread);
end.

