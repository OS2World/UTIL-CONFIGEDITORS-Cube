/* lib for cube

    15/09/03    1.1 added bootpath (gjarvis@ieee.org)
                        added: CREATEDELIMITERS,PARSEOPT, GETOPT, GETSTROPT,
                        WHENSELECTED
    30/06/03    1.0 initial version (gjarvis@ieee.org)
*/

ver = 1.1
call getosver ver, os.
say "bootpath =" os.0bootpath
say "datapath =" os.0datapath
say "ver =" os.0ver
say "line =" os.0line
say "match 're*' & 'rexx'" wildcardmatch("re*","rexx")
say "match 're*' & 'run'" wildcardmatch("re*","run")
sopt = "all make $advance$"
say "option=" sopt
call parseopt sopt, copt.
say "key NONE="  GETOPT("NONE", copt.)
say "key ALL=" GETOPT("ALL", copt.)
say "key ALL string basic=" getstropt("basic", copt.)
say "key MAKE=" GETOPT("MAKE", copt.)
say "key  MAKE string basic=" getstropt("basic", copt.)
say "whenselected(d b,a b c)=" whenselected("d b","a b c")
exit 0


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


/* ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
   ณ  parse options                                                        ฦ
        stem    global  delimit.
        string  in      option string to parse (any case)
        stem    out     option stem
   ิอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ  */
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

/* ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
   ณ  true if name exists in option                                        ฦ
        string  in      key string to test (upper case)
        stem    in/out  option stem
        bool    ret     if string is a option
   ิอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ  */
GetOpt: procedure
   use arg skey, gopt.
   gopt.pos = wordpos(skey, gopt.KEY)
   return gopt.pos>0
   

/* ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ
   ณ  gets option string of key from last GETOPT call, 
    which may be optional and may have a default     

string  in      default string 
        stem    in      option stem
        string  ret     option string or default string or null
   ิอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ  */
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
   


