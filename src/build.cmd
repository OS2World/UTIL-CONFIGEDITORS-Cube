/* to build all sources */

call buildem "cube.cmd"
call buildem "getini.cmd"
call buildem "putini.cmd"
call buildem "getclass.cmd"
call buildem "putclass.cmd"
call buildem "getwps.cmd"
call buildem "putwps.cmd"
call buildem "vbcopy.cmd"
call buildem "vback.cmd"
exit

/* preprocess and compile and launch */
buildem: procedure
   parse arg file
   call pprexx file "..\bin\"file
   return


