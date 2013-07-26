/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  GETWPS gets selected desktop and startup objects and their decedents บ
    บ  with multiple drive support.                                         บ
    บ                                                                       บ
    บ  15/09/03: V1.3 - map datapath                      (gjarvis@ieee.org)บ
    บ  19/05/03: V1.2 - for shadows missing OBJECTID (gjarvis@ieee.org)     บ
    บ  23/03/03: V1.1 - (ALL command line option                            บ
    บ                 - (WPDATA command line option                         บ
    บ                 - OBJ verb                      (gjarvis@ieee.org)    บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

#include lib

'@echo off'
prgver = '1.3'
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs
call RxFuncAdd 'WPToolsLoadFuncs', 'WPTOOLS', 'WPToolsLoadFuncs'
call WPToolsLoadFuncs
listFile = 'getwps.lst'
datFile = 'getwps.din'
newnum = 0
creatednum = 0
_d_ = '"'

prgver = prgver 'with WPTOOLS.DLL' WPToolsVersion()
call getosver prgver, os.
say os.0line

parse arg parm '(' opt
opt = translate(opt)
allFlag = wordpos("ALL",opt)>0
wpdataFlag = wordpos("WPDATA",opt)>0
if allFlag then datFile = "getwps.all"

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
      call closefile listfile
   end /* do */
end

call vback datfile "backing existing"
call stream datfile, 'c', "open write replace"
call lineout datfile, 'from' os.0line

tops.1 = '<WP_DESKTOP>'
tops.2 = '<WP_START>'
tops.0 = 2


/* main loop */
do j = 1 to tops.0
    if \WPToolsFolderContent(tops.j, "objs.", 'F') Then iterate
    do i = 1 to objs.0
        obj = objs.i
        if \WPToolsQueryObject(obj, "class", "title", , "loc") Then iterate
        if allFlag then do
           call getfldchk obj
           iterate
        end /* do */
        f = inlist(class, title, loc)
        if f>0 then do
           if pos('INC',lists.f)=1 then call getfldchk obj
        end /* do */
        else do
            call lineout listFile,'EXC' '"'class'"' '"'title'"' '"'loc'"'
            newnum = newnum + 1
        end /* do */
    end
end
call getwps "<WP_DESKTOP>"

/* OBJ */
if \allFLag then do
    do i = 1 to lists.0
       parse var lists.i lverb rest
       if lverb<>"OBJ" then iterate
       parse var rest (_d_) obj (_d_) .
       call getfldchk obj
    end /* do */
end

if newnum>0 then call closefile listfile
call closefile datFile
call vback datfile "backing new"
say os.0prgname 'read:' lists.0 'new:' newnum 'created:' creatednum
exit 0;




/* return index to lists. with matching obj & class else returns 0 if nothing matches */
inlist: procedure expose lists. _d_
    parse arg class, title, loc
    /*say '"'obj'"' '"'class'"' '"'title'"' '"'setup'"' '"'loc'"'*/
    do i = 1 to lists.0
       parse var lists.i lverb (_d_) lclass (_d_) (_d_) ltitle (_d_) (_d_) lloc (_d_) rest
       if class<>lclass then iterate
       if title<>ltitle then iterate
       if loc<>lloc then iterate
       return i
    end /* do */
    return 0



/* get all objects from obj including subfolders */
getfldchk: procedure expose datfile creatednum os. wpdataFlag allFlag lists.
    parse arg obj, class
    if \WPToolsQueryObject(obj, "class", , , ) Then return
    if \getwps(obj) then return
    if class='WPFolder' then do
        if \WPToolsFolderContent(obj, "objs.", 'F') Then return
        do i = 1 to objs.0
            call getfldchk objs.i
        end
    end
    return



/* get class, title, setup, loc for obj and write it to datfile */
getwps: procedure expose datfile creatednum os. wpdataFlag allFlag lists.
    parse arg obj
    if \WPToolsQueryObject(obj, "class", "title", "setup", "loc") then return 0
    setup = changestr(os.0bootpath, setup, 'C:\')
    setup = changestr(os.0datapath, setup, 'D:\')
    loc = changestr(os.0bootpath, loc, 'C:\')
    loc = changestr(os.0datapath, loc, 'D:\')
    if class='WPShadow' then setup = subsetup('SHADOWID=', setup) || subsetup('OBJECTID=', setup)
    if (wpdataFlag) & (class='WPDataFile') then return 0
    call lineout datfile, '"'class'"' '"'title'"' '"'loc'"' '"'setup'"'
    creatednum = creatednum + 1
    return 1


/* return substr of setup */
subsetup: procedure
    parse arg sub, setup
    b = pos(sub, setup)
    if b=0 then return ''
    e = pos(';', setup, b)
    return substr(setup, b, e-b+1)


