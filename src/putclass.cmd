/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  PUTCLASS register selected obect classes                              บ
    บ                                                                       บ
    บ  15/09/03: V1.1 - map datapath                      (gjarvis@ieee.org)บ
    บ  02/06/03: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib

'@echo off'
prgver = '1.1'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
listFile = 'getCLASS.lst'
datFile = 'getCLASS.din'

/* statistics */
num.rd = 0
num.new = 0
num.upd = 0

_d_ = '"'
parse arg file '(' switch
if file<>'' then datfile = file
writeflag = wordpos('WRITE', translate(switch))>0

call getosver prgver, os.
say os.0line
say 'reading' datfile 'and write =' writeflag

/* OBJECT CLASSES */
call SysQueryClassList "class."
do i = 1 to class.0
      parse var class.i name.i dll.i .
         num.rd = num.rd + 1
end

/* read dat file */
say linein(datfile)
do while lines(datFile)
    call putkey
end
call closefile datfile

say os.0prgname 'read:' num.rd 'new:' num.new 'updated:' num.upd
exit 0;





/* read linein and put key value for CLASS & app & key & val if changed and return true */
putkey: procedure expose datfile tran. num. class. name. dll. _d_ writeFlag os.
    num.rd = num.rd + 1
    parse value Linein(datfile) with cname cdll .
    cdll = changestr('D:\',cdll,os.0datapath)
    cdll = changestr('C:\',cdll,os.0bootpath)
    find = 0
    do i=1 to class.0
       if cname <> name.i then iterate
       find = 1
       leave
    end /* do */
    if find then do
        if cdll <> dll.i then do /* update */
            if writeFlag then do
               call SysDeregisterObjectClass cname
               if \SysRegisterObjectClass(cname,cdll) then return 0
            end /* do */
            num.upd = num.upd + 1
        end /* do */
    end
    else do /* new */
         if writeFlag then do
            if \SysRegisterObjectClass(cname,cdll) then return 0
         end /* do */
         num.new = num.new + 1
    end /* do */
    return 1


