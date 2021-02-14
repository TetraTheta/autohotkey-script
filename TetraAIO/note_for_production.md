# How to make working EXE for production

1. Make EXE file with `ahk2exe`. I need to specify default icon file when compile.  
2. Use `ResourceHacker.exe` to manipulate 'Icon Group' and 'RCData'.  
    1. `Icon Group > 159`: Default Icons  
       `Icon Group > 206`: Suspend Icons. Change it with my desired icon.  
       `Icon Group > 500`: My custom Icons. If more required, add them with different numbers.  
    2. `RCData > AUTOHOTKEY SCRIPT`: Script to modify.  
	   Change All `normal.ico` things into `%A_ScriptFullPath%, -159`.  
3. Save EXE and compress it with UPX.
  
It would be nice if I change original script's `normal.ico` things into `%A_ScriptFullPath%, -159` but I didn't tested it.  
No, it's not working in debugging session which is run directly `.ahk` file.