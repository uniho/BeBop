unit unit_mod_child_process;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  unit_global, LazFileUtils, Process, unit_thread, unit_js,
  uCEFTypes, uCEFInterfaces, uCEFConstants, uCEFv8Context, uCEFv8Value, uCEFValue,
  uCefDictionaryValue;

const
  MODULE_NAME = 'child_process'; //////////

type

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
  handler: ICefv8Handler;
begin
  retval:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'execFile');
  retval.SetValueByKey('execFile',
   TCefv8ValueRef.NewFunction('execFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  Result:= True;
end;

//
function requireExecute(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  v, g: ICefv8Value;
  uuid: string;
begin
  // (resolve, reject) => {...}

  Result:= requireCreate(name, obj, arguments, retval, exception);
  if not Result or (exception <> '') then Exit;

  uuid:= StartPromiseThread(TRequireThread,
    [], arguments[0], arguments[1], MODULE_NAME, 'require');
  g:= TCefv8ContextRef.Current.GetGlobal;
  v:= g.GetValueByKey(G_VAR_IN_JS_NAME).GetValueByKey('_ipc').GetValueByKey(UTF8Decode(uuid));
  v.SetValueByKey('resolve_args', retval, V8_PROPERTY_ATTRIBUTE_NONE);

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

  { TExecFileThread }

  TExecFileThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TReadThread }

  TReadThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TCloseThread }

  TCloseThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TIsRunningThread }

  TIsRunningThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  end;

  { TProcessObject }

  TProcessObject = class(TObject)
  public
    process: TProcess;
    constructor Create(aprocess: TProcess);
    destructor Destroy; override;
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;

  {$IFDEF CEF_SINGLE_PROCESS}
  function closeSync: ICefv8Value;
  var
    uuid: string;
    o: TObject;
  begin
    if not Assigned(obj) or not obj.HasValueByKey(VTYPE_OBJECT_NAME) then
      Raise SysUtils.Exception.Create(ERROR_INVALID_HANDLE_VALUE);
    uuid:= UTF8Encode(obj.GetValueByKey(VTYPE_OBJECT_NAME).GetStringValue);
    o:= GetObjectList(uuid);
    if not Assigned(o) or not(o is TProcessObject) then
      Raise SysUtils.Exception.Create(ERROR_INVALID_HANDLE_VALUE);

    RemoveObjectList(uuid);

    Result:= TCefv8ValueRef.NewBool(true);
  end;
  {$ENDIF}

begin
  Result:= False;
  case handler.FuncName of
    'subprocess.read',
    'subprocess.close',
    'subprocess.isRunning',
    'execFile': begin
      // res = (arg, ...) => new Promise(resolve => {...})
      retval:= newV8Promise(name, TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
    end;

    {$IFDEF CEF_SINGLE_PROCESS}
    'subprocess.closeSync': begin
      retval:= closeSync;
    end;
    {$ENDIF}

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
    'execFile': begin
      StartPromiseThread(TExecFileThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'subprocess.read': begin
      StartPromiseThread(TReadThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'subprocess.close': begin
      StartPromiseThread(TCloseThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'subprocess.isRunning': begin
      StartPromiseThread(TIsRunningThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;


{ TExecFileThread }

procedure TExecFileThread.ExecuteAct;
var
  s: string;
  i, len, exitStatus: integer;
  pro: TProcess;
  codePage: integer;
  argList: ICefListValue;
  option, dic, func: ICefDictionaryValue;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);

  argList:= nil;
  if (Args.GetSize > 1) then begin
    argList:= Args.GetList(1);
  end;

  option:= nil;
  if (Args.GetSize > 2) then begin
    option:= Args.GetDictionary(2);
  end;

  codePage:= 0;
  if Assigned(option) then begin
    codePage:= option.GetInt('codePage');
  end;

  pro:= TProcess.Create(nil);

  s:= UTF8Encode(Args.GetString(0));
  if s = '' then exit;
  s:= CreateAbsolutePath(s, execPath);
  if codePage > 0 then begin
    SetCodePage(RawByteString(s), codePage, true);
  end;
  pro.Executable:= s;

  if Assigned(argList) then begin
    len:= argList.GetSize;
    for i:= 0 to len-1 do begin
      s:= UTF8Encode(argList.GetString(i));
      if codePage > 0 then begin
        SetCodePage(RawByteString(s), codePage, true);
      end;
      pro.Parameters.Add(s);
    end;
  end;

  pro.Options:= pro.Options + [poNoConsole, poUsePipes];
  if Assigned(option) then begin
    {$IFDEF Windows}
    if option.GetBool('windowsHide') = false then
      pro.Options:= pro.Options - [poNoConsole, poUsePipes];
    {$ENDIF}
  end;

  pro.Execute;

  exitStatus:= 0;
  if not (poUsePipes in pro.Options) then begin
    while pro.Running do begin
      if Self.Terminated then begin
        pro.Terminate(0);
        Break;
      end;
    end;
    exitStatus:= pro.ExitStatus;
  end;

  dic:= NewUserObject(TProcessObject.Create(pro));
  dic.SetInt('status', exitStatus);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'child_process');
  func.SetString('FuncName', 'subprocess.read');
  dic.SetDictionary('read', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'child_process');
  func.SetString('FuncName', 'subprocess.close');
  dic.SetDictionary('close', func);

  {$IFDEF CEF_SINGLE_PROCESS}
  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'child_process');
  func.SetString('FuncName', 'subprocess.closeSync');
  dic.SetDictionary('closeSync', func);
  {$ENDIF}

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'child_process');
  func.SetString('FuncName', 'subprocess.isRunning');
  dic.SetDictionary('isRunning', func);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetDictionary(dic);
end;

{ TReadThread }

procedure TReadThread.ExecuteAct;
var
  OutputString, StdErrString: string;
  obj: TObject;
  pro: TProcess;
  anExitStatus, len: integer;
  option, dic: ICefDictionaryValue;
  wait, waitc: integer;
  available1, available2: boolean;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  obj:= GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME)));
  if not Assigned(obj) or not(obj is TProcessObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  pro:= TProcessObject(obj).process;

  OutputString:= '';
  StdErrString:= '';
  anExitStatus:= 0;
  try
    option:= nil;
    wait:= 1000;
    if (Args.GetSize > 1) then begin
      option:= Args.GetDictionary(1);
      if option.HasKey('wait') then begin
        wait:= option.GetInt('wait');
      end;
    end;
    if wait < 100 then wait:= 100;

    if not Self.Terminated and (poUsePipes in pro.Options) then begin
      if pro.Running then begin
        // Only call ReadFromStream if Data from corresponding stream
        // is already available, otherwise, on  linux, the read call
        // is blocking, and thus it is not possible to be sure to handle
        // big data amounts bboth on output and stderr pipes. PM.
        len:= pro.output.NumBytesAvailable;
        available1:= len > 0;
        if available1 then begin
          //available1:= pro.ReadInputStream(pro.output,BytesRead,OutputLength,OutputString,1);
          try
            SetLength(OutputString, len);
            len:= pro.output.Read(OutputString[1], len);
            SetLength(OutputString, len);
          except
            OutputString:= '';
          end;
        end;

        // The check for assigned(P.stderr) is mainly here so that
        // if we use poStderrToOutput in p.Options, we do not access invalid memory.
        available2:= not Self.Terminated and assigned(pro.stderr) and (pro.stderr.NumBytesAvailable > 0);
        if available2 then begin
          //  available2:= pro.ReadInputStream(pro.StdErr,StdErrBytesRead,StdErrLength,StdErrString,1);
          try
            len:= pro.stderr.NumBytesAvailable;
            SetLength(StdErrString, len);
            len:= pro.stderr.Read(StdErrString[1], len);
            SetLength(StdErrString, len);
          except
            StdErrString:= '';
          end;
        end;

        if not available1 and not available2 then begin
          waitc:= wait div 100;
          while not Self.Terminated and (waitc > 0) do begin
            Sleep(100);
            Dec(waitc);
          end;
        end;

      end else begin
        anExitStatus:= pro.exitstatus;
        // Get left output after end of execution
        //pro.ReadInputStream(pro.output,BytesRead,OutputLength,OutputString,1);
        len:= pro.output.NumBytesAvailable;
        if len > 0 then begin
          try
            SetLength(OutputString, len);
            len:= pro.output.Read(OutputString[1], len);
            SetLength(OutputString, len);
          except
            OutputString:= '';
          end;
        end;
        if assigned(pro.stderr) and not Self.Terminated and (pro.stderr.NumBytesAvailable > 0) then begin
          //pro.ReadInputStream(pro.StdErr,StdErrBytesRead,StdErrLength,StdErrString,1);
          try
            len:= pro.stderr.NumBytesAvailable;
            SetLength(StdErrString, len);
            len:= pro.stderr.Read(StdErrString[1], len);
            SetLength(StdErrString, len);
          except
            StdErrString:= '';
          end;
        end;
      end;
    end;

  finally
    dic:= TCefDictionaryValueRef.New;
    dic.SetString('stdout', UTF8Decode(OutputString));
    dic.SetString('stderr', UTF8Decode(StdErrString));
    dic.SetInt('status', anExitStatus);
    CefResolve:= TCefValueRef.New;
    CefResolve.SetDictionary(dic);
  end;
end;

{ TCloseThread }

procedure TCloseThread.ExecuteAct;
var
  obj: TObject;
  //pro: TProcess;
  dic: ICefDictionaryValue;
  uuid: string;
  taskResult: TTaskResult;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  uuid:= UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME));
  obj:= GetObjectList(uuid);
  if not Assigned(obj) or not(obj is TProcessObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  //pro:= TProcessObject(obj).process;

  //pro.Terminate(0);
  //pro.WaitOnExit;
  //while pro.Running do;

  taskResult:= TTaskResult.Create;
  try
    RemoveObjectListResult(uuid, taskResult);
    while Integer(taskResult.result) = 0 do;
  finally
    taskResult.Free;
  end;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True);
end;

{ TIsRunningThread }

procedure TIsRunningThread.ExecuteAct;
var
  obj: TObject;
  pro: TProcess;
  dic: ICefDictionaryValue;
  uuid: string;
begin
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  uuid:= UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME));
  obj:= GetObjectList(uuid);
  if not Assigned(obj) or not(obj is TProcessObject) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  pro:= TProcessObject(obj).process;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(
    pro.Running or ((poUsePipes in pro.Options) and (pro.output.NumBytesAvailable > 0) or
    (Assigned(pro.stderr) and (pro.StdErr.NumBytesAvailable > 0)))
  );
end;

{ TProcessObject }

constructor TProcessObject.Create(aprocess: TProcess);
begin
  process:= aprocess;
end;

destructor TProcessObject.Destroy;
begin
  process.Terminate(0);
  process.WaitOnExit;
  process.Free;
  inherited Destroy;
end;


initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread);
  AddPromiseThreadClass(MODULE_NAME, TExecFileThread);
  AddPromiseThreadClass(MODULE_NAME, TReadThread);
  AddPromiseThreadClass(MODULE_NAME, TCloseThread);
  AddPromiseThreadClass(MODULE_NAME, TIsRunningThread);
end.

