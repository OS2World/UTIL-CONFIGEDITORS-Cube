/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  VBCOPY intelligent backup and copy tree                              บ
    บ                                                                       บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    บ  03/07/03: V1.1 - reverse copy if newer (gjarvis@ieee.org)            บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */
#include lib

'@echo off'

call RxFuncAdd 'SysFileTree', 'RexxUtil', 'SysFileTree'
prgver = '1.1'

/* statistics */
num.0read = 0
num.0copy = 0
num.0update = 0

call getosver prgver, os.
say os.0line
parse arg from to
if to='' then do
    say "usage::vbcopy <from> <to>"
    say "from     path name"
    say "to       path name"
    exit 1
end

vdir = "vback"
log = "vbcopy.log"
address cmd
curpath = directory()
frompath = directory(from)
if lastpos('\',frompath)\=length(frompath) then frompath = frompath'\'
frompos = length(frompath)+38
call directory curpath
topath = directory(to)
if lastpos('\',topath)\=length(topath) then topath = topath'\'
topos = length(topath)+38
call directory curpath
if frompath='' then do
    say 'parameter from' from 'is bogus'
    exit 1
end /* do */
if topath='' then do
    say 'parameter to' to 'is bogus'
    exit 1
end /* do */


/* directories */

call SysFileTree frompath, 'fromdir', 'SD'


do i=1 to fromdir.0
    fromname = substr(fromdir.i,frompos)
    /* exclude vback paths */
    s1 = lastpos('\',fromname)
    if s1=0 then pd = fromname
    else pd = substr(fromname,s1+1)
/*    if pd=="vback" then say "skipping dir" fromname*/
    if pd=="vback" then iterate
    call SysFileTree topath||fromname, 'todir', 'D'
    if todir.0=0 then "md" topath||fromname '1>nul: 2>nul:'
end /* do */

/* files */

call SysFileTree frompath'*', 'froms', 'SF'
n = froms.0
if n=0 then do
    say 'nothing in from path:' from
    exit 1
end /* do */
num.0read = n

do i=1 to froms.0
   fromname = substr(froms.i,frompos)
    /* exclude vback paths */
    s1 = lastpos('\',fromname)
    if s1>0 then do
       s2 = lastpos('\',fromname,s1-1)
       pd   = substr(fromname,s2+1,s1-s2-1)
/*       if pd=="vback" then say "skipping file" fromname*/
       if pd=="vback" then iterate
    end /* do */
    
    tocopy = 1
   call SysFileTree topath||fromname, 'tos', 'F'
   if tos.0>0 then do
      todate = left(tos.1,16)
      fromdate = left(froms.i,16)
      call vback topath||fromname 'backing existing'
      if fromdate<>todate then do
         if dateGT(todate,fromdate) then do
            /* updating to: copying to from */
            call vback frompath||fromname 'backing existing'
            address cmd "copy" topath||fromname frompath||fromname '1>nul: 2>nul:'
            call vback frompath||fromname 'backing copy'
            if num.0update=0 then call lineout log, os.0line
            call lineout log, "replacing" frompath||fromname fromdate "by" topath||fromname todate
            num.0update = num.0update + 1
            tocopy = 0
         end /* do */
      end /* do */
      else tocopy = 0
   end /* do */
   if tocopy then do
        /* copying from to */
        address cmd "copy" frompath||fromname topath||fromname '1>nul: 2>nul:'
        call vback topath||fromname 'backing copy'
        num.0copy = num.0copy + 1
   end /* do */
          
end /* do */

if num.0update>0 then do
   call lineout log, ''
   call closefile log
end /* do */
say os.0prgname 'read:' num.0read 'copied:' num.0copy "update:" num.0update
exit 0



/* date compare ex: "10/22/01   6:11p" 
returns true if date1 > date 2*/
dateGT: procedure 
    parse arg fdate, tdate
    parse var fdate fmo +2 +1 fdy +2 +1 fyr +2 +2 fhh +2 +1 fmi +2 fi
    parse var tdate tmo +2 +1 tdy +2 +1 tyr +2 +2 thh +2 +1 tmi +2 ti
    select
       when fyr>tyr then gt = 1
       when fyr<tyr then gt = 0
       when fmo>tmo then gt = 1
       when fmo<tmo then gt = 0
       when fdy>tdy then gt = 1
       when fdy<tdy then gt = 0
       when fi>ti then gt = 1
       when fi<ti then gt = 0
       when fhh>thh then gt = 1
       when fhh<thh then gt = 0
       when fmi>tmi then gt = 1
    otherwise gt = 0
    end  /* select */
    return gt
    


