/* Don't edit this file, as it is generated by 'PPREXX' version 1.0 from the ..\src directory. */
/* Please edit the following:
    ..\src\putwps.cmd
    ..\src\lib.cmd
*/
/*  �����������������������������������������������������������������������ͻ
    �  PUTWPS puts WPS objects selected list for multiple drive support.    �
    �                                                                       �
    �  29/09/03: V1.3 - map datapath                      (gjarvis@ieee.org)�
    �                 - both create and update statistics                   �
    �  04/07/03: V1.2 - check for unregister class (gjarvis@ieee.org)       �
    �  23/03/03: V1.1 - check for missing title                             �
    �                 - (DEBUG command line option   (gjarvis@ieee.org)     �
    �  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  �
    �����������������������������������������������������������������������ͼ */


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

getosver:procedure expose delimit.
   use arg prgver, os.
   call createdelimiters
   /* program invoked */
   parse upper source . . os.0prgname
   /* bootpath */
   parse value value('PATH',,'OS2ENVIRONMENT') with . ":\OS2;" -1 os.0bootPath +3
   /* datapath */
   parse var os.0prgname os.0datapath +3
   /* version - note sysos2ver() returns version of C: rather than actual bootdrive */
   /*4502.*/
   os.0ver = strip(translate("31524",c2x(charin(os.0bootpath"OS2\INSTALL\SYSLEVEL.OS2",41,2))'.',"12345"),,0)
   call stream bootpath"OS2\INSTALL\SYSLEVEL.OS2", 'c', 'close'
   curpath = directory()
   ecspath = directory(os.0bootpath'ecs')
   select
      when os.0ver<4.51 then os.0ver = 'WARP' os.0ver
      when  translate(ecspath)=os.0bootpath'ECS' then os.0ver = 'eCS' os.0ver
   otherwise os.0ver = 'SWC' os.0ver
   end  /* select */
   call directory(curpath)
   /* program name */
   i = lastpos('\', os.0prgname) + 1
   parse var os.0prgname =(i) os.0prg "."
   /* program running line */
   os.0line = os.0prg prgver 'running' '"'os.0bootpath'"' os.0ver 'on' date() time()
   return



/* wildcard match */
wildcardmatch: procedure
   parse arg wstr, str
   w = pos('*',wstr)
   if w<2 then m = str==wstr
   else m = left(str,w-1)==left(wstr,w-1)
   return m


/*  return true if file succesfully closed */
closeFile:   procedure
   ret = stream(arg(1),'C','CLOSE')
   if ret='READY:' then return 1
   say 'error closing file stream' arg(1) ret
   exit -1
   return 0


/*  return true if file exists */
fileExists:  procedure
   ret = stream(arg(1),'C','QUERY EXISTS')
   if ret='' then return 0
   return 1


/* �����������������������������������������������������������������������͸
   �  parse options                                                        �
        stem    global  delimit.
        string  in      option string to parse (any case)
        stem    out     option stem
   �����������������������������������������������������������������������;  */
ParseOpt: procedure expose delimit.
  use arg sop, option.
  dq = '"'
  quote = translate(sop,delimit.asciiless,delimit.ascii,dq)
  option.KEY = ""
  option.0 = 0
  do forever
    if sop='' then leave
    pdq = pos(dq,quote)
    if pdq>0 then do
      parse var sop keys =(pdq) d +1  str (d) sop
      quote = right(quote,length(sop))
    end
    else do
       keys = sop
       str = ''
       sop = ''
    end
    option.KEY = option.KEY keys
    w = words(keys)
    if w>1 then
      do i  = option.0+1 to option.0+w-1
         option.i = ''
      end /* do */
    i = option.0 + w
    option.i = str
    option.0 = i
  end
  option.key = translate(strip(option.key,'L'))
   return

/* �����������������������������������������������������������������������͸
   �  true if name exists in option                                        �
        string  in      key string to test (upper case)
        stem    in/out  option stem
        bool    ret     if string is a option
   �����������������������������������������������������������������������;  */
GetOpt: procedure
   use arg skey, gopt.
   gopt.pos = wordpos(skey, gopt.KEY)
   return gopt.pos>0
   

/* �����������������������������������������������������������������������͸
   �  gets option string of key from last GETOPT call, 
    which may be optional and may have a default     

string  in      default string 
        stem    in      option stem
        string  ret     option string or default string or null
   �����������������������������������������������������������������������;  */
GetStrOpt: procedure
   use arg default, gsopt.
   found = gsopt.[gsopt.pos]
   if length(found)=0 then found = default
   return found


/**
CreateDelimiters
create global dynamic delimit stem
stem global delimit.
*/
CreateDelimiters: procedure expose delimit.
delimit.STR = '"' || "'`!@#$%^&"
delimit.asciiless = ''
do i = 32 to 126
   if pos(d2c(i),delimit.Str)=0 then delimit.asciiless = delimit.asciiless || d2c(i)
end /* do */
delimit.ascii = delimit.asciiless || delimit.str
return


/**
WHENSELECTED Make and when test.
    make    in  string  make words (may be empty)
    mwhen   in  string  when words (may be '*')
    return  flag    if okay
    */
whenselected: procedure
   parse arg make, mwhen
   if mwhen='*' then return 1
   if words(make)>0 then do i=1 to words(make)
      if wordpos(word(Make,i),MWhen)>0 then return 1
   end /* do */
   return 0
   

