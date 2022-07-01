unit unit_js;

{.$DEFINE USE_LUA_MODULE}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uCEFInterfaces, uCEFTypes, uCEFv8Handler, uCEFValue, uCEFv8Value, uCEFChromiumCore;

type

  { TV8HandlerSafe }

  TV8HandlerSafe = class(TCefv8HandlerOwn)
  private
    FModuleName, FFuncName: string;
    FArgs: TCefv8ValueArray;
    FObject, FLocal: ICefv8Value;
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  public
    constructor Create(const aModuleName, aFuncName: string; const aArgs: TCefv8ValueArray = nil; aobj:ICefv8Value = nil; alocal:ICefv8Value = nil); overload;
    property ModuleName: string read FModuleName;
    property FuncName: string read FFuncName;
    property Args: TCefv8ValueArray read FArgs;
    property CefObject: ICefv8Value read FObject;
    property CefLocal: ICefv8Value read FLocal;
  end;

  TImportCreate = function(const name: string): ICefv8Value;

  // DEPRECATED
  TRequireFunction = function(const name: ustring; const obj: ICefv8Value;
    const arguments: TCefv8ValueArray; var retval: ICefv8Value;
    var exception: ustring): Boolean;

  TSafeExecute = function(const handler: TV8HandlerSafe; const name: ustring;
    const obj: ICefv8Value; const arguments: TCefv8ValueArray;
    var retval: ICefv8Value; var exception: ustring): Boolean;

  TModuleHandlers = class
  public
    requireCreate, requireExecute: TRequireFunction;
    safeExecute: TSafeExecute;
    creater: TImportCreate;
    body: string;
  end;

  { TTaskResult }

  TTaskResult = class(TObject)
  public
    result: TObject;
    CefResult: ICefValue;
    procedure callback(obj: TObject);
  end;

  { TObjectWithInterface }

  TObjectWithInterface = class
  public
    cefBaseRefCounted: ICefBaseRefCounted;
    destructor Destroy; override;
  end;

  { TCefValueExRef }

  TCefValueExRef = class(TCefValueRef)
  public
    destructor  Destroy; override;
  end;

var
  MainBrowserID: integer; // just for Renderer Process

procedure WebKitInitializedEvent;
procedure ContextCreatedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
procedure ContextReleasedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
procedure ProcessMessageReceivedEvent(const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId; const message: ICefProcessMessage; var aHandled : boolean);

procedure AddModuleHandler(const name: string; requireCreate, requireExecute: TRequireFunction; safeExecute: TSafeExecute);
procedure AddModuleHandler(const name, body: string; creater: TImportCreate; safeExecute: TSafeExecute);
function AddObjectList(const obj: TObject): string;
procedure AddObjectListUUID(const uuid: string; obj: TObject);
function GetObjectList(const uuid: string): TObject;
procedure SetObjectList(const uuid: string; obj: TObject);
procedure RemoveObjectList(const uuid: string);
procedure RemoveObjectListResult(const uuid: string; result: TTaskResult);
function StringPasToJS(const str: string): string;
function StringPasToJS2(const str: string): string;
function CefValueToCefv8Value(const cef: ICefValue): ICefv8Value;
function Cefv8ValueToCefValue(const v8: ICefv8Value; convFuncs: boolean = true): ICefValue;
function Cefv8ArrayToCefList(const v8: TCefv8ValueArray; convFuncs: boolean = true): ICefListValue;
function CopyCefValueEx(const src: ICefBaseRefCounted): ICefValue;
procedure CleanupIPCG;
procedure RemoveIPCG(const uid: string);
function NewV8Object(const parent: ICefv8Value; const args: TCefv8ValueArray): ICefv8Value;
function NewV8Promise(const name: ustring; const handler: ICefv8Handler): ICefv8Value;
procedure NewFunction(const code: string; const args: ICefListValue = nil; const uid: string = ''); // DEPRECATED
function NewFunctionRe(const code: string; const args: ICefListValue = nil; const uid: string = ''; return: boolean = true; const crm: TChromiumCore = nil): ICefValue;
function NewFunctionV8(const code: string; const args: TCefv8ValueArray): ICefv8Value;
function NewUserObject(const obj: TObject): ICefDictionaryValue;
function NewUserObjectV8(const obj: TObject): ICefv8Value;
procedure showWarning(const msg: string);
procedure showWarningUI(const msg: string);

procedure FreeMemProc(buffer: Pointer);

implementation
uses
  // List of Modules
  unit_mod_fs, unit_mod_util, unit_mod_path, unit_mod_process, unit_mod_child_process,
  unit_mod_project, unit_mod_web_util,
  {$IFDEF USE_LUA_MODULE}
  unit_mod_lua,
  {$ENDIF}

  unit_global,
  Forms, TypInfo, DateUtils,
  uCEFConstants, uCEFListValue, uCEFv8Context, uCEFProcessMessage,
  uCefDictionaryValue, uCefBinaryValue, uCEFTask, uCEFMiscFunctions,
  uCefv8ArrayBufferReleaseCallback;

type

  { TV8HandlerGlobal }

  // DEPRECATED
  TV8HandlerGlobal = class(TCefv8HandlerOwn)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TV8HandlerRequire }

  // DEPRECATED
  TV8HandlerRequire = class(TCefv8HandlerOwn)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TV8HandlerInitImport }

  TV8HandlerInitImport = class(TCefv8HandlerOwn)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;


procedure WebKitInitializedEvent;
begin
  //
end;

procedure ContextCreatedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
var
  msg: ICefProcessMessage;
  us: ustring;
  i, len: integer;
  v1, v2: ICefv8Value;
  handler: TModuleHandlers;
begin
  if browser.IsPopup then Exit;
  if MainBrowserID = 0 then MainBrowserID:= browser.Identifier;
  if browser.Identifier <> MainBrowserID then Exit;

  // DEPRECATED
  context.Global.SetValueByKey('require',
   TCefv8ValueRef.NewFunction('require', TV8HandlerGlobal.Create), V8_PROPERTY_ATTRIBUTE_NONE);

  // DEPRECATED
  context.Global.SetValueByKey('requireSync',
   TCefv8ValueRef.NewFunction('requireSync', TV8HandlerGlobal.Create), V8_PROPERTY_ATTRIBUTE_NONE);

  // window.G_VAR_IN_JS_NAME = {};
  v1:= TCefv8ValueRef.NewObject(nil, nil);
  context.Global.SetValueByKey(G_VAR_IN_JS_NAME, v1, V8_PROPERTY_ATTRIBUTE_NONE);

  len:= ModuleHandlerList.Count;
  for i:= 0 to len-1 do begin
    handler:= TModuleHandlers(ModuleHandlerList.Objects[i]);
    if Assigned(handler.creater) then begin
      us:= UTF8Decode(ModuleHandlerList[i]);
      v2:= TCefv8ValueRef.NewObject(nil, nil);
      v2.SetValueByKey('__init__',
       TCefv8ValueRef.NewFunction(us, TV8HandlerInitImport.Create), V8_PROPERTY_ATTRIBUTE_NONE);
      v1.SetValueByKey(us, v2, V8_PROPERTY_ATTRIBUTE_NONE);
    end;
  end;

  msg:= TCefProcessMessageRef.New('context_created');
  frame.SendProcessMessage(PID_BROWSER, msg);
end;

procedure ContextReleasedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
begin
  {$IFDEF USE_LUA_MODULE}
  llua_close;
  {$ENDIF}
end;

procedure FreeMemProc(buffer: Pointer);
begin
  FreeMem(buffer);
end;

procedure FreeMemProcUserObject(buffer: Pointer);
var
  s: string;
begin
  s:= StrPas(buffer);
  RemoveObjectList(s);
  FreeMem(buffer);
end;

function CefValueToCefv8Value(const cef: ICefValue): ICefv8Value;
var
  i, len: integer;
  sl: TStringList;
  us: ustring;
  s: string;
  p: PChar;
  handler: ICefv8Handler;
begin
  if not Assigned(cef) then begin
    Result:= TCefv8ValueRef.NewNull;
    Exit;
  end;
  case cef.GetType of
    VTYPE_BOOL:
      Result:= TCefv8ValueRef.NewBool(cef.GetBool);
    VTYPE_INT:
      Result:= TCefv8ValueRef.NewInt(cef.GetInt);
    VTYPE_DOUBLE:
      Result:= TCefv8ValueRef.NewDouble(cef.GetDouble);
    VTYPE_STRING:
      Result:= TCefv8ValueRef.NewString(cef.GetString);
    VTYPE_LIST: begin
      Result:= TCefv8ValueRef.NewArray(cef.GetList.GetSize);
      for i:= 0 to cef.GetList.GetSize-1 do begin
        Result.SetValueByIndex(i, CefValueToCefv8Value(cef.GetList.GetValue(i)));
      end;
    end;
    VTYPE_BINARY: begin
      len:= cef.GetBinary.Size;
      if len > 0 then begin
        p:= GetMem(len);
        cef.GetBinary.GetData(p, len, 0);
        Result:= TCefv8ValueRef.NewArrayBuffer(p, len,
          TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProc));
      end else begin
        Result:= TCefv8ValueRef.NewNull;
      end;
    end;
    VTYPE_DICTIONARY: begin
      if cef.GetDictionary.HasKey(VTYPE_FUNCTION_NAME) and
        (cef.GetDictionary.GetType(VTYPE_FUNCTION_NAME) = VTYPE_STRING)  then begin
        if cef.GetDictionary.HasKey('ModuleName') then begin
          // function
          handler:= TV8HandlerSafe.Create(
            UTF8Encode(cef.GetDictionary.GetString('ModuleName')),
            UTF8Encode(cef.GetDictionary.GetString('FuncName')),
            [],
            CefValueToCefv8Value(cef.GetDictionary.GetValue('CefObject')),
            CefValueToCefv8Value(cef.GetDictionary.GetValue('CefLocal')));
          Result:= TCefv8ValueRef.NewFunction(cef.GetDictionary.GetString(VTYPE_FUNCTION_NAME), handler);
        end else if cef.GetDictionary.HasKey('G_UID') then begin
          // function on _ipc_g
          Result:= TCefv8ContextRef.Current.GetGlobal.GetValueByKey(G_VAR_IN_JS_NAME);
          Result:= Result.GetValueByKey('_ipc_g');
          Result:= Result.GetValueByKey(cef.GetDictionary.GetString('G_UID'));
        end;
      end else begin
        Result:= TCefv8ValueRef.NewObject(nil, nil);
        sl:= TStringList.Create;
        try
          cef.GetDictionary.GetKeys(sl);
          for i:= 0 to sl.Count-1 do begin
            if sl[i] = VTYPE_OBJECT_NAME then begin
              // userdata
              us:= cef.GetDictionary.GetString(VTYPE_OBJECT_NAME);
              Result.SetValueByKey(VTYPE_OBJECT_NAME, TCefv8ValueRef.NewString(us), V8_PROPERTY_ATTRIBUTE_NONE);

              s:= UTF8Encode(us);
              len:= Length(s) + 1;
              p:= GetMem(len);
              Move(PChar(s)^, p^, len);
              Result.SetValueByKey(VTYPE_OBJECT_FIELD, TCefv8ValueRef.NewArrayBuffer(
                p, len, TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProcUserObject)), V8_PROPERTY_ATTRIBUTE_NONE);
            end else begin
              us:= UTF8Decode(sl[i]);
              if (cef.GetDictionary.GetType(us) = VTYPE_DICTIONARY) and
                cef.GetDictionary.GetDictionary(us).HasKey(VTYPE_FUNCTION_NAME) and
                (cef.GetDictionary.GetDictionary(us).GetType(VTYPE_FUNCTION_NAME) = VTYPE_BOOL) and
                cef.GetDictionary.GetDictionary(us).HasKey('ModuleName') then begin
                // function
                // DEPRECATED
                s:= UTF8Encode(cef.GetDictionary.GetDictionary(us).GetString('FuncName')) + ' in ' + UTF8Encode(cef.GetDictionary.GetDictionary(us).GetString('ModuleName')) + ' : '#$0d;
                showWarning(s + 'func.SetBool(VTYPE_FUNCTION_NAME, true) has been DEPRECATED. Use func.SetString(VTYPE_FUNCTION_NAME, "name of function")');
                handler:= TV8HandlerSafe.Create(
                  UTF8Encode(cef.GetDictionary.GetDictionary(us).GetString('ModuleName')),
                  UTF8Encode(cef.GetDictionary.GetDictionary(us).GetString('FuncName')),
                  [],
                  CefValueToCefv8Value(cef.GetDictionary.GetDictionary(us).GetValue('CefObject')),
                  CefValueToCefv8Value(cef.GetDictionary.GetDictionary(us).GetValue('CefLocal')));
                Result.SetValueByKey(us, TCefv8ValueRef.NewFunction(us, handler), V8_PROPERTY_ATTRIBUTE_NONE);
              end else begin
                Result.SetValueByKey(us, CefValueToCefv8Value(cef.GetDictionary.GetValue(us)), V8_PROPERTY_ATTRIBUTE_NONE);
              end;
            end;
          end;
        finally
          sl.Free;
        end;
      end;
    end;

    else
      Result:= TCefv8ValueRef.NewNull;
  end;
end;

procedure ProcessMessageReceivedEvent(const browser: ICefBrowser;
  const frame: ICefFrame; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; var aHandled: boolean);
var
  context: ICefv8Context;

  procedure promise;
  var
    ipc, v1, v2, g, param: ICefv8Value;
    us, us2: ustring;
    sl: TStringList;
    i, len: integer;
  begin
    g:= TCefv8ContextRef.Current.GetGlobal;
    ipc:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc');
    us:= message.ArgumentList.GetString(0);
    if not Assigned(ipc) or not ipc.HasValueByKey(us) then Exit;
    try
      i:= message.ArgumentList.GetInt(1);
      if i = 0 then Exit;
      if i = 1 then begin
        v1:= ipc.GetValueByKey(us).GetValueByKey('resolve');
        param:= CefValueToCefv8Value(message.ArgumentList.GetValue(2));
        if ipc.GetValueByKey(us).HasValueByKey('resolve_args') then begin
          v2:= ipc.GetValueByKey(us).GetValueByKey('resolve_args');
          if param.IsObject and v2.IsObject then begin
            sl:= TStringList.Create;
            try
              v2.GetKeys(sl);
              len:= sl.Count;
              for i:= 0 to len-1 do begin
                param.SetValueByIndex(param.GetArrayLength, v2.GetValueByKey(UTF8Decode(sl[i])));
              end;
            finally
              sl.Free;
            end;
          end else begin
            param:= v2;
          end;
        end;
      end else begin
        v1:= ipc.GetValueByKey(us).GetValueByKey('reject');
        // e = new Error(message)
        us2:= '';
        if ipc.GetValueByKey(us).HasValueByKey('moduleName') then begin
          us2:= us2 + 'in ' + ipc.GetValueByKey(us).GetValueByKey('moduleName').GetStringValue + '.';
        end;
        if ipc.GetValueByKey(us).HasValueByKey('funcName') then begin
          us2:= us2 + ipc.GetValueByKey(us).GetValueByKey('funcName').GetStringValue + '(): ';
        end;
        v2:= TCefv8ValueRef.NewString(us2 + message.ArgumentList.GetString(2));
        param:= NewV8Object(g.GetValueByKey('Error'), [v2]);
      end;
      v1.ExecuteFunction(nil, [param]);
    finally
      ipc.DeleteValueByKey(us);
      CleanupIPCG;
    end;
  end;

  // DEPRECATED
  procedure newFunction;
  var
    ipc, v1, v2, g: ICefv8Value;
    arr: TCefv8ValueArray;
    us: ustring;
    i, len: integer;
  begin
    // const F = new Function("...args", code)
    g:= TCefv8ContextRef.Current.GetGlobal;
    v1:= newV8Object(g.GetValueByKey('Function'),
      [TCefv8ValueRef.NewString('...args'), CefValueToCefv8Value(message.ArgumentList.GetValue(1))]);
    // result = F(...args)
    len:= message.ArgumentList.GetList(0).GetSize; // args
    SetLength(arr{%H-}, len);
    for i:= 0 to len-1 do begin
      arr[i]:= CefValueToCefv8Value(message.ArgumentList.GetList(0).GetValue(i));
    end;
    v1:= v1.ExecuteFunction(nil, arr);
    if message.ArgumentList.GetString(2) <> '' then begin
      // to resolve promise
      g:= TCefv8ContextRef.Current.GetGlobal;
      ipc:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc');
      us:= message.ArgumentList.GetString(2);
      if not Assigned(ipc) or not ipc.HasValueByKey(us) then Exit;
      try
        v2:= ipc.GetValueByKey(us).GetValueByKey('resolve');
        v2.ExecuteFunction(nil, [v1]);
      finally
        ipc.DeleteValueByKey(us);
      end;
    end;
  end;

  procedure newFunctionRe;
  var
    ipc, v1, g, resolve, reject: ICefv8Value;
    arr: TCefv8ValueArray;
    us: ustring;
    i, len: integer;
    msg: ICefProcessMessage;
  begin
    // const F = new Function("resolve, reject, ...args", code)
    g:= TCefv8ContextRef.Current.GetGlobal;
    v1:= newV8Object(g.GetValueByKey('Function'),
      [TCefv8ValueRef.NewString('resolve,reject,...args'), CefValueToCefv8Value(message.ArgumentList.GetValue(1))]);

    // result = F(resolve, reject, ...args)
    len:= message.ArgumentList.GetList(0).GetSize; // args
    SetLength(arr{%H-}, len+2);
    us:= message.ArgumentList.GetString(2);
    ipc:= nil;
    resolve:= TCefV8ValueRef.NewNull;
    reject:= TCefV8ValueRef.NewNull;
    if us <> '' then begin
      // to resolve promise
      ipc:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc');
      if Assigned(ipc) and ipc.HasValueByKey(us) then begin
        resolve:= ipc.GetValueByKey(us).GetValueByKey('resolve');
        reject:= ipc.GetValueByKey(us).GetValueByKey('reject');
      end;
    end;
    arr[0]:= resolve;
    arr[1]:= reject;
    for i:= 0 to len-1 do begin
      arr[i+2]:= CefValueToCefv8Value(message.ArgumentList.GetList(0).GetValue(i));
    end;

    v1:= v1.ExecuteFunction(nil, arr);

    msg:= TCefProcessMessageRef.New('new_function_re');
    msg.ArgumentList.SetString(0, message.ArgumentList.GetString(3)); // resultId
    msg.ArgumentList.SetValue(1, Cefv8ValueToCefValue(v1));
    frame.SendProcessMessage(PID_BROWSER, msg);
  end;

begin
  aHandled:= True;
  context:= frame.GetV8Context;
  case message.Name of
    'promise': begin
      context.Enter;
      try
        promise;
      finally
        context.Exit;
      end;
    end;
    'new_function': begin // DEPRECATED
      context.Enter;
      try
        showWarning('unit_js.NewFunction() has been DEPRECATED. use unit_js.NewFunctionRe().');
        newFunction;
      finally
        context.Exit;
      end;
    end;
    'new_function_re': begin
      context.Enter;
      try
        newFunctionRe;
      finally
        context.Exit;
      end;
    end;
  end;
end;

// DEPRECATED
procedure AddModuleHandler(const name: string;
  requireCreate, requireExecute: TRequireFunction; safeExecute: TSafeExecute);
var
  handlers: TModuleHandlers;
begin
  if not Assigned(ModuleHandlerList) then begin
    ModuleHandlerList:= TStringList.Create;
    ModuleHandlerList.Sorted:= True;
    ModuleHandlerList.OwnsObjects:= True;
  end;
  handlers:= TModuleHandlers.Create;
  handlers.requireCreate:= requireCreate;
  handlers.requireExecute:= requireExecute;
  handlers.safeExecute:= safeExecute;
  ModuleHandlerList.AddObject(name, handlers);
end;

procedure AddModuleHandler(const name, body: string;
  creater: TImportCreate; safeExecute: TSafeExecute);
var
  i: integer;
  handler: TModuleHandlers;
begin
  if not Assigned(ModuleHandlerList) then begin
    ModuleHandlerList:= TStringList.Create;
    ModuleHandlerList.Sorted:= True;
    ModuleHandlerList.OwnsObjects:= True;
  end;
  i:= ModuleHandlerList.IndexOf(name);
  if i < 0 then begin
    handler:= TModuleHandlers.Create;
    handler.requireCreate:= nil;
    handler.requireExecute:= nil;
    handler.safeExecute:= safeExecute;
    handler.creater:= creater;
    handler.body:= body;
    ModuleHandlerList.AddObject(name, handler);
  end else begin
    // It's unnecessary in the future.
    handler:= TModuleHandlers(ModuleHandlerList.Objects[i]);
    handler.safeExecute:= safeExecute;
    handler.creater:= creater;
    handler.body:= body;
  end;
end;

type

  { TAddObjectListTask }

  TAddObjectListTask = class(TCefTaskOwn)
  private
    uuid: string;
    obj: TObject;
  protected
    procedure Execute; override;
  public
    constructor Create(const auuid: string; aobj: TObject); reintroduce;
  end;

  { TRemoveObjectListTask }

  TRemoveObjectListTask = class(TCefTaskOwn)
  private
    uuid: string;
    result: TTaskResult;
  protected
    procedure Execute; override;
  public
    constructor Create(const auuid: string; aresult: TTaskResult = nil); reintroduce;
  end;

{ TAddObjectListTask }

procedure TAddObjectListTask.Execute;
begin
  if not Assigned(ObjectList) then begin
    ObjectList:= TSafeStringList.Create;
  end;
  ObjectList.AddObject(uuid, obj);
end;

constructor TAddObjectListTask.Create(const auuid: string; aobj: TObject);
begin
  uuid:= auuid;
  obj:= aobj;
  inherited Create;
end;

{ TRemoveObjectListTask }

constructor TRemoveObjectListTask.Create(const auuid: string; aresult: TTaskResult);
begin
  uuid:= auuid;
  result:= aresult;
  inherited Create;
end;

procedure TRemoveObjectListTask.Execute;
begin
  ObjectList.RemoveObject(uuid);
  if Assigned(result) then result.callback(TObject(1));
end;

{ TTaskResult }

procedure TTaskResult.callback(obj: TObject);
begin
  result:= obj;
end;

{ TObjectWithInterface }

destructor TObjectWithInterface.Destroy;
begin
  cefBaseRefCounted:= nil;
  inherited Destroy;
end;

{ TCefValueExRef }

destructor TCefValueExRef.Destroy;
var
  uid: string;
  g, v: ICefv8Value;
begin
  if RefCount = 0 then begin
    if GetType = VTYPE_DICTIONARY then begin
      if GetDictionary.HasKey(VTYPE_FUNCTION_NAME) then begin
        if GetDictionary.HasKey('G_UID') then begin
          if Assigned(TCefv8ContextRef.Current) and
            Assigned(TCefv8ContextRef.Current.GetGlobal) then begin
            g:= TCefv8ContextRef.Current.GetGlobal;
            g:= g.GetValueByKey(G_VAR_IN_JS_NAME);
            g:= g.GetValueByKey('_ipc_g');
            v:= g.GetValueByKey(GetDictionary.GetString('G_UID'));
            v.SetValueByKey('del', TCefV8ValueRef.NewDouble(Now), V8_PROPERTY_ATTRIBUTE_NONE);
          end else begin
            uid:= UTF8Encode(GetDictionary.GetString('G_UID'));
            NewFunctionRe(G_VAR_IN_JS_NAME + '._ipc_g["' + uid + '"].del=' +
             FloatToStr(Now) + ';', nil, '', false);
          end;
        end;
      end;
    end;
  end;

  inherited Destroy;
end;

function AddObjectList(const obj: TObject): string;
begin
  Result:= NewUID;
  AddObjectListUUID(Result, obj);
end;

procedure AddObjectListUUID(const uuid: string; obj: TObject);
begin
  CefPostTask(TID_UI, TAddObjectListTask.Create(uuid, obj));
end;

function GetObjectList(const uuid: string): TObject;
begin
  if not Assigned(ObjectList) then begin
    Result:= nil;
    Exit;
  end;
  Result:= ObjectList.GetObject(uuid);
end;

procedure SetObjectList(const uuid: string; obj: TObject);
begin
  ObjectList.SetObject(uuid, obj);
end;

procedure RemoveObjectList(const uuid: string);
begin
  CefPostTask(TID_UI, TRemoveObjectListTask.Create(uuid));
end;

procedure RemoveObjectListResult(const uuid: string; result: TTaskResult);
begin
  CefPostTask(TID_UI, TRemoveObjectListTask.Create(uuid, result));
end;

function StringPasToJS(const str: string): string;
begin
  Result:= '"'
   + StringReplace(StringReplace(str, '"', '\"', [rfReplaceAll]),
      '\', '\\', [rfReplaceAll])
   + '"';
end;

function StringPasToJS2(const str: string): string;
var
  i, l: integer;
  us: ustring;
begin
  us:= UTF8Decode(str);
  Result:= '';
  l:= Length(us);
  for i:= 1 to l do begin
    Result:= Result + '\u' + IntToHex(ord(us[i]), 4);
  end;
  Result:= '"' + Result + '"';
end;

procedure showWarning(const msg: string);
var
  v1, v2, g: ICefv8Value;
begin
  g:= TCefv8ContextRef.Current.GetGlobal;
  v1:= g.GetValueByKey('console');
  v2:= v1.GetValueByKey('warn');
  v2.ExecuteFunction(v1, [TCefv8ValueRef.NewString(UTF8Decode(msg))]);
end;

procedure showWarningUI(const msg: string);
var
  args: ICefListValue;
begin
  args:= TCefListValueRef.New;
  args.SetString(0, UTF8Decode(msg));
  NewFunctionRe('console.warn(args[0]);', args, '', false);
end;

{ TV8HandlerGlobal }

// DEPRECATED
function TV8HandlerGlobal.Execute(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;

  //
  function requireSync: boolean;
  var
    us: ustring;
    i: integer;
    handlers: TModuleHandlers;
  begin
    Result:= True;
    if Length(arguments) > 0 then begin
      us:= arguments[0].GetStringValue;
      i:= ModuleHandlerList.IndexOf(UTF8Encode(us));
      if i < 0 then begin
        exception:= 'You forgot to add "' + us + '" module handler to ModuleHandlerList.';
        exit;
      end;
      handlers:= TModuleHandlers(ModuleHandlerList.Objects[i]);
      if not Assigned(handlers.requireCreate) then begin
        exception:= '"' + us + '" module does NOT support requireSync(). Use require().';
        exit;
      end;
      Result:= handlers.requireCreate(us, obj, arguments, retval, exception);
    end;
  end;

var
  us: ustring;
  i: integer;
begin
  Result:= False;
  case name of
    'require': begin
      showWarning('require() has been deprecated. Please use import().');
      if Length(arguments) > 0 then begin
        us:= arguments[0].GetStringValue;
        i:= ModuleHandlerList.IndexOf(UTF8Encode(us));
        if i < 0 then begin
          exception:= 'You forgot to add "' + us + '" module handler to ModuleHandlerList.';
          Result:= True;
          exit;
        end;
        // require = new Promise(f)
        retval:= newV8Promise(us, TV8HandlerRequire.Create);
      end;
    end;

    'requireSync': begin
      showWarning('requireSync() has been deprecated. Please use import.');
      Result:= requireSync;
    end;
  end;
  Result:= True;
end;

{ TV8HandlerRequire }

// DEPRECATED
function TV8HandlerRequire.Execute(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  i: integer;
  handler: TModuleHandlers;
begin
  Result:= False;
  i:= ModuleHandlerList.IndexOf(UTF8Encode(name));
  handler:= TModuleHandlers(ModuleHandlerList.Objects[i]);
  if not Assigned(handler.requireExecute) then begin
    exception:= '"' + name + '" module does NOT support require(). Use import().';
    exit;
  end;
  Result:= handler.requireExecute(name, obj, arguments, retval, exception);
end;

{ TV8HandlerInitImport }

function TV8HandlerInitImport.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  s: string;
  v1, g: ICefv8Value;
  i: integer;
  handler: TModuleHandlers;
begin
  s:= UTF8Encode(name);
  i:= ModuleHandlerList.IndexOf(s);
  handler:= TModuleHandlers(ModuleHandlerList.Objects[i]);
  v1:= handler.creater(s);
  g:= TCefv8ContextRef.Current.GetGlobal.GetValueByKey(G_VAR_IN_JS_NAME);
  g.SetValueByKey(name, v1, V8_PROPERTY_ATTRIBUTE_NONE);
  Result:= True;
end;

{ TV8HandlerSafe }

function TV8HandlerSafe.Execute(const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  i: integer;
  handlers: TModuleHandlers;
begin
  Result:= False;
  i:= ModuleHandlerList.IndexOf(FModuleName);
  if i < 0 then begin
    exception:= UTF8Decode('You forgot to add "' + FModuleName + '" module handler to ModuleHandlerList.');
    Result:= True;
    exit;
  end;
  handlers:= TModuleHandlers(ModuleHandlerList.Objects[i]);
  Result:= handlers.safeExecute(self, name, obj, arguments, retval, exception);
end;

constructor TV8HandlerSafe.Create(const aModuleName, aFuncName: string; const aArgs: TCefv8ValueArray = nil; aobj:ICefv8Value = nil; alocal:ICefv8Value = nil); overload;
begin
  FModuleName:= aModuleName;
  FFuncName:= afuncName;
  FArgs:= aargs;
  FObject:= aobj;
  FLocal:= alocal;
  inherited Create;
end;

function Cefv8ValueToCefValue(const v8: ICefv8Value; convFuncs: boolean): ICefValue;

  procedure setFunction(const v: ICefValue);
  var
    key: ustring;
    gvar, ipcg, funcs: ICefv8Value;
    dic: ICefDictionaryValue;
  begin
    key:= UTF8Decode(NewUID());
    gvar:= TCefv8ContextRef.Current.GetGlobal.GetValueByKey(G_VAR_IN_JS_NAME);
    ipcg:= gvar.GetValueByKey('_ipc_g');
    ipcg.SetValueByKey(key, TCefV8ValueRef.NewObject(nil, nil), V8_PROPERTY_ATTRIBUTE_NONE);
    funcs:= ipcg.GetValueByKey(key);
    dic:= TCefDictionaryValueRef.New;
    dic.SetString(VTYPE_FUNCTION_NAME, v8.GetFunctionName);
    funcs.SetValueByKey('f', v8, V8_PROPERTY_ATTRIBUTE_NONE);
    dic.SetString('FuncName', G_VAR_IN_JS_NAME + '._ipc_g["' + key + '"].f');
    dic.SetString('G_UID', key);
    v.SetDictionary(dic);
  end;

var
  v1, v2, v3: ICefv8Value;
  i, len: integer;
  sl: TStringList;
  list: ICefListValue;
  dic: ICefDictionaryValue;
  us: ustring;
  s: string;
begin
  Result:= TCefValueExRef.New;
  if not Assigned(v8) or v8.IsUndefined or v8.IsNull then begin
    Result.SetNull();
  end else if v8.IsInt then begin
    Result.SetInt(v8.GetIntValue);
  end else if v8.IsDouble then begin
    Result.SetDouble(v8.GetDoubleValue);
  end else if v8.IsBool then begin
    Result.SetBool(v8.GetBoolValue);
  end else if v8.IsString then begin
    Result.SetString(v8.GetStringValue);
  end else if v8.IsArray then begin
    list:= TCefListValueRef.New;
    len:= v8.GetArrayLength;
    //list.SetSize(len);
    for i:= 0 to len-1 do begin
      list.SetValue(i, Cefv8ValueToCefValue(v8.GetValueByIndex(i), convFuncs));
    end;
    Result.SetList(list);
  end else if v8.IsArrayBuffer then begin
    // dataView = new DataView(v8)
    v1:= newV8Object(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('DataView'), [v8]);
    // len = dataView.byteLength
    len:= v1.GetValueByKey('byteLength').GetIntValue;
    // for (let i=0;i<l;i++) s[i] = dataView.getUint8(i)
    SetLength(s{%H-}, len);
    v2:= v1.GetValueByKey('getUint8');
    for i:= 0 to len-1 do begin
      v3:= TCefv8ValueRef.NewInt(i);
      s[i+1]:= Chr(v2.ExecuteFunction(v1, [v3]).GetIntValue);
    end;
    Result.SetBinary(TCefBinaryValueRef.New(@s[1], len));
  end else if v8.IsFunction then begin
    if convFuncs then setFunction(Result);
  end else if v8.IsObject then begin
    sl:= TStringList.Create;
    try
      v8.GetKeys(sl);
      dic:= TCefDictionaryValueRef.New;
      for i:= 0 to sl.count-1 do begin
        us:= UTF8Decode(sl[i]);
        dic.SetValue(us, Cefv8ValueToCefValue(v8.GetValueByKey(us), convFuncs));
      end;
      Result.SetDictionary(dic);
    finally
      sl.Free;
    end;
  end;
end;

function Cefv8ArrayToCefList(const v8: TCefv8ValueArray; convFuncs: boolean = true): ICefListValue;
var
  i, len: integer;
begin
  Result:= TCefListValueRef.New;
  len:= Length(v8);
  //Result.SetSize(len);
  for i:= 0 to len-1 do begin
    Result.SetValue(i, Cefv8ValueToCefValue(v8[i], convFuncs));
  end;
end;

function CopyCefValueEx(const src: ICefBaseRefCounted): ICefValue;
var
  uid, uid2, us: ustring;
  g: ICefv8Value;
  srcdic, dic: ICefDictionaryValue;
  srclist, list: ICefListValue;
  sl: TStringList;
  i, len: integer;
begin
  Result:= nil;
  dic:= nil;
  if src is ICefDictionaryValue then begin
    srcdic:= ICefDictionaryValue(src);
    dic:= TCefDictionaryValueRef.New;
    Result:= TCefValueExRef.New;
    Result.SetDictionary(dic);
  end else if src is ICefValue then begin
    case ICefValue(src).GetType of
      VTYPE_BOOL: begin
        Result:= TCefValueExRef.New;
        Result.SetBool(ICefValue(src).GetBool);
      end;
      VTYPE_INT: begin
        Result:= TCefValueExRef.New;
        Result.SetInt(ICefValue(src).GetInt);
      end;
      VTYPE_DOUBLE: begin
        Result:= TCefValueExRef.New;
        Result.SetDouble(ICefValue(src).GetDouble);
      end;
      VTYPE_STRING: begin
        Result:= TCefValueExRef.New;
        Result.SetString(ICefValue(src).GetString);
      end;
      VTYPE_LIST: begin
        Result:= TCefValueExRef.New;
        list:= TCefListValueRef.New;
        Result.SetList(list);
        srclist:= ICefValue(src).GetList;
        len:= srclist.GetSize;
        for i:= 0 to len-1 do begin
          list.SetValue(i, CopyCefValueEx(srclist.GetValue(i)));
        end;
      end;
      VTYPE_BINARY: begin
        Result:= TCefValueExRef.New;
        Result.SetBinary(ICefValue(src).GetBinary.Copy);
      end;
      VTYPE_DICTIONARY: begin
        srcdic:= ICefValue(src).GetDictionary;
        dic:= TCefDictionaryValueRef.New;
        Result:= TCefValueExRef.New;
        Result.SetDictionary(dic);
      end;
    end;
  end;

  if Assigned(dic) then begin
    if srcdic.HasKey(VTYPE_FUNCTION_NAME) and srcdic.HasKey('G_UID') then begin
      uid:= srcdic.GetString('G_UID');
      uid2:= UTF8Decode(NewUID());
      dic.SetString(VTYPE_FUNCTION_NAME, srcdic.GetString(VTYPE_FUNCTION_NAME));
      dic.SetString('FuncName', G_VAR_IN_JS_NAME + '._ipc_g["' + uid2 + '"].f');
      dic.SetString('G_UID', uid2);
      if Assigned(TCefv8ContextRef.Current) and Assigned(TCefv8ContextRef.Current.GetGlobal) then begin
        g:= TCefv8ContextRef.Current.GetGlobal;
        g:= g.GetValueByKey(G_VAR_IN_JS_NAME);
        g:= g.GetValueByKey('_ipc_g');
        g.SetValueByKey(uid2, TCefV8ValueRef.NewObject(nil, nil), V8_PROPERTY_ATTRIBUTE_NONE);
        g.GetValueByKey(uid2).SetValueByKey('f',
         g.GetValueByKey(uid).GetValueByKey('f'), V8_PROPERTY_ATTRIBUTE_NONE);
      end else begin
        NewFunctionRe(
         G_VAR_IN_JS_NAME + '._ipc_g["' + UTF8Encode(uid2) + '"]={}; ' +
         G_VAR_IN_JS_NAME + '._ipc_g["' + UTF8Encode(uid2) + '"].f=' +
         G_VAR_IN_JS_NAME + '._ipc_g["' + UTF8Encode(uid) + '"].f;', nil, '', true);
      end;
    end else begin
      sl:= TStringList.Create;
      try
        srcdic.GetKeys(sl);
        for i:= 0 to sl.count-1 do begin
          us:= UTF8Decode(sl[i]);
          dic.SetValue(us, CopyCefValueEx(srcdic.GetValue(us)));
        end;
      finally
        sl.Free;
      end;
    end;
  end;
end;

procedure CleanupIPCG;
var
  v, g, ipcg: ICefv8Value;
  sl: TStringList;
  i, len: integer;
  us: ustring;
begin
  g:= TCefv8ContextRef.Current.GetGlobal;
  ipcg:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc_g');
  sl:= TStringList.Create;
  try
    ipcg.GetKeys(sl);
    len:= sl.Count;
    for i:= 0 to len-1 do begin
      us:= UTF8Decode(sl[i]);
      v:= ipcg.GetValueByKey(us);
      v:= v.GetValueByKey('del');
      if Assigned(v) and v.IsDouble and
        (SecondsBetween(Now, v.GetDoubleValue) >= 60) then ipcg.DeleteValueByKey(us);
    end;
  finally
    sl.Free;
  end;
end;

// DEPRECATED
procedure RemoveIPCG(const uid: string);
begin
  showWarningUI('RemoveIPCG() has been deprecated. No need to call this function anymore.');
  //NewFunctionRe('delete ' + G_VAR_IN_JS_NAME + '._ipc_g["' + uid + '"];', nil, '', false);
end;

function NewV8Object(const parent: ICefv8Value; const args: TCefv8ValueArray): ICefv8Value;
var
  v1, v2, v3, g: ICefv8Value;
  i, len: integer;
begin
  g:= TCefv8ContextRef.Current.GetGlobal;
  v1:= g.GetValueByKey('Reflect');
  v2:= v1.GetValueByKey('construct');
  len:= Length(args);
  v3:= TCefv8ValueRef.NewArray(len);
  for i:= 0 to len-1 do v3.SetValueByIndex(i, args[i]);
  Result:= v2.ExecuteFunction(v1, [parent, v3]);
end;

function NewV8Promise(const name: ustring; const handler: ICefv8Handler): ICefv8Value;
var
  v1, v2, v3, g: ICefv8Value;
begin
  g:= TCefv8ContextRef.Current.GetGlobal;
  v1:= g.GetValueByKey('Reflect');
  v2:= v1.GetValueByKey('construct');
  v3:= TCefv8ValueRef.NewArray(1);
  v3.SetValueByIndex(0, TCefv8ValueRef.NewFunction(name, handler));
  Result:= v2.ExecuteFunction(v1, [g.GetValueByKey('Promise'), v3]);
end;

type

  { TNewFunctionTask }

  // DEPRECATED
  TNewFunctionTask = class(TCefTaskOwn)
  private
    code: string;
    args: ICefListValue;
    uid: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const acode: string; aargs: ICefListValue; const auid: string); reintroduce;
  end;

// DEPRECATED
constructor TNewFunctionTask.Create(const acode: string; aargs: ICefListValue; const auid: string);
begin
  code:= acode;
  args:= aargs;
  uid:= auid;
  inherited Create;
end;

// DEPRECATED
procedure TNewFunctionTask.Execute;
var
  msg: ICefProcessMessage;
begin
  msg:= TCefProcessMessageRef.New('new_function');
  if Assigned(args) then begin
    msg.ArgumentList.SetList(0, args);
  end else begin
    msg.ArgumentList.SetList(0, TCefListValueRef.New);
  end;
  msg.ArgumentList.SetString(1, UTF8Decode(code));

  msg.ArgumentList.SetString(2, UTF8Decode(uid));

  unit_global.Chromium.SendProcessMessage(PID_RENDERER, msg);
end;

// DEPRECATED
procedure NewFunction(const code: string; const args: ICefListValue; const uid: string);
begin
  CefPostTask(TID_UI, TNewFunctionTask.Create(code, args, uid));
end;

function NewFunctionRe(const code: string; const args: ICefListValue;
  const uid: string; return: boolean; const crm: TChromiumCore): ICefValue;
var
  msg: ICefProcessMessage;
  resultId: string;
  obj: TObjectWithInterface;
begin
  msg:= TCefProcessMessageRef.New('new_function_re');
  if Assigned(args) then begin
    msg.ArgumentList.SetList(0, args);
  end else begin
    msg.ArgumentList.SetList(0, TCefListValueRef.New);
  end;
  msg.ArgumentList.SetString(1, UTF8Decode(code));

  msg.ArgumentList.SetString(2, UTF8Decode(uid));
  resultId:= AddObjectList(nil);
  msg.ArgumentList.SetString(3, UTF8Decode(resultId));

  if Assigned(crm) then
    crm.SendProcessMessage(PID_RENDERER, msg)
  else
    unit_global.Chromium.SendProcessMessage(PID_RENDERER, msg);

  Result:= nil;
  while return and not unit_global.appClosing do begin
    obj:= TObjectWithInterface(GetObjectList(resultId));
    if Assigned(obj) then begin
      Result:= obj.cefBaseRefCounted as ICefValue;
      break;
    end;
    Sleep(1);
  end;

  RemoveObjectList(resultId);
end;

function NewFunctionV8(const code: string; const args: TCefv8ValueArray): ICefv8Value;
begin
  // const F = new Function("...args", code)
  Result:= newV8Object(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('Function'),
    [TCefv8ValueRef.NewString('...args'), TCefv8ValueRef.NewString(UTF8Decode(code))]);
  // result = F(...args)
  Result:= Result.ExecuteFunction(nil, args);
end;

function NewUserObject(const obj: TObject): ICefDictionaryValue;
var
  s: string;
begin
  Result:= TCefDictionaryValueRef.New;
  s:= AddObjectList(obj);
  Result.SetString(VTYPE_OBJECT_NAME, UTF8Decode(s));
end;

function NewUserObjectV8(const obj: TObject): ICefv8Value;
var
  s: string;
  len: integer;
  p: PChar;
begin
  Result:= TCefv8ValueRef.NewObject(nil, nil);
  s:= AddObjectList(obj);
  Result.SetValueByKey(VTYPE_OBJECT_NAME, TCefv8ValueRef.NewString(UTF8Decode(s)), V8_PROPERTY_ATTRIBUTE_NONE);
  len:= Length(s) + 1;
  p:= GetMem(len);
  Move(PChar(s)^, p^, len);
  Result.SetValueByKey(VTYPE_OBJECT_FIELD, TCefv8ValueRef.NewArrayBuffer(
    p, len, TCefFastv8ArrayBufferReleaseCallback.Create(@FreeMemProcUserObject)), V8_PROPERTY_ATTRIBUTE_NONE);
end;

initialization
  MainBrowserID:= 0;
end.

