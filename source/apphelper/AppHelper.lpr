
program AppHelper;

{$mode objfpc}{$H+}

{$I cef.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  unit_js,
  uCEFApplication, uCEFTypes, uCEFConstants, LazFileUtils, sysutils;

begin
  GlobalCEFApp:= TCefApplication.Create;

  GlobalCEFApp.OnProcessMessageReceived:= @ProcessMessageReceivedEvent;

  // The main process and the subprocess *MUST* have the same GlobalCEFApp
  // properties and events, specially FrameworkDirPath, ResourcesDirPath,
  // LocalesDirPath, cache and UserDataPath paths.
  {$IFDEF MACOSX}
  GlobalCEFApp.InitLibLocationFromArgs;
  {$ENDIF}

  GlobalCEFApp.StartSubProcess;
  GlobalCEFApp.Free;
  GlobalCEFApp:= nil;
end.

