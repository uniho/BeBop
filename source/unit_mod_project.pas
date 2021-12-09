unit unit_mod_project;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, unit_js,
  uCEFTypes, uCEFInterfaces;

function CreateRequest(const fileName: string): ICefRequest;

implementation

uses
  Forms, unit1, LazFileUtils, unit_global, unit_thread,
  uCEFConstants, uCEFv8Context, uCEFv8Value,
  uCEFv8Accessor, uCEFRequest, uCEFPostData, uCEFPostDataElement, uCEFValue;

const
  MODULE_NAME = PROJECT_NAME; //////////

type

  { TV8AccessorScreen }

  TV8AccessorScreen = class(TCefV8AccessorOwn)
  protected
    function Get(const name: ustring; const object_: ICefv8Value; var retval : ICefv8Value; var exception: ustring): Boolean; override;
    function Set_(const name: ustring; const object_, value: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TV8AccessorMainform }

  TV8AccessorMainform = class(TCefV8AccessorOwn)
  protected
    function Get(const name: ustring; const object_: ICefv8Value; var retval : ICefv8Value; var exception: ustring): Boolean; override;
    function Set_(const name: ustring; const object_, value: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TRequireThread }

  TRequireThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  v1, v2, g, gvar: ICefv8Value;
  handler: ICefv8Handler;
  acr: ICefV8Accessor;
begin
  Result:= False;
  g:= TCefv8ContextRef.Current.GetGlobal;
  gvar:= g.GetValueByKey(G_VAR_IN_JS_NAME);
  if not gvar.HasValueByKey(PROJECT_NAME) then begin
    v2:= TCefv8ValueRef.NewObject(nil, nil);

    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'app.showMessage');
    v1:= TCefv8ValueRef.NewObject(nil, nil);
    v1.SetValueByKey('showMessage',
     TCefv8ValueRef.NewFunction('showMessage', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'app.terminate');
    v1.SetValueByKey('terminate',
     TCefv8ValueRef.NewFunction('terminate', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    v2.SetValueByKey('app', v1, V8_PROPERTY_ATTRIBUTE_NONE);

    acr:= TV8AccessorScreen.Create;
    v1:= TCefv8ValueRef.NewObject(acr, nil);
    v1.SetValueByAccessor('workAreaWidth', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('workAreaHeight', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v2.SetValueByKey('screen', v1, V8_PROPERTY_ATTRIBUTE_NONE);

    acr:= TV8AccessorMainform.Create;
    v1:= TCefv8ValueRef.NewObject(acr, nil);
    v1.SetValueByAccessor('left', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('top', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('width', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('height', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('caption', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('visible', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    v1.SetValueByAccessor('set', V8_ACCESS_CONTROL_DEFAULT, V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'mainform.show');
    v1.SetValueByKey('show',
     TCefv8ValueRef.NewFunction('show', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'mainform.hide');
    v1.SetValueByKey('hide',
     TCefv8ValueRef.NewFunction('hide', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'mainform.close');
    v1.SetValueByKey('close',
     TCefv8ValueRef.NewFunction('close', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    v2.SetValueByKey('mainform', v1, V8_PROPERTY_ATTRIBUTE_NONE);

    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'browser.reload');
    v1:= TCefv8ValueRef.NewObject(nil, nil);
    v1.SetValueByKey('reload',
     TCefv8ValueRef.NewFunction('reload', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'browser.showDevTools');
    v1.SetValueByKey('showDevTools',
     TCefv8ValueRef.NewFunction('showDevTools', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'browser.loadURL');
    v1.SetValueByKey('loadURL',
     TCefv8ValueRef.NewFunction('loadURL', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'browser.goBack');
    v1.SetValueByKey('goBack',
     TCefv8ValueRef.NewFunction('goBack', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'browser.goForward');
    v1.SetValueByKey('goForward',
     TCefv8ValueRef.NewFunction('goForward', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    v2.SetValueByKey('browser', v1, V8_PROPERTY_ATTRIBUTE_NONE);

    gvar.SetValueByKey(PROJECT_NAME, v2, V8_PROPERTY_ATTRIBUTE_NONE);
  end;

  retval:= gvar.GetValueByKey(PROJECT_NAME);

  Result:= True;
end;


//
function requireExecute(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  v1, g: ICefv8Value;
  uuid: string;
begin
  // (resolve, reject) => {...}

  Result:= requireCreate(name, obj, arguments, retval, exception);
  if not Result or (exception <> '') then Exit;

  uuid:= StartPromiseThread(TRequireThread,
    [], arguments[0], arguments[1], MODULE_NAME, 'require');
  g:= TCefv8ContextRef.Current.GetGlobal;
  v1:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc').GetValueByKey(UTF8Decode(uuid));
  v1.SetValueByKey('resolve_args', retval, V8_PROPERTY_ATTRIBUTE_NONE);

  retval:= TCefv8ValueRef.NewNull;

  Result:= True;
end;

{ TRequireThread }

procedure TRequireThread.ExecuteAct;
begin
  // Nothing to do
  CefResolve:= TCefValueRef.New;
end;


type

  { TV8HandlerCallback }

  TV8HandlerCallback = class(TV8HandlerSafe)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TAppShowMessageThread }

  TAppShowMessageThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TAppTerminateThread }

  TAppTerminateThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TBrowserReloadThread }

  TBrowserReloadThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TBrowsershowDevToolsThread }

  TBrowsershowDevToolsThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TBrowserLoadURLThread }

  TBrowserLoadURLThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TBrowserGoBackThread }

  TBrowserGoBackThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TBrowserGoForwardThread }

  TBrowserGoForwardThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TScreenGetWorkAreaWidthThread }

  TScreenGetWorkAreaWidthThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TScreenGetWorkAreaHeightThread }

  TScreenGetWorkAreaHeightThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetLeftThread }

  TMainformGetLeftThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetTopThread }

  TMainformGetTopThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetWidthThread }

  TMainformGetWidthThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetHeightThread }

  TMainformGetHeightThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetCaptionThread }

  TMainformGetCaptionThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformGetVisibleThread }

  TMainformGetVisibleThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetLeftThread }

  TMainformSetLeftThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetTopThread }

  TMainformSetTopThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetWidthThread }

  TMainformSetWidthThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetHeightThread }

  TMainformSetHeightThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetCaptionThread }

  TMainformSetCaptionThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformSetVisibleThread }

  TMainformSetVisibleThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformShowThread }

  TMainformShowThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

  { TMainformHideThread }

  TMainformHideThread = class(TPromiseThread)
  private
    procedure doUnSafe;
  protected
    procedure ExecuteAct; override;
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
  case handler.FuncName of
    'app.showMessage',
    'app.terminate',
    'browser.reload',
    'browser.showDevTools',
    'browser.loadURL',
    'browser.goBack',
    'browser.goForward',
    'screen.workAreaWidth',
    'screen.workAreaHeight',
    'mainform.left',
    'mainform.top',
    'mainform.width',
    'mainform.height',
    'mainform.caption',
    'mainform.visible',
    'mainform.set.left',
    'mainform.set.top',
    'mainform.set.width',
    'mainform.set.height',
    'mainform.set.caption',
    'mainform.set.visible',
    'mainform.show',
    'mainform.hide',
    'mainform.close': begin
      // res = (arg, ...) => new Promise(resolve => {...})
      retval:= NewV8Promise(name,
       TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
    end;

    else
      Exit;
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
    'app.showMessage': begin
      StartPromiseThread(TAppShowMessageThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'app.terminate', 'mainform.close': begin
      StartPromiseThread(TAppTerminateThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'browser.reload': begin
      StartPromiseThread(TBrowserReloadThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'browser.showDevTools': begin
      StartPromiseThread(TBrowserShowDevToolsThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'browser.loadURL': begin
      StartPromiseThread(TBrowserLoadURLThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'browser.goBack': begin
      StartPromiseThread(TBrowserGoBackThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'browser.goForward': begin
      StartPromiseThread(TBrowserGoBackThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'screen.workAreaWidth': begin
      StartPromiseThread(TScreenGetWorkAreaWidthThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'screen.workAreaHeight': begin
      StartPromiseThread(TScreenGetWorkAreaHeightThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.left': begin
      StartPromiseThread(TMainFormGetLeftThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.top': begin
      StartPromiseThread(TMainFormGetTopThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.width': begin
      StartPromiseThread(TMainFormGetWidthThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.height': begin
      StartPromiseThread(TMainFormGetHeightThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.caption': begin
      StartPromiseThread(TMainFormGetCaptionThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.visible': begin
      StartPromiseThread(TMainFormGetVisibleThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.left': begin
      StartPromiseThread(TMainFormSetLeftThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.top': begin
      StartPromiseThread(TMainFormSetTopThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.width': begin
      StartPromiseThread(TMainFormSetWidthThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.height': begin
      StartPromiseThread(TMainFormSetHeightThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.caption': begin
      StartPromiseThread(TMainFormSetCaptionThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.set.visible': begin
      StartPromiseThread(TMainFormSetVisibleThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.show': begin
      StartPromiseThread(TMainFormShowThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mainform.hide': begin
      StartPromiseThread(TMainFormHideThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;

{ TAppShowMessageThread }

procedure TAppShowMessageThread.doUnSafe;
var
  s: String;
begin
  s:= '';
  if Args.GetSize > 0 then s:= UTF8Encode(Args.GetString(0));
  Application.MessageBox(PChar(s), PChar(PROJECT_NAME));
  Form1.Chromium.SetFocus(True);
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TAppShowMessageThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TAppTerminateThread }

procedure TAppTerminateThread.doUnSafe;
begin
  Form1.Close;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TAppTerminateThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TBrowsershowDevToolsThread }

procedure TBrowsershowDevToolsThread.doUnSafe;
begin
  Form1.Chromium.ShowDevTools(Point(0, 0));
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TBrowsershowDevToolsThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TBrowserReloadThread }

procedure TBrowserReloadThread.doUnSafe;
begin
  Form1.Chromium.ReloadIgnoreCache;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TBrowserReloadThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TBrowserLoadURLThread }

procedure TBrowserLoadURLThread.doUnSafe;
var
  s: String;
begin
  if Args.GetSize > 0 then begin
    s:= UTF8Encode(Args.GetString(0));
    Form1.Chromium.LoadURL(UTF8Decode('http://0.0.0.0/' + s));
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TBrowserLoadURLThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TBrowserGoBackThread }

procedure TBrowserGoBackThread.doUnSafe;
begin
  Form1.Chromium.GoBack;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TBrowserGoBackThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TBrowserGoForwardThread }

procedure TBrowserGoForwardThread.doUnSafe;
begin
  Form1.Chromium.GoForward;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TBrowserGoForwardThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformShowThread }

procedure TMainformShowThread.doUnSafe;
begin
  Form1.Show;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TMainformShowThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformHideThread }

procedure TMainformHideThread.doUnSafe;
begin
  Form1.Hide;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;

procedure TMainformHideThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;


{ TV8AccessorScreen }

function TV8AccessorScreen.Get(const name: ustring; const object_: ICefv8Value;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  func: ICefv8Value;
begin
  func:= TCefv8ValueRef.NewFunction(name, TV8HandlerSafe.Create(PROJECT_NAME, 'screen.' + UTF8Encode(name)));
  retval:= func.ExecuteFunction(nil, nil);
  Result:= True;
end;

function TV8AccessorScreen.Set_(const name: ustring; const object_,
  value: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
end;

{ TScreenGetworkAreaWidthThread }

procedure TScreenGetworkAreaWidthThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Screen.WorkAreaWidth);
end;

procedure TScreenGetworkAreaWidthThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TScreenGetworkAreaHeightThread }

procedure TScreenGetworkAreaHeightThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Screen.WorkAreaHeight);
end;

procedure TScreenGetworkAreaHeightThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;


{ TV8AccessorMainform }

function TV8AccessorMainform.Get(const name: ustring;
  const object_: ICefv8Value; var retval: ICefv8Value; var exception: ustring
  ): Boolean;
var
  v1, func: ICefv8Value;
  handler: ICefv8Handler;
begin
  case name of
    'set': begin
      retval:= TCefv8ValueRef.NewObject(nil, nil);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.left');
      retval.SetValueByKey('left',
       TCefv8ValueRef.NewFunction('left', handler), V8_PROPERTY_ATTRIBUTE_NONE);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.top');
      retval.SetValueByKey('top',
       TCefv8ValueRef.NewFunction('top', handler), V8_PROPERTY_ATTRIBUTE_NONE);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.width');
      retval.SetValueByKey('width',
       TCefv8ValueRef.NewFunction('width', handler), V8_PROPERTY_ATTRIBUTE_NONE);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.height');
      retval.SetValueByKey('height',
       TCefv8ValueRef.NewFunction('height', handler), V8_PROPERTY_ATTRIBUTE_NONE);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.caption');
      retval.SetValueByKey('caption',
       TCefv8ValueRef.NewFunction('caption', handler), V8_PROPERTY_ATTRIBUTE_NONE);
      handler:= TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.visible');
      retval.SetValueByKey('visible',
       TCefv8ValueRef.NewFunction('visible', handler), V8_PROPERTY_ATTRIBUTE_NONE);
    end;
    else begin
      func:= TCefv8ValueRef.NewFunction(name, TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.' + UTF8Encode(name)));
      retval:= func.ExecuteFunction(nil, nil);
    end;
  end;
  Result:= True;
end;

function TV8AccessorMainform.Set_(const name: ustring; const object_,
  value: ICefv8Value; var exception: ustring): Boolean;
var
  func: ICefv8Value;
begin
  // Setters cannot return a value so it is impossible to return the promise.
  // It means setters cannot wait finish this process.
  // Use "await xxx.set.yyy()" if you want to wait.
  func:= TCefv8ValueRef.NewFunction(name, TV8HandlerSafe.Create(PROJECT_NAME, 'mainform.set.' + UTF8Encode(name)));
  func.ExecuteFunction(nil, [value]);
  Result:= True;
end;

{ TMainformGetLeftThread }

procedure TMainformGetLeftThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Form1.Left);
end;

procedure TMainformGetLeftThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformGetTopThread }

procedure TMainformGetTopThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Form1.Top);
end;

procedure TMainformGetTopThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformGetWidthThread }

procedure TMainformGetWidthThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Form1.Width);
end;

procedure TMainformGetWidthThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformGetHeightThread }

procedure TMainformGetHeightThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(Form1.Height);
end;

procedure TMainformGetHeightThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformGetCaptionThread }

procedure TMainformGetCaptionThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetString(UTF8Decode(Form1.Caption));
end;

procedure TMainformGetCaptionThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformGetVisibleThread }

procedure TMainformGetVisibleThread.doUnSafe;
begin
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(Form1.Visible);
end;

procedure TMainformGetVisibleThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetLeftThread }

procedure TMainformSetLeftThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Left:= Args.GetInt(0);
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetLeftThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetTopThread }

procedure TMainformSetTopThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Top:= Args.GetInt(0);
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetTopThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetWidthThread }

procedure TMainformSetWidthThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Width:= Args.GetInt(0);
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetWidthThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetHeightThread }

procedure TMainformSetHeightThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Height:= Args.GetInt(0);
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetHeightThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetCaptionThread }

procedure TMainformSetCaptionThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Caption:= UTF8Encode(Args.GetString(0));
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetCaptionThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

{ TMainformSetVisibleThread }

procedure TMainformSetVisibleThread.doUnSafe;
begin
  if Args.GetSize > 0 then begin
    Form1.Visible:= Args.GetBool(0);
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

procedure TMainformSetVisibleThread.ExecuteAct;
begin
  Synchronize(@doUnSafe);
end;

// Maybe this function is unnecessary.
function CreateRequest(const fileName: string): ICefRequest;
var
  s: string;
  sl: TStringList;
  p: ICefPostData;
  e: ICefPostDataElement;
begin
  sl:= TStringList.Create;
  try
    sl.LoadFromFile(dogRoot+fileName);
    s:= sl.Text;
  finally
    sl.Free;
  end;
  Result:= TCefRequestRef.New;
  Result.Url:= UTF8Decode('http://0.0.0.0/' + fileName);
  p:= TCefPostDataRef.New;
  e:= TCefPostDataElementRef.New;
  e.SetToBytes(Length(s), PChar(s));
  p.AddElement(e);
  Result.PostData:= p;
end;

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread);
  AddPromiseThreadClass(MODULE_NAME, TAppShowMessageThread);
  AddPromiseThreadClass(MODULE_NAME, TAppTerminateThread);
  AddPromiseThreadClass(MODULE_NAME, TBrowserReloadThread);
  AddPromiseThreadClass(MODULE_NAME, TBrowserShowDevToolsThread);
  AddPromiseThreadClass(MODULE_NAME, TBrowserLoadURLThread);
  AddPromiseThreadClass(MODULE_NAME, TBrowserGoBackThread);
  AddPromiseThreadClass(MODULE_NAME, TBrowserGoForwardThread);
  AddPromiseThreadClass(MODULE_NAME, TScreenGetWorkAreaWidthThread);
  AddPromiseThreadClass(MODULE_NAME, TScreenGetWorkAreaHeightThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetLeftThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetTopThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetWidthThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetHeightThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetCaptionThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormGetVisibleThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetLeftThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetTopThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetWidthThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetHeightThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetCaptionThread);
  AddPromiseThreadClass(MODULE_NAME, TMainFormSetVisibleThread);
  AddPromiseThreadClass(MODULE_NAME, TMainformShowThread);
  AddPromiseThreadClass(MODULE_NAME, TMainformHideThread);
end.
