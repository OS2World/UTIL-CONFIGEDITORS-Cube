/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  TXT2XML gets selected desktop and startup objects and their decedents บ
    บ  with multiple drive support.                                         บ
    บ                                                                       บ
    บ  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */

'@echo off'
prgver = '1.0'
parse upper source pmgsrc
parse value value('PATH',,'OS2ENVIRONMENT') with . ":\OS2;" -1 bootPath +3 .
creatednum = 0

sysver = translate('3241', Sysos2ver(), '1234')    /* positional bug in sysos2ver */
curpath = directory()
ecspath = directory(bootpath'ecs')
select
   when sysver<4.51 then sysos = 'WARP'
   when ecspath=bootpath'ECS' then sysos = 'eCS'
otherwise sysos = 'SWC'
end  /* select */
call directory(curpath)

line = 'TXT2XML' 'running' '"'bootpath'"' sysos sysver 'on' date() time()
say line

parse arg file
infile = file || ".doc"
outfile = file || ".xml"

/* printable ASCII */
ascii.print = ''
do i = 32 to 126
   ascii.print = ascii.print || d2c(i)
end /* do */
ascii.all = ascii.print
do i = 0 to 31
   ascii.all = ascii.all || d2c(i)
end /* do */
do i = 127 to 255
   ascii.all = ascii.all || d2c(i)
end /* do */

if exists(outfile) then do
   call vback outfile "backing existing"
   address cmd 'del' outfile
end /* do */


/* read list file */
if exists(infile) then do
   do while lines(infile)
      call txt2xml linein(infile)
   end
   call close infile
   call close outfile
end /* do */

call vback outfile "backing new"
say pmgsrc 'created:' creatednum
exit 0;



/* process a line and write to file */
txt2xml: procedure expose outfile creatednum ascii.
    parse arg line
    line = strip( translate(line, ascii.print, ascii.all, ' '), 'B')     /* strip out graphic characters */
    line = repstr("&", line, "&amp;")
    line = repstr("<", line, "&lt;")
    line = repstr(">", line, "&gt;")
    call lineout outfile, line
    creatednum = creatednum + 1
    return 1


/* return str that find is replace by rep */
repstr: procedure
   parse arg find, str, rep
   /*say "repstr:" find str rep*/
   out = ''
   do while str\=''
      if pos(find,str)=0 then rep = ''
      parse var str first (find) str
      out = out || first || rep
   end /* do */
return out


/* return true if file succesfully closed */
close: procedure
    ret = stream(arg(1),'C','CLOSE')
    if ret='READY:' then return 1
    say 'error closing file stream' arg(1) ret
    exit -1
    return 0


/* return true if file exists */
exists: procedure
   ret = stream(arg(1),'C','QUERY EXISTS')
   if ret='' then return 0
   else return 1


