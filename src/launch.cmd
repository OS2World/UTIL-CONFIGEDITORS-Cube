/* launch lib */

'@echo off'
parse arg parm
call launch "$wdir$", parm
exit


/* change to working dir and run the command processor */
launch: procedure
   parse arg wdir, parm
   parse upper source . . name
   parse var name  path "BIN\" prg
   call directory(path || wdir)
   "cmd /c" path || "cmd\" || prg parm
   return


