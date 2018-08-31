{
    MIT License

    Copyright (c) 2018 noism

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
}

{$MODE OBJFPC}

uses windows, sysutils;

const
  kernel32 = 'kernel32.dll';
  AWSuffix= 'A';

type
  PPROCESSENTRY32 = ^PROCESSENTRY32;
  {$EXTERNALSYM PPROCESSENTRY32}
  tagPROCESSENTRY32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;          // this process
    th32DefaultHeapID: ULONG_PTR;
    th32ModuleID: DWORD;           // associated exe
    cntThreads: DWORD;
    th32ParentProcessID: DWORD;    // this process's parent process
    pcPriClassBase: LONG;          // Base priority of process's threads
    dwFlags: DWORD;
    szExeFile: array [0..MAX_PATH - 1] of Char;    // Path
  end;
  {$EXTERNALSYM tagPROCESSENTRY32}
  PROCESSENTRY32 = tagPROCESSENTRY32;
  {$EXTERNALSYM PROCESSENTRY32}
  LPPROCESSENTRY32 = ^PROCESSENTRY32;
  {$EXTERNALSYM LPPROCESSENTRY32}
  TProcessEntry32 = PROCESSENTRY32;

const
   TH32CS_SNAPPROCESS  = $00000002;


function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): HANDLE; stdcall; external kernel32 name 'CreateToolhelp32Snapshot';
function Process32Next(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall; external kernel32 name 'Process32Next';
function Process32First(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall; external kernel32 name 'Process32First';
function QueryFullProcessImageNameA(hProcess: HANDLE; dwFlags: DWORD; lpExeName: PChar; var dwsize: DWORD): BOOL; stdcall; external kernel32 name 'QueryFullProcessImageNameA';

const currentTestFolderPtr1 = $18BC10;  // 1.7.6.144
      currentTestFolderPtr2 = $12BF58; // 1.9.6.2331
      target = 'bai1';

type
   themisVersion = record
      major, minor, build, revision: DWORD;
   end;

function VersionIdentical(ver: themisversion; major, minor, build, revision: DWORD): boolean;
begin
    if ((ver.major = major) and (ver.minor = minor) and (ver.build = build) and (ver.revision = revision)) then
       exit(true);

    exit(false);
end;

function GetThemisTestPointerFromver(ver: themisVersion): DWORD;
begin
    // This address is not stable
    if VersionIdentical(ver, 1, 7, 6, 744) then
       exit(currentTestFolderPtr1);

    if (VersionIdentical(ver, 1, 9, 6, 2331)) then
       exit(currentTestFolderPtr2);

    exit(0);
end;

function GetThemisVersion(path: AnsiString): themisVersion;
type FILEINFOPTR = ^VS_FIXEDFILEINFO;
var verSize, verHandle: DWORD;
    puLenFileInfo: DWORD;
    verData: array of BYTE;
    fileInfoP: FILEINFOPTR;
    fileInfo: VS_FIXEDFILEINFO;
begin
        versize := GetFileVersionInfoSize(@path[1], verHandle);

        if (versize > 0) then
        begin
            SetLength(verData, verSize);

            if GetFileVersionInfo(@path[1], verHandle, verSize, @verData[0]) then
            begin
                if (VerQueryValue(@verData[0], '\', @fileInfoP, @puLenFileInfo)) then
                begin
                    fileInfo := fileInfoP^;

                    if (puLenFileInfo > 0) and (fileInfo.dwSignature = $feef04bd)
                    then
                    begin
                        GetThemisversion.major := (fileInfo.dwFileversionMS shr 16) and $FFFF;
                        GetThemisversion.minor := (fileInfo.dwFileversionMS shr 0) and $FFFF;
                        GetThemisversion.build := (fileInfo.dwFileversionLS shr 16) and $FFFF;
                        GetThemisversion.revision := (fileInfo.dwFileversionLS shr 0) and $FFFF;

                        exit;
                   end;
                end;
            end;
        end;

        raise Exception.Create('Cannot get the version of Themis');
end;


function GetThemisCurrentTest(var path: UnicodeString): boolean;
var entry: TProcessEntry32;
    snapshot, themisprocess: THandle;
    pathReadSucc, found: boolean;
    buffer: packed array[0..300] of char;
    bytesRead, strsize, tfp: DWord;
    ver: ThemisVersion;
    fullPath: AnsiString;
    fullPathBuf: packed array[0..1000] of char;
begin
    found:=false;

    entry.dwSize := sizeof(TProcessEntry32);
    snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (Process32First(snapshot, entry) = TRUE) then
    begin
        while (Process32Next(snapshot, entry) = TRUE) do
        begin
            if (AnsiString(entry.szExeFile) =  'Themis.exe')  then
            begin
                themisprocess := OpenProcess(PROCESS_ALL_ACCESS,
                    FALSE, entry.th32ProcessID);

                strsize:=1000;

                if (QueryFullProcessImageNameA(themisprocess, 0,@fullPathBuf[0],
                        strsize)) then
                     fullPath := AnsiString(fullPathBuf);

                ver := GetThemisVersion(fullPath);

                tfp:=GetThemisTestPointerFromVer(ver);

                pathReadSucc := ReadProcessMemory(themisprocess, Pointer(tfp),
                    @buffer, 200, bytesRead);

                if (pathReadSucc) then
                begin
                    SetString(path, PWideChar(@buffer[0]), bytesRead div 2);
                    GetThemisCurrentTest := true;
                    found := true;
                end else
                    GetThemisCurrentTest := false;

                CloseHandle(themisprocess);
            end;
        end;
    end;

    CloseHandle(snapshot);
    exit(found);
end;

var themisPath, themisCurrentTestCaseClean, themisCurrentTestCase: UnicodeString;
    themisUtf8TestPath : Utf8String;
    themisTest: TextFile;
    temp: ansistring;
    i: longint;

begin
        GetThemisCurrentTest(themisCurrentTestCase);

        i:=1;

        while ((ord(themisCurrentTestCase[i]) > 0) and
            (i <= length(themisCurrentTestCase))) do
        begin
                themisCurrentTestCaseClean := themisCurrentTestCaseClean + themisCurrentTestCase[i];
                i:=i+1;
        end;

        themisUtf8TestPath :=
           Utf8String(themisCurrentTestCaseClean) + '\' + target + '.OUT';

        assign(themisTest, themisUtf8TestPath); reset(themisTest);
        assign(output, target + '.out'); rewrite(output);

        while not eof(themisTest) do
        begin
                readln(themisTest, temp);
                writeln(temp);
        end;
end.
