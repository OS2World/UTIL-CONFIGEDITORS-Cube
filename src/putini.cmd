/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  PUTINI puts selected USER and SYSTEM INI data for multiple drive     บ
    บ  support.                                                             บ
    บ                                                                       บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    บ  17/02/03: V1.1 - fix bootpath    (gjarvis@ieee.org)                  บ
    บ  03/06/03: V1.2 - key in quotes (may have spaces)   (gjarvis@ieee.org)บ
    บ  15/09/03: V1.3 - map datapath                      (gjarvis@ieee.org)บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib
#include ascii

'@echo off'
prgver = '1.3'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
call newascii 

call getosver prgver, os.
say os.0line
listFile = 'getini.lst'
datFile = 'getini.din'

/* statistics */
num.rd = 0
num.new = 0
num.upd = 0
num.err = 0

_d_ = '"'
parse arg file '(' opt
if file<>'' then datfile = file
call parseopt opt, copt.
writeflag = getopt('WRITE', copt.)
say 'reading' datfile 'and write =' writeflag

 /* read dat file */
say linein(datfile)
do while lines(datFile)
    call putkey
end
call closefile datfile

say os.0prgname 'read:' num.rd 'new:' num.new 'updated:' num.upd 'error' num.err
exit 0;





/* read linein and put key value for ini & app & key & val if changed and return true */
putkey: procedure expose datfile tran. num. _d_ writeFlag os.
    num.rd = num.rd + 1
    parse value Linein(datfile) with ini . (_d_) app (_d_) (_d_) key (_d_) (tran.4) valfmt (tran.5) val .
    if length(val)<>(2*length(valfmt)) then do
       say "missing part of value in line" num.rd '"'app'"' '"'key'"'
       num.err =num.err + 1
       return 0
    end /* do */
    else
    val = x2c(val)
    val = changestr('D:\', val, os.0datapath)
    val = changestr('C:\', val, os.0bootpath)
    asc = asciiformat(val)
    oldval = SysIni(ini, app, key)
    if oldval=val then return 0
    if writeFlag then call sysini ini, app, key, val
    if oldval='ERROR:' then do
        op = 'new'
        num.new = num.new + 1
    end
    else do
        op = 'updated'
        num.upd = num.upd + 1
    end
    if length(val)>60 then asc = 'length(value)='|| length(val)
    say op ini '"'app'"' key asc
    return 1


