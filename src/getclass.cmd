/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  GETClass gets selected Object Classes                                  บ
    บ                                                                       บ
    บ  15/09/03: V1.1 - map datapath                      (gjarvis@ieee.org)บ
    บ  02/06/03: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib

'@echo off'
prgver = '1.1'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
listFile = 'getclass.lst'
datFile = 'getclass.din'

/* statistics */
num.0rd = 0
num.0new = 0
num.0create = 0

_d_ = '"'

call getosver prgver, os.
say os.0line

parse arg parm . '(' opt
opt = translate(opt)
allFlag = wordpos("ALL",opt)>0
if allFlag then datFile = "getclass.all"

/* read list file */
lists.0 = 0
if \allFlag then do
   if fileExists(listfile) then do
      call vback listfile 'backing existing'
      i =   0
      do while lines(listFile)
         i = i + 1
         parse value linein(listfile) with verb rest
         lists.i = translate(verb) rest
      end
      lists.0 = i
      call closeFile listfile
   end /* do */
end

call vback datfile "backing existing"
call stream datfile, 'c', "open write replace"
call lineout datfile, 'from' os.0line



/* Type the list of object classes */
call SysQueryClassList "class."
do i = 1 to class.0
   if allflag then call create class.i
   else do
      parse var class.i name .
      in = inlist(name)
      if in>0 then do
         if pos("INC",lists.in)=1 then call create class.i
         num.0rd = num.0rd + 1
      end /* do */
      else do
         call lineout listfile, "EXC" name
         num.0new = num.0new + 1
      end /* do */
   end /* do */
end

if num.0new>0 then call closeFile listfile
call closeFile datFile
call vback datfile "backing new"
say os.0prgname 'read:' num.0rd 'new:' num.0new 'created:' num.0create
exit 0;




/* return index to lists. with matching -name else returns 0 if nothing matches */
inlist: procedure expose lists. _d_
   parse arg name
   do i = 1 to lists.0
      parse var lists.i lverb lname .
      select
         when lverb='' then iterate
         when pos('*',lverb)=1 then iterate
         otherwise
            if wildcardmatch(lname,name) then return i
      end
   end /* do */
   return 0



/*    create class - write it to datfile */
create:    procedure expose datfile num. os. allFlag lists.
   parse arg class
   class = changestr(os.0bootpath,class,'C:\')
   class = changestr(os.0datapath,class,'D:\')
   call lineout datfile, class
   num.0create = num.0create + 1
   return 1


