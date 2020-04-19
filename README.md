# pp [![Build status](https://ci.appveyor.com/api/projects/status/s7jwvj5a45xsdtvy/branch/master?svg=true)](https://ci.appveyor.com/project/bentokun/pp/branch/master)

Using Win32 API to do a copy/paste test case to output from a Themis contest on a 32-bit Windows.

## Explanation
- Static address in memory of path of test cases in Themis was found by analyzing. This is a tool that opens the output test files from Themis server, and copy them to our output files.
- Firstly, the application queries a list of process and find the one that has the executable name of **Themis.exe**. Then, it tries to read the address of the test cases, copy them then open the output file.

## Compatibility
- This does not confirm to work on 64-bit machines or Windows 10, only Windows 7 32-bit are guaranteed.
- Supported Themis version: 1.7.6.744, 1.9.6.2331
