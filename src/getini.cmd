/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  GETINI gets selected USER and SYSTEM INI data for multiple drive     บ
    บ  support.                                                             บ
    บ                                                                       บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    บ  05/06/03: V1.1 - drive mapping bug                                   บ
    บ                   key now in quotes (may have spaces)                 บ
    บ                   wild card matching of apps                          บ
    บ                   ALL option           (gjarvis@ieee.org)             บ
    บ  06/10/03: V1.2 - map datapath                      (gjarvis@ieee.org)บ	
    บ                   key maybe option in list          (gjarvis@ieee.org)บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib
#include ascii

'@echo off'
prgver = '1.2'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
call getosver prgver, os.
say os.0line
call newascii 

file.0list = 'getini.lst'
file.0dat = 'getini.din'

/* statistics */
num.rd = 0
num.new = 0
num.ky = 0

_d_ = '"'

parse arg . '(' opt
call parseopt opt, copt.
flag.all = getopt('ALL',copt.)
if flag.all then file.0dat = 'getini.all'

/* read list file */
i = 0
lists.0 = 0
if \Flag.all then do
   if fileExists(file.0list) then do
      call vback file.0list 'backing existing'
      do while lines(file.0list)
         i = i + 1
         parse value linein(file.0list) with verb rest
         lists.i = translate(verb) rest
      end
      lists.0 = i
      say "read" i "lst lines"
      call closefile file.0list
   end
end

call vback file.0dat "backing existing"
call stream file.0dat, 'c', "open write replace"
call lineout file.0dat, 'from' os.0line

inifile.1 = 'USER'
inifile.2 = 'SYSTEM'
inifile.0 = 2

/* main loop */
do j = 1 to 2
   call SysIni inifile.j, 'All:', 'Apps.'
   if Result = 'ERROR:' then exit -1;
   do i = 1 to Apps.0
      call getapp inifile.j, apps.i
   end
end /* do */

call closefile file.0dat
call vback file.0dat "backing new"
say os.0prgname 'read:' num.rd 'new:' num.new 'keys:' num.ky
if num.new>0 then call closefile file.0list
exit 0;




/* return index to lists. with matching ini & app & key else returns 0 if nothing matches */
inlist: procedure expose lists. _d_
   parse arg ini, app, key
   do i = 1 to lists.0
      parse var lists.i lverb lini (_d_) lapp (_d_) (_d_) lkey (_d_) .
      select
         when lverb='' then iterate
         when pos('*',lverb)=1 then iterate
         when ini<>lini then iterate
         otherwise
            if wildcardmatch(lapp,app) then do
                if lkey='' then return i
                if lkey=key then return i
            end
      end
   end /* do */
   return 0



/* get all keys for ini & app and calls getkey */
getapp: procedure expose file. tran. num. os. flag. lists. _d_
    parse arg ini, app
    call SysIni ini, app, 'All:', 'Keys'
    if Result \= 'ERROR:' then do j=1 to Keys.0
        if flag.all then call getkey ini, app, keys.j
        else do
            f = inlist(ini, app, keys.j)
            if f>0 then do
                if pos('INC',lists.f)=1 then call getkey ini, app, keys.j
                num.rd = num.rd + 1
            end /* do */
            else do
                call lineout file.0list,'EXC' ini '"'app'"'
                num.new = num.new + 1
            end /* do */
        end
    end
    return



/* get key value for ini & app & key and write it to file.0dat */
getkey: procedure expose file. tran. num. os.
    parse arg ini, app, key
    val = SysIni(ini, app, key)
    val = changestr(os.0bootpath, val, 'C:\')
    val = changestr(os.0datapath, val, 'D:\')
     call lineout file.0dat, ini '"'app'"' '"'key'"' asciiFormat(val) c2x(val)
    num.ky = num.ky + 1
    return



