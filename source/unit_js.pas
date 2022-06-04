unit unit_js;

{.$DEFINE USE_LUA_MODULE}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uCEFInterfaces, uCEFTypes, uCEFv8Handler, uCEFValue, uCEFv8Value;

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

  //{ ICefUserDataObject }
  //
  //ICefUserDataObject = interface(ICefv8Value)
  //  ['{7754755E-2B08-4E4A-AF75-5FE805B5E453}'] // SHIFT+CTRL+G!
  //  function GetObject: TObject;
  //end;
  //
  //{ TCefUserDataObject }
  //
  //TCefUserDataObject = class(TCefv8ValueRef, ICefUserDataObject)
  //private
  //  obj: TObject;
  //protected
  //public
  //  constructor Create(const aobj: TObject); overload;
  //  destructor Destroy; override;
  //  function GetObject: TObject;
  //end;


procedure WebKitInitializedEvent;
procedure ContextCreatedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
procedure ContextReleasedEvent(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
procedure ProcessMessageReceivedEvent(const browser: ICefBrowser; const frame: ICefFrame; sourceProcess: TCefProcessId; const message: ICefProcessMessage; var aHandled : boolean);

procedure AddModuleHandler(const name: string; requireCreate, requireExecute: TRequireFunction; safeExecute: TSafeExecute);
procedure AddModuleHandler(const name, body: string; creater: TImportCreate; safeExecute: TSafeExecute);
function AddObjectList(obj: TObject): string;
procedure AddObjectListUUID(const uuid: string; obj: TObject);
function GetObjectList(const uuid: string): TObject;
procedure RemoveObjectList(const uuid: string);
procedure RemoveObjectListResult(const uuid: string; result: TTaskResult);
function StringPasToJS(const str: string): string;
function StringPasToJS2(const str: string): string;
function CefValueToCefv8Value(cef: ICefValue): ICefv8Value;
function Cefv8ValueToCefValue(v8: ICefv8Value): ICefValue;
function Cefv8ArrayToCefList(v8: TCefv8ValueArray): ICefListValue;
function NewV8Object(parent: ICefv8Value; const args: TCefv8ValueArray): ICefv8Value;
function NewV8Promise(const name: ustring; handler: ICefv8Handler): ICefv8Value;
procedure NewFunction(const code: string; args: ICefListValue = nil; const uid: string = '');
function NewFunctionV8(const code: string; args: TCefv8ValueArray): ICefv8Value;
function NewUserObject(obj: TObject): ICefDictionaryValue;
function NewUserObjectV8(obj: TObject): ICefv8Value;
procedure showWarning(const msg: string);

procedure FreeMemProc(buffer: Pointer);

implementation
uses
  unit1, unit_global,
  {$IFDEF USE_LUA_MODULE}
  unit_mod_lua,
  {$ENDIF}
  Forms, TypInfo,
  uCEFConstants, uCEFListValue, uCEFv8Context, uCEFProcessMessage,
  uCefDictionaryValue, uCefBinaryValue, uCEFTask, uCEFMiscFunctions,
  uCefv8ArrayBufferReleaseCallback;

type

  { TV8HandlerGlobal }

  TV8HandlerGlobal = class(TCefv8HandlerOwn)
  protected
    function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

  { TV8HandlerRequire }

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

  context.Global.SetValueByKey('require',
   TCefv8ValueRef.NewFunction('require', TV8HandlerGlobal.Create), V8_PROPERTY_ATTRIBUTE_NONE);

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

function CefValueToCefv8Value(cef: ICefValue): ICefv8Value;
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
              (cef.GetDictionary.GetDictionary(us).HasKey(VTYPE_FUNCTION_NAME)) then begin
              // function
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
    else
      Result:= TCefv8ValueRef.NewNull;
  end;
end;

procedure ProcessMessageReceivedEvent(const browser: ICefBrowser;
  const frame: ICefFrame; sourceProcess: TCefProcessId;
  const message: ICefProcessMessage; var aHandled: boolean);
var
  context: ICefv8Context;
  ipc, v1, v2, g, param: ICefv8Value;
  arr: TCefv8ValueArray;
  us, us2: ustring;
  sl: TStringList;
  i, len: integer;
begin
  aHandled:= True;
  context:= frame.GetV8Context;
  case message.Name of
    'promise': begin
      context.Enter;
      try
        g:= TCefv8ContextRef.Current.GetGlobal;
        ipc:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc');
        us:= message.ArgumentList.GetString(0);
        if not Assigned(ipc) or not ipc.HasValueByKey(us) then Exit;
        try
          if message.ArgumentList.GetBool(1) then begin
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
        end;
      finally
        context.Exit;
      end;
    end;
    'new_function': begin
      context.Enter;
      try
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
      finally
        context.Exit;
      end;
    end;
  end;
end;

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
  handler: TModuleHandlers;
begin
  if not Assigned(ModuleHandlerList) then begin
    ModuleHandlerList:= TStringList.Create;
    ModuleHandlerList.Sorted:= True;
    ModuleHandlerList.OwnsObjects:= True;
  end;
  handler:= TModuleHandlers.Create;
  handler.requireCreate:= nil;
  handler.requireExecute:= nil;
  handler.safeExecute:= safeExecute;
  handler.creater:= creater;
  handler.body:= body;
  ModuleHandlerList.AddObject(name, handler);
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

//{ TCefUserDataObject }
//
//constructor TCefUserDataObject.Create(const aobj: TObject);
//begin
//  obj:= aobj;
//  inherited Create(cef_value_create());
//end;
//
//destructor TCefUserDataObject.Destroy;
//begin
//  inherited Destroy;
//end;
//
//function TCefUserDataObject.GetObject: TObject;
//begin
//  Result:= obj;
//end;

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

constructor TRemoveObjectListTask.Create(const auuid: string; aresult: TTaskResult);
begin
  uuid:= auuid;
  result:= aresult;
  inherited Create;
end;

function AddObjectList(obj: TObject): string;
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
  Result:= ObjectList.GetObject(uuid);
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

{ TV8HandlerGlobal }

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
        exception:= '"' + us + '" module dose NOT support requireSync(). Use require().';
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

function Cefv8ValueToCefValue(v8: ICefv8Value): ICefValue;
var
  v1, v2, v3: ICefv8Value;
  i, len: integer;
  sl: TStringList;
  list: ICefListValue;
  dic: ICefDictionaryValue;
  us: ustring;
  s: string;
begin
  Result:= TCefValueRef.New;
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
      list.SetValue(i, Cefv8ValueToCefValue(v8.GetValueByIndex(i)));
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
    //func:= TCefDictionaryValueRef.New;
    //func.SetBool(VTYPE_FUNCTION_NAME, true);
    //// ToDo:
    ////func.SetString('ModuleName', 'child_process');
    ////func.SetString('FuncName', 'subprocess.read');
    //dic:= TCefDictionaryValueRef.New;
    //dic.SetDictionary(v8.GetFunctionName, func);
    //Result.SetDictionary(dic);
  end else if v8.IsObject then begin
    sl:= TStringList.Create;
    try
      v8.GetKeys(sl);
      dic:= TCefDictionaryValueRef.New;
      for i:= 0 to sl.count-1 do begin
        us:= UTF8Decode(sl[i]);
        dic.SetValue(us, Cefv8ValueToCefValue(v8.GetValueByKey(us)));
      end;
      Result.SetDictionary(dic);
    finally
      sl.Free;
    end;
  end;
end;

function Cefv8ArrayToCefList(v8: TCefv8ValueArray): ICefListValue;
var
  i, len: integer;
begin
  Result:= TCefListValueRef.New;
  len:= Length(v8);
  //Result.SetSize(len);
  for i:= 0 to len-1 do begin
    Result.SetValue(i, Cefv8ValueToCefValue(v8[i]));
  end;
end;

function NewV8Object(parent: ICefv8Value; const args: TCefv8ValueArray): ICefv8Value;
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

function NewV8Promise(const name: ustring; handler: ICefv8Handler): ICefv8Value;
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

procedure NewFunction(const code: string; args: ICefListValue; const uid: string);
begin
  CefPostTask(TID_UI, TNewFunctionTask.Create(code, args, uid));
end;

{ TNewFunctionTask }

constructor TNewFunctionTask.Create(const acode: string; aargs: ICefListValue; const auid: string);
begin
  code:= acode;
  args:= aargs;
  uid:= auid;
  inherited Create;
end;

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

  Form1.Chromium.SendProcessMessage(PID_RENDERER, msg);
end;

function NewFunctionV8(const code: string; args: TCefv8ValueArray): ICefv8Value;
begin
  // const F = new Function("...args", code)
  Result:= newV8Object(TCefv8ContextRef.Current.GetGlobal.GetValueByKey('Function'),
    [TCefv8ValueRef.NewString('...args'), TCefv8ValueRef.NewString(UTF8Decode(code))]);
  // result = F(...args)
  Result:= Result.ExecuteFunction(nil, args);
end;

function NewUserObject(obj: TObject): ICefDictionaryValue;
var
  s: string;
begin
  Result:= TCefDictionaryValueRef.New;
  s:= AddObjectList(obj);
  Result.SetString(VTYPE_OBJECT_NAME, UTF8Decode(s));
end;

function NewUserObjectV8(obj: TObject): ICefv8Value;
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

end.

