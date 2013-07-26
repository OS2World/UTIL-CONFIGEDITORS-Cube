/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  PUTWPS puts WPS objects selected list for multiple drive support.    บ
    บ                                                                       บ
    บ  29/09/03: V1.3 - map datapath                      (gjarvis@ieee.org)บ
    บ                 - both create and update statistics                   บ
    บ  04/07/03: V1.2 - check for unregister class (gjarvis@ieee.org)       บ
    บ  23/03/03: V1.1 - check for missing title                             บ
    บ                 - (DEBUG command line option   (gjarvis@ieee.org)     บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib

'@echo off'
prgver = '1.3'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
datFile = 'getwps.din'
linenum = 0
num.0create = 0
num.0update = 0
num.0error = 0
_d_ = '"'

call getosver prgver, os.
say os.0line

parse arg parm '(' opt
opt = translate(opt)
DEBUGFlag = wordpos("DEBUG",opt)>0

/* get the registered object classes */
call SysQueryClassList "regclass."
validclass = ''
do i = 1 to regclass.0
   parse var regclass.i name .
   validclass = validclass name
end

/* read dat file */
if fileExists(datfile) then do
    linenum = 1
    say linein(datfile)
    do while lines(datFile)
        linenum = linenum + 1
        call putwps
    end
    call closefile datfile
end /* do */

say os.0prgname 'read:' linenum-1 'created:' num.0create 'updated:' num.0update  'Errors:' num.0error
exit 0;


/* put class, title, setup, loc for obj and write it to datfile */
putwps: procedure expose datfile num. os. _d_ linenum debugFlag validclass
    parse value linein(datfile) with (_d_) class (_d_) (_d_) title (_d_) (_d_) loc (_d_) (_d_) setup (_d_)
    setup = changestr('D:\', setup, os.0datapath)
    setup = changestr('C:\', setup, os.0bootpath)
    loc = changestr('D:\', loc, os.0datapath)
    loc = changestr('C:\', loc, os.0bootpath)
    if debugFlag then say 'calling syscreateobject for' class title loc 'line' linenum
    if wordpos(class,validclass)=0 then do
        say "unregistered class for" class loc 'line' linenum
        return 0
    end /* do */
    if length(title)=0 then do
        say "missing title for" class loc 'line' linenum
        return 0
    end /* do */
    select
       when SysCreateObject( class, title, loc, setup, 'f') then num.0create = num.0create + 1
       when SysCreateObject( class, title, loc, setup, 'u') then num.0update = num.0update + 1
    otherwise say 'can not update object for' class title loc 'line' linenum
       num.0error = num.0error + 1
    end  /* select */
    return 1


/* return substr of setup */
subsetup: procedure
    parse arg sub, setup
    b = pos(sub, setup)
    if b=0 then do
        say 'no' sub 'in' setup
        return ''
    end /* do */
    b = b + length(sub)
    e = pos(';', setup, b)
    s = substr(setup, b, e-b)
    return s

