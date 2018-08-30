# pp

Using Win32 API to do a copy/paste test case to output from a Themis contest on a 32-bit Windows.

## Explanation
- By doing analyze, static address of test case path on a 32-bit machine (Windows 7) have been found. Taking advantage of the executable - which
file name never change, this is a tool to open the output test file from Themis server, and copy paste them to our output file.
- The application first queries a list of process and find the one that has the executable name of **Themis.exe**. Than, the app tries to read the address
of the test case path, copy them and then open the output file.

## Compatibility
- This does not confirm to work on 64-bit or Windows 10 machine, only Windows 7 32-bit were guranteed.
- Supported Themis version: 1.9.144

Released under MIT license, all work is done by @Noism.
