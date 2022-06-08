unit unit_mod_web_util;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  Variants, unit_js, unit_thread,
  uCEFTypes, uCEFInterfaces, unit_global, LazFileUtils,
  uCEFConstants, uCEFv8Value, uCEFValue, uCefDictionaryValue, uCefBinaryValue,
  uCEFUrlRequestClientComponent, uCEFRequest, uCEFUrlRequest;

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

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
begin
  Result:= False;
  try
    case handler.FuncName of

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
    else
      Exit;
  end;
  Result:= True;
end;

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
    DeleteFile(fileName);
    if RenameFile(fileName + '.tmp', fileName) then complete:= true else error:= 'rename file error';
  end else begin
    DeleteFile(fileName + '.tmp');
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
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', MODULE_NAME);
  func.SetString('FuncName', 'request.read');
  dic.SetDictionary('read', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
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
  bin: ICefBinaryValue;
  wait, waitc: integer;
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

    waitc:= wait div 100;
    while not Self.Terminated and not req.finished and (waitc > 0) do begin
      Sleep(100);
      Dec(waitc);
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

{ TCancelThread }

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

//
const
  _import = G_VAR_IN_JS_NAME + '["' + MODULE_NAME + '"]';
  _body = _import + '.__init__();' +
     'export const downloadFile=' + _import + '.downloadFile;' +
     '';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TDownloadFileThread);
  AddPromiseThreadClass(MODULE_NAME, TReadThread);
  AddPromiseThreadClass(MODULE_NAME, TCancelThread);
end.

