program AppHelper;

{.$DEFINE USE_LUA_MODULE}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  uCEFApplication,
  unit_js,
  unit_mod_fs, unit_mod_util, unit_mod_path, unit_mod_process,
  {$IFDEF USE_LUA_MODULE}
  unit_mod_lua,
  {$ENDIF}
  unit_mod_project;

begin
  GlobalCEFApp:= TCefApplication.Create;

  GlobalCEFApp.OnProcessMessageReceived:= @ProcessMessageReceivedEvent;

  // The main process and the subprocess *MUST* have the same GlobalCEFApp
  // properties and events, specially FrameworkDirPath, ResourcesDirPath,
  // LocalesDirPath, cache and UserDataPath paths.
  {$IFDEF DARWIN}
  GlobalCEFApp.InitLibLocationFromArgs;
  {$ENDIF}

  GlobalCEFApp.StartSubProcess;
  GlobalCEFApp.Free;
  GlobalCEFApp:= nil;
end.

