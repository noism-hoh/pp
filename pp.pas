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

uses windows;

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


const currentTestFolderPtr = $12BF58;
      target = 'BAI1';

function GetThemisCurrentTest(var path: UnicodeString): boolean;
var entry: TProcessEntry32;
    snapshot, themisprocess: THandle;
    pathReadSucc, found: boolean;
    buffer: packed array[0..300] of char;
    bytesRead: DWord;
begin
    found:=false;

    entry.dwSize := sizeof(TProcessEntry32);
    snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

    if (Process32First(snapshot, entry) = TRUE) then
    begin
        while (Process32Next(snapshot, entry) = TRUE) do
        begin
            writeln(AnsiString(entry.szExeFile));

            if (AnsiString(entry.szExeFile) =  'Themis.exe')  then
            begin
                themisprocess := OpenProcess(PROCESS_ALL_ACCESS,
                    FALSE, entry.th32ProcessID);

                pathReadSucc := ReadProcessMemory(themisprocess, Pointer(currentTestFolderPtr),
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
