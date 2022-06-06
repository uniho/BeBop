unit unit_mod_fs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  unit_global, LazFileUtils, unit_js, unit_thread,
  uCEFTypes, uCEFInterfaces, uCEFConstants, uCEFv8Context, uCEFv8Value, uCEFValue,
  uCEFListValue, uCefDictionaryValue, uCefBinaryValue, uCefv8ArrayBufferReleaseCallback;

const
  MODULE_NAME = 'fs'; //////////

type

  { TRequireThread }

  TRequireThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function importCreate(const name: string): ICefv8Value;
var
  handler: ICefv8Handler;
begin
  Result:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'mkdir');
  Result.SetValueByKey('mkdir',
   TCefv8ValueRef.NewFunction('mkdir', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'open');
  Result.SetValueByKey('open',
   TCefv8ValueRef.NewFunction('open', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'readdir');
  Result.SetValueByKey('readdir',
   TCefv8ValueRef.NewFunction('readdir', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'rename');
  Result.SetValueByKey('rename',
   TCefv8ValueRef.NewFunction('rename', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'rm');
  Result.SetValueByKey('rm',
   TCefv8ValueRef.NewFunction('rm', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'stat');
  Result.SetValueByKey('stat',
   TCefv8ValueRef.NewFunction('stat', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'readFile');
  Result.SetValueByKey('readFile',
   TCefv8ValueRef.NewFunction('readFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'writeFile');
  Result.SetValueByKey('writeFile',
   TCefv8ValueRef.NewFunction('writeFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);
end;

//
function requireCreate(const name: ustring; const obj: ICefv8Value;
  const arguments: TCefv8ValueArray; var retval: ICefv8Value;
  var exception: ustring): Boolean;
var
  handler: ICefv8Handler;
begin
  retval:= TCefv8ValueRef.NewObject(nil, nil);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'mkdir');
  retval.SetValueByKey('mkdir',
   TCefv8ValueRef.NewFunction('mkdir', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'open');
  retval.SetValueByKey('open',
   TCefv8ValueRef.NewFunction('open', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'readdir');
  retval.SetValueByKey('readdir',
   TCefv8ValueRef.NewFunction('readdir', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'rename');
  retval.SetValueByKey('rename',
   TCefv8ValueRef.NewFunction('rename', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'rm');
  retval.SetValueByKey('rm',
   TCefv8ValueRef.NewFunction('rm', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'stat');
  retval.SetValueByKey('stat',
   TCefv8ValueRef.NewFunction('stat', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'readFile');
  retval.SetValueByKey('readFile',
   TCefv8ValueRef.NewFunction('readFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);

  handler:= TV8HandlerSafe.Create(UTF8Encode(name), 'writeFile');
  retval.SetValueByKey('writeFile',
   TCefv8ValueRef.NewFunction('writeFile', handler), V8_PROPERTY_ATTRIBUTE_NONE);

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

  { TStatThread }

  TStatThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TReaddirThread }

  TReaddirThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TMkDirThread }

  TMkDirThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TRenameThread }

  TRenameThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TRmThread }

  TRmThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TOpenThread }

  TOpenThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TSizeThread }

  TSizeThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TSeekThread }

  TSeekThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TWriteFileThread }

  TWriteFileThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TCloseThread }

  TCloseThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TReadFileThread }

  TReadFileThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TReadThread }

  TReadThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

  { TWriteThread }

  TWriteThread = class(TPromiseThread)
  protected
    procedure ExecuteAct; override;
  public
  end;

//
function safeExecute(const handler: TV8HandlerSafe; const name: ustring;
  const obj: ICefv8Value; const arguments: TCefv8ValueArray;
  var retval: ICefv8Value; var exception: ustring): Boolean;
var
  v1: ICefv8Value;
begin
  Result:= False;
  case handler.FuncName of
    'filehandle.close',
    'filehandle.read',
    'filehandle.write',
    'filehandle.seek',
    'filehandle.size',
    'mkdir',
    'open',
    'readFile',
    'readdir',
    'rename',
    'rm',
    'stat',
    'writeFile': begin
      // res = (arg, ...) => new Promise((resolve, reject) => {...})
      retval:= NewV8Promise(name, TV8HandlerCallback.Create(handler.ModuleName, handler.FuncName, arguments, obj));
    end;

    'dirent.isDirectory': begin
      v1:= obj.GetValueByKey('attr');
      retval:= TCefv8ValueRef.NewBool(v1.GetIntValue and faDirectory <> 0);
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
    'filehandle.close': begin
      StartPromiseThread(TCloseThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'filehandle.read': begin
      StartPromiseThread(TReadThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'filehandle.write': begin
      StartPromiseThread(TWriteThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'filehandle.seek': begin
      StartPromiseThread(TSeekThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'filehandle.size': begin
      StartPromiseThread(TSizeThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'mkdir': begin
      StartPromiseThread(TMkDirThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'open': begin
      StartPromiseThread(TOpenThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'readFile': begin
      StartPromiseThread(TReadFileThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'readdir': begin
      StartPromiseThread(TReaddirThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'rename': begin
      StartPromiseThread(TRenameThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'rm': begin
      StartPromiseThread(TRmThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'stat': begin
      StartPromiseThread(TStatThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    'writeFile': begin
      StartPromiseThread(TWriteFileThread, Args, arguments[0], arguments[1], ModuleName, FuncName, CefObject);
    end;
    else
      Exit;
  end;
  Result:= True;
end;


{ TSizeThread }

procedure TSizeThread.ExecuteAct;
var
  fs: TFileStream;
  dic: ICefDictionaryValue;
  offset: Int64;
begin
  //if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  fs:= TFileStream(GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME))));
  if not Assigned(fs) or not(fs is TFileStream) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  offset:= fs.Seek(Int64(0), 2);
  if offset = -1 then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  fs.Seek(0, 0);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(offset); // ToDo: BigInt
end;


{ TSeekThread }

procedure TSeekThread.ExecuteAct;
var
  fs: TFileStream;
  dic: ICefDictionaryValue;
  origin: integer;
  offset: Int64;
begin
  //if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  fs:= TFileStream(GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME))));
  if not Assigned(fs) or not(fs is TFileStream) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  offset:= 0;
  if Args.GetSize > 0 then begin
    if Args.GetType(0) = VTYPE_INT then begin
      offset:= Args.GetInt(0);
    end else begin
      // ToDo: BigInt
    end;
  end;

  origin:= 0;
  if Args.GetSize > 1 then begin
    origin:= Args.GetInt(1);
  end;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetInt(fs.Seek(offset, origin)); // ToDo: BigInt
end;


{ TWriteThread }

procedure TWriteThread.ExecuteAct;
var
  fs: TFileStream;
  dic: ICefDictionaryValue;
  buffer: PByte;
  s: string;
begin
  //if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  fs:= TFileStream(GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME))));
  if not Assigned(fs) or not(fs is TFileStream) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  if Args.GetSize > 0 then begin
    if Args.GetType(0) = VTYPE_BINARY then begin
      buffer:= GetMem(Args.GetBinary(0).Size);
      try
        Args.GetBinary(0).GetData(buffer, Args.GetBinary(0).Size, 0);
        fs.Write(buffer^, Args.GetBinary(0).Size);
      finally
        FreeMem(buffer);
      end;
    end else begin
      // write as UTF8
      s:= UTF8Encode(Args.GetString(0));
      fs.Write(s[1], Length(s));
    end;
  end;
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;


{ TReadThread }

procedure TReadThread.ExecuteAct;
var
  fs: TFileStream;
  dic: ICefDictionaryValue;
  buffer: string;
  bin: ICefBinaryValue;
  read_length, bytesRead: integer;
begin
  //if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  fs:= TFileStream(GetObjectList(UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME))));
  if not Assigned(fs) or not(fs is TFileStream) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  read_length:= 0;
  if Args.GetSize > 0 then begin
    read_length:= Args.GetInt(0);
  end;
  if read_length <= 0 then read_length:= 16384;

  SetLength(buffer{%H-}, read_length);
  bytesRead:= fs.Read(buffer[1], read_length);
  CefResolve:= TCefValueRef.New;
  if bytesRead > 0 then begin
    bin:= TCefBinaryValueRef.New(@buffer[1], bytesRead);
    CefResolve.SetBinary(bin);
  end else begin
    CefResolve.SetNull;
  end;
end;


{ TReadFileThread }

procedure TReadFileThread.ExecuteAct;
var
  fileName, flag, data: string;
  options: ICefDictionaryValue;
  codepage: integer;
  mode: integer;
  fs: TFileStream;
  bin: ICefBinaryValue;
  len: Int64;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);

  options:= nil;
  if Args.GetSize > 1 then begin
    options:= Args.GetDictionary(1);
  end;

  flag:= 'r';
  mode:= fmOpenRead;
  if Assigned(options) and options.HasKey('flag') then begin
    flag:= UTF8Encode(options.GetString('flag'));
  end;

  codepage:= 65001{utf-8};
  if Assigned(options) and options.HasKey('codePage') then begin
    codePage:= options.GetInt('codePage');
  end;

  fs:= TFileStream.Create(fileName, mode);
  try
    len:= fs.Size;
    if len > MaxInt then Raise Exception.Create(ERROR_OVER_THE_LIMIT);
    SetLength(data{%H-}, len);
    fs.Read(data[1], len);
    if codepage = 0 then begin
      bin:= TCefBinaryValueRef.New(@data[1], len);
      CefResolve:= TCefValueRef.New;
      CefResolve.SetBinary(bin)
    end else begin
      SetCodePage(RawByteString(data), codepage, false);
      SetCodePage(RawByteString(data), 65001{utf-8}, true);
      CefResolve:= TCefValueRef.New;
      CefResolve.SetString(UTF8Decode(data));
    end;
  finally
    fs.Free;
  end;
end;


{ TCloseThread }

procedure TCloseThread.ExecuteAct;
var
  fs: TFileStream;
  dic: ICefDictionaryValue;
  uuid: string;
begin
  //if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dic:= CefObject.GetDictionary;
  if not Assigned(dic) or not dic.IsValid then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);
  uuid:= UTF8Encode(dic.GetString(VTYPE_OBJECT_NAME));
  fs:= TFileStream(GetObjectList(uuid));
  if not Assigned(fs) or not(fs is TFileStream) then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  RemoveObjectList(uuid);
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;


{ TWriteFileThread }

procedure TWriteFileThread.ExecuteAct;
var
  fileName, flag, data: string;
  options: ICefDictionaryValue;
  mode: integer;
  h: THandle;
begin
  if Args.GetSize < 2 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);

  if Args.GetType(1) = VTYPE_BINARY then begin
    if Args.GetBinary(1).Size > MaxInt then
      Raise Exception.Create(ERROR_OVER_THE_LIMIT);
    SetLength(data, Args.GetBinary(1).Size);
    Args.GetBinary(1).GetData(@data[1], Args.GetBinary(1).Size, 0);
  end else begin
    // write as UTF8
    data:= UTF8Encode(Args.GetString(1));
  end;

  options:= nil;
  if Args.GetSize > 2 then begin
    options:= Args.GetDictionary(2);
  end;

  flag:= 'w';
  mode:= fmOpenWrite;
  if Assigned(options) and options.HasKey('flag') then begin
    flag:= UTF8Encode(options.GetString('flag'));
  end;

  if FileExists(fileName) then begin
    h:= FileOpen(fileName, mode);
  end else begin
    h:= FileCreate(fileName);
  end;
  if h = feInvalidHandle then
    Raise Exception.Create(ERROR_INVALID_HANDLE_VALUE);

  try
    if Length(data) > 0 then begin
      FileWrite(h, data[1], Length(data));
    end;
  finally
    FileClose(h);
  end;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(true);
end;


{ TOpenThread }

procedure TOpenThread.ExecuteAct;
var
  fileName, flags: string;
  mode: integer;
  fs: TFileStream;
  option, dic, func: ICefDictionaryValue;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);
  flags:= 'r';
  mode:= fmOpenRead;
  if Args.GetSize > 1 then begin
    flags:= UTF8Encode(Args.GetString(1));
  end;
  case flags of
    'r': mode:= fmOpenRead;
    'r+': mode:= fmOpenReadWrite;
    'w', 'w+': begin
      if FileExists(fileName) then begin
        mode:= fmOpenReadWrite;
      end else begin
        mode:= fmCreate;
      end;
    end;
  end;
  fs:= TFileStream.Create(fileName, mode);

  dic:= NewUserObject(fs);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'fs');
  func.SetString('FuncName', 'filehandle.close');
  dic.SetDictionary('close', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'fs');
  func.SetString('FuncName', 'filehandle.read');
  dic.SetDictionary('read', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'fs');
  func.SetString('FuncName', 'filehandle.write');
  dic.SetDictionary('write', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'fs');
  func.SetString('FuncName', 'filehandle.seek');
  dic.SetDictionary('seek', func);

  func:= TCefDictionaryValueRef.New;
  func.SetBool(VTYPE_FUNCTION_NAME, true);
  func.SetString('ModuleName', 'fs');
  func.SetString('FuncName', 'filehandle.size');
  dic.SetDictionary('size', func);

  CefResolve:= TCefValueRef.New;
  CefResolve.SetDictionary(dic);
end;


{ TRmThread }

procedure TRmThread.ExecuteAct;

  function remove(const fileName: string; recursive: boolean): boolean;
  var
    searchRec: TSearchRec;
  begin
    Result:= False;
    if FileExists(fileName) then begin
      Result:= DeleteFile(fileName);
      exit;
    end else if (DirectoryExists(fileName)) then begin
      if not recursive then begin
        Result:= RemoveDir(fileName);
        exit;
      end;
      if FindFirst(IncludeTrailingPathDelimiter(fileName) + '*', faAnyFile, searchRec) = 0 then begin
        try
          repeat
            if not ((searchRec.Name = '..') or (searchRec.Name = '.')) then begin
              if (searchRec.Attr and faDirectory <> 0) then begin
                Result:= remove(IncludeTrailingPathDelimiter(fileName)+searchRec.Name, true);
                if not Result then exit;
              end else begin
                Result:= DeleteFile(IncludeTrailingPathDelimiter(fileName)+searchRec.Name);
                if not Result then exit;
              end;
            end;
          until (FindNext(searchRec) <> 0) or Terminated;
        finally
          FindClose(searchRec);
        end;
      end;
      Result:= RemoveDir(fileName);
    end;
  end;

var
  fileName: string;
  option: ICefDictionaryValue;
  b: boolean;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);
  option:= nil;
  if Args.GetSize > 1 then begin
    option:= Args.GetDictionary(1);
  end;
  b:= not Terminated and remove(fileName, Assigned(option) and option.GetBool('recursive'));
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(b);
end;


{ TRenameThread }

procedure TRenameThread.ExecuteAct;
var
  fileName1, fileName2: string;
  b: boolean;
begin
  if Args.GetSize < 2 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName1:= UTF8Encode(Args.GetString(0));
  if fileName1 = '' then fileName1:= '.';
  fileName1:= CreateAbsolutePath(fileName1, dogRoot);
  fileName2:= UTF8Encode(Args.GetString(1));
  if fileName2 = '' then fileName2:= '.';
  fileName2:= CreateAbsolutePath(fileName2, dogRoot);
  b:= RenameFile(fileName1, fileName2);
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(b);
end;


{ TMkdirThread }

procedure TMkdirThread.ExecuteAct;
var
  dirName: string;
  option: ICefDictionaryValue;
  b: boolean;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  dirName:= UTF8Encode(Args.GetString(0));
  if dirName = '' then dirName:= '.';
  dirName:= CreateAbsolutePath(dirName, dogRoot);
  if Args.GetSize > 1 then begin
    option:= Args.GetDictionary(1);
    if option.GetBool('recursive') then begin
      b:= ForceDirectories(dirName);
      CefResolve:= TCefValueRef.New;
      CefResolve.SetBool(b);
      exit;
    end;
  end;
  b:= CreateDir(dirName);
  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(b);
end;


{ TStatThread }

procedure TStatThread.ExecuteAct;
var
  fileName: string;
  searchRec: TSearchRec;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);
  if FindFirst(fileName, faAnyFile, searchRec) = 0 then begin
    FindClose(searchRec);
  end else begin
    fileName:= IncludeTrailingPathDelimiter(fileName) + '*';
    if FindFirst(fileName, faDirectory, searchRec) = 0 then begin
      repeat
        if searchRec.Name = '.' then break;
      until (FindNext(searchRec) <> 0) or Terminated;
      FindClose(searchRec);
    end else begin
      CefReject:= TCefValueRef.New;
      CefReject.SetString(ERROR_ENOENT);
      exit;
    end;
  end;

  CefResolve:= TCefValueRef.New;
  CefResolve.SetBool(True); // ToDo: fs.Stat Object
end;


{ TReaddirThread }

procedure TReaddirThread.ExecuteAct;
var
  i: integer;
  fileName: string;
  searchRec: TSearchRec;
  list: ICefListValue;
  dic, func: ICefDictionaryValue;
begin
  if Args.GetSize < 1 then Raise Exception.Create(ERROR_INVALID_PARAM_COUNT);
  list:= TCefListValueRef.New;
  i:= 0;
  fileName:= UTF8Encode(Args.GetString(0));
  if fileName = '' then fileName:= '.';
  fileName:= CreateAbsolutePath(fileName, dogRoot);
  fileName:= IncludeTrailingPathDelimiter(fileName) + '*';
  if FindFirst(fileName, faAnyFile, searchRec) = 0 then begin
    repeat
      if not ((searchRec.Name = '..') or (searchRec.Name = '.')) then begin
        inc(i);
        list.SetSize(i);

        // Set fs.Dirent type.
        dic:= TCefDictionaryValueRef.New;
        dic.SetString('name', UTF8Decode(searchRec.Name));
        dic.SetInt('attr', searchRec.Attr);

        func:= TCefDictionaryValueRef.New;
        func.SetBool(VTYPE_FUNCTION_NAME, true);
        func.SetString('ModuleName', 'fs');
        func.SetString('FuncName', 'dirent.isDirectory');
        dic.SetDictionary('isDirectory', func);

        list.SetDictionary(i-1, dic);
      end;
    until (FindNext(searchRec) <> 0) or Terminated;
    FindClose(searchRec);

    CefResolve:= TCefValueRef.New;
    CefResolve.SetList(list);
  end else begin
    CefReject:= TCefValueRef.New;
    CefReject.SetString(ERROR_ENOENT);
  end;
end;

//
const
  _import = G_VAR_IN_JS_NAME + '["' + MODULE_NAME + '"]';
  _body = _import + '.__init__();' +
     'export const mkdir=' + _import + '.mkdir;' +
     'export const open=' + _import + '.open;' +
     'export const readdir=' + _import + '.readdir;' +
     'export const rename=' + _import + '.rename;' +
     'export const rm=' + _import + '.rm;' +
     'export const stat=' + _import + '.stat;' +
     'export const readFile=' + _import + '.readFile;' +
     'export const writeFile=' + _import + '.writeFile;' +
     '';

initialization
  // Regist module handler
  AddModuleHandler(MODULE_NAME, @requireCreate, @requireExecute, @safeExecute); // DEPRECATED
  AddModuleHandler(MODULE_NAME, _body, @importCreate, @safeExecute);

  // Regist TPromiseThread class
  AddPromiseThreadClass(MODULE_NAME, TRequireThread); // DEPRECATED
  AddPromiseThreadClass(MODULE_NAME, TMkdirThread);
  AddPromiseThreadClass(MODULE_NAME, TCloseThread);
  AddPromiseThreadClass(MODULE_NAME, TOpenThread);
  AddPromiseThreadClass(MODULE_NAME, TReadThread);
  AddPromiseThreadClass(MODULE_NAME, TReadFileThread);
  AddPromiseThreadClass(MODULE_NAME, TReaddirThread);
  AddPromiseThreadClass(MODULE_NAME, TRenameThread);
  AddPromiseThreadClass(MODULE_NAME, TRmThread);
  AddPromiseThreadClass(MODULE_NAME, TSizeThread);
  AddPromiseThreadClass(MODULE_NAME, TSeekThread);
  AddPromiseThreadClass(MODULE_NAME, TStatThread);
  AddPromiseThreadClass(MODULE_NAME, TWriteThread);
  AddPromiseThreadClass(MODULE_NAME, TWriteFileThread);
end.

