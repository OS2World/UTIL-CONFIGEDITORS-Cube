/* Don't edit this file, as it is generated by 'PPREXX' version 1.0 from the ..\src directory. */
/* Please edit the following:
    ..\src\getini.cmd
    ..\src\lib.cmd
    ..\src\ascii.cmd
*/
/*  浜様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
    �  GETINI gets selected USER and SYSTEM INI data for multiple drive     �
    �  support.                                                             �
    �                                                                       �
    �  17/06/02: V1.0 - Initial version (gjarvis@ieee.org)                  �
    �  05/06/03: V1.1 - drive mapping bug                                   �
    �                   key now in quotes (may have spaces)                 �
    �                   wild card matching of apps                          �
    �                   ALL option           (gjarvis@ieee.org)             �
    �  06/10/03: V1.2 - map datapath                      (gjarvis@ieee.org)�	
    �                   key maybe option in list          (gjarvis@ieee.org)�
    藩様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様� */


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


/* 嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
   �  parse options                                                        �
        stem    global  delimit.
        string  in      option string to parse (any case)
        stem    out     option stem
   塒様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�  */
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

/* 嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
   �  true if name exists in option                                        �
        string  in      key string to test (upper case)
        stem    in/out  option stem
        bool    ret     if string is a option
   塒様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�  */
GetOpt: procedure
   use arg skey, gopt.
   gopt.pos = wordpos(skey, gopt.KEY)
   return gopt.pos>0
   

/* 嬪様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�
   �  gets option string of key from last GETOPT call, 
    which may be optional and may have a default     

string  in      default string 
        stem    in      option stem
        string  ret     option string or default string or null
   塒様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様�  */
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
   




/**ASCII Setup ascii trans. table*/
NEWASCII: procedure expose tran.
/* table translation
    tran.1  printable ascii and graphic char for null
    tran.2  all codes with tran.1 first but actual null
    tran.3  pad char for binary char
    tran.4  begin quote char
    tran.5  end quote char          */
tran.3 = d2c(2)
tran.4 = d2c(16)
tran.5 = d2c(17)
do i = 32 to 126
    tran.1 = tran.1||d2c(i)
end /* do */
tran.2 = tran.1
tran.1 = tran.1||d2c(232)
do i = 0 to 31
   tran.2 = tran.2||d2c(i)
end /* do */
do i = 127 to 255
   tran.2 = tran.2||d2c(i)
end /* do */
tran.0 = 5                                                  s
return


/**  ASCIIFORMAT Quick format binary/ASCIIZ/ASCII. */
ASCIIFORMAT: procedure expose tran.
   parse arg val
    return tran.4||translate(val,tran.1,tran.2,tran.3)||tran.5
    
    
