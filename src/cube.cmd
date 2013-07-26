/*  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
    º                    Config Update/Batch Editing                        º
    º                                                                       º
    º  Batch update of CONFIG.SYS-like files. CUBE modifies a Target ASCII  º
    º  file, given a set of commands in a Procedure file.                   º
    º                                                                       º
    º  09/10/03: V3.3 - new COMMENT TOP, AL (COPY                           º
    º                   MAKE can be several words                           º
    º                   braces for single command for backward compatibilityº
    º                   improved UPKWD                                      º
    º                   datapath mapping              (gjarvis@ieee.org)    º
    º  24/05/03: V3.2 - dynamic string delimiters                           º
    º                   rewrote documentation in xhtml format               º
    º                   strings in options are excluded from keyword search º
    º                   code reuse heavily exploited command line           º
    º                   RS()->ENV & KEY with greater flexibility            º
    º                   tested and fixed most options                       º
    º                   requires Object REXX          (gjarvis@ieee.org)    º
    º  20/03/03: V3.1 (unreleased - untested code)    (gjarvis@ieee.org)    º
    º                   ADDSTRING\DELSTRING now handles seperation char     º
    º  25/06/02: V3.0 - In procedure "C:\" replaced by actual boot path     º
    º                   Added verb COMMENT & IGNORESPACES                   º
    º                   New cmd line print usage & option VBACK             º
    º                   show only changed lines                             º
    º                        (gjarvis@ieee.org)                             º
    º  04/06/93: V2.6 - Add 'procedure read from QUEUE' (from Steve Farrell)º
    º  03/06/93: V2.5 - Add IF/IFNOT to xLINE cmds (generalize N. Marks req)º
    º                   Correct ADDSTRING BEFORE option  (Neil Marks)       º
    º  07/04/93: V2.4 - Corrected ADDBOTTOM/ADDTOP in ADDSTRING (Per Hertz) º
    º                   Address cmd + CHECK Option + new exit rtne          º
    º  21/01/93: V2.3 - Added user defined string delimiter in CUBE cmds    º
    º  21/12/92: V2.2 - Added conditionnal command processing (WHEN)        º
    º  26/11/92: V2.1 - RS() for DL, DS (desinstallation case)              º
    º                   New LINEID command (strip leading chars)            º
    º                   ADDTOP,ADDBOTTOM for AS (W. Pachl requirement)      º
    º                   Fix Whereis (Walter Pachl).                         º
    º                   Exit with SaveFile return code (Walter Pachl)       º
    º  18/11/92: V2.0 - Changes with environment variable substitution (RS) º
    º                       (AS, RS, AL & AL now all have same RS() option) º
    º                   Logging of all changes made to Target File          º
    º                   Adapt/Include some of Walter Pachl's enhancements:  º
    º                       Single CUBE command on command line             º
    º                       Add'l string substitution at command line level º
    º                       PAUSE option (debugging purposes)               º
    º  05/11/92: V1.5 - AL with pre substitution                            º
    º  03/11/92: V1.4 - AS with substitution ; fix RS recursion.            º
    º  02/11/92: V1.3 - Bug fixes & cmds abbrev, thanks to Walter Pachl.    º
    º                   Target Backup & lineid no more limited to col 1.    º
    º  30/10/92: V1.2 - Added env variable substitution + version #         º
    º  31/08/92: V1.1 - Bug fix                                             º
    º  21/07/92: V1.0 - Initial revision                                    º
    º  Didier LAFON - LAFON at CBEPROFS                                     º
    ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼ */

#include lib

'@echo off'
prgver = '3.3'

call getosver prgver, os.
pf = 0
la = left(strip(arg(1),'L'),1)
select
   when pos(la, delimit.str)>0 then parse arg d +1 PFile (d) TFile Bkup . '(' Opt
   when la='{' then parse arg '{' PFile '}' TFile Bkup . '(' Opt
otherwise
  parse arg PFile TFile Bkup . '(' Opt
  pf = 1
end  /* select */

if pf then do
  if PFile = '' then call printUsage
  if Pfile <> 'QUEUE' then if exists(PFile)='' then call exitCube 0 PFile 'not found'
end
if TFile = ''  then call printUsage
if exists(TFile)='' then call exitCube 0 TFile 'not found'

call parseOpt Opt, ClOpt.
flag.0pause=GetOpt('PAUSE',ClOpt.)                   /* Pause mode ?            */
flag.0chkmd=GetOpt('CHECK',ClOpt.)                       /* Check mode ?            */
flag.0vback=GetOpt('VBACK',ClOpt.)                   /* VBACK mode ?            */
flag.0verbose=flag.0pause | flag.0chkmd
if GetOpt('MAKE', ClOpt.) then Make = translate(GetStrOpt('', ClOpt.))
else Make =''
flag.0when = 1
if  GetOpt('KEY',ClOpt.) then                      /* parse key value str? */
   call ParseOpt GetStrOpt('', ClOpt.), KeyOpt.
else keyopt.key = ''
flag.0test = GetOpt('TEST',ClOpt.)                  /* test  mode ?            */
flag.0StopOnErr = 1                                 /* Default OnError setting */
flag.0debug = 0
flag.0CaseIns = 1                                    /* String compare default  */
comment.0Top = 1
comment.0Begin = ''
comment.0Tail = ''
comment.0BlockBegin = ''
comment.0BlockEnd = ''
LineID.strip= ''                                         /* No lineid strip         */
LineID.profileFlag = 0
Number.Changes = 0
Number.Commands = 0
Number.Errors = 0
parse value value('PATH',,'OS2ENVIRONMENT') with ":\OS2;" -1 bootPath +3

say 'CUBE' prgver 'applying' PFile 'to' TFile 'on' date() time()
if flag.0verbose then say 'boot path=' bootPath 'Options=' Opt

Proc. = ''
if pf then do
   If PFile = 'QUEUE' then Do
     i = 1
     Do Queued()
       Parse Pull procline
       proc.i = proc.i || upkw(procline)
       if right(Proc.i,1) = ','                       /*   continuation char ?   */
         then proc.i=left(proc.i,length(proc.i)-1)' ' /*     yes: blank it out   */
         else  i = i + 1                              /*     no: new Proc line   */
     end
     Proc.0 = i-1                                     /* Proc.0 = # of lines     */
     if Proc.0 <= 0 then call exitCube 0 PFile 'empty'
  end
  Else do
     i = 1 ;                                          /* current Proc line: null */
     do while lines(PFile)                            /* for all PFile's lines   */
       Proc.i = Proc.i || upkw(linein(PFile))         /*   concat to Proc line   */
       if right(Proc.i,1) = ','                       /*   continuation char ?   */
         then proc.i=left(proc.i,length(proc.i)-1)' ' /*     yes: blank it out   */
         else  i = i + 1                              /*     no: new Proc line   */
     end
     Proc.0 = i-1                                     /* Proc.0 = # of lines     */
     call close PFile
     if Proc.0 <= 0 then call exitCube 0 PFile 'empty'
  End
end
else do
  Proc.0 = 1
  Proc.1 = upkw(Pfile)
end

i = 0
do while lines(TFile)                              /* for all TFile's lines   */
  i = i + 1                                        /*   get line in           */
  Target.i = linein(TFile)                         /*   Target. stem          */
end
Target.0 = i                                       /* Target.0 = # of lines   */
call close Tfile

/*  ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
    ºThe real thing: go thru procedure file, interpret/execute its commands º
    ºsequentially.                                                          º
    ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼ */
if flag.0test then say "make=" make

p = 0                                              /* Proc lines index        */
Proc.0lp = p                                        /* last logged line */
do while p <= Proc.0                               /* for all PFile's lines   */
    p = p + 1                                        /*   index next line       */
    if Proc.p = '' then iterate                      /*   ignore null lines    */
    Proc.0proc = Proc.p                             /* current line */
    Proc.0p = p                                     /* line number */

    /* replace D:\ & C:\ with actual datapath & bootpath */
    Proc.0proc = changestr('d:\', Proc.0proc, os.0datapath)
    Proc.0proc = changestr('D:\', Proc.0proc, os.0datapath)
    Proc.0proc = changestr('c:\', Proc.0proc, os.0bootpath)
    Proc.0proc = changestr('C:\', Proc.0proc, os.0bootpath)

  parse var Proc.0proc Verb Parms                      /*   Isolate command verb  */
  if flag.0verbose then do
    say
    say '>>>' Proc.0proc
  end /* do */
  Verb = translate(Verb)
    Number.Commands = Number.Commands + 1
  Select                                           /*   Process verb          */
    When left(Verb,1) = '*'      then iterate
    When left(Verb,2) = '--'     then iterate
               /* modifiers that always get executed  */
    When Verb = 'WHEN'           then call APPLYWHEN
    When Verb = 'ONERROR'        then call ONERROR
    When Verb = 'CASE'           then call CASE
    When Verb = 'LINEID'         then call LINEID
    When Verb = 'COMMENT'        then call COMMENT
               /* functions executed when WHEN/MAKE match */
    When \flag.0when & \flag.0test then iterate
    When Verb = 'REPLINE'     | verb = 'RL'  then call REPLINE
    When Verb = 'ADDLINE'     | verb = 'AL'  then call ADDLINE
    When Verb = 'DELLINE'     | verb = 'DL'  then call DELLINE
    When Verb = 'ADDSTRING'   | verb = 'AS'  then call ADDSTRING
    When Verb = 'DELSTRING'   | verb = 'DS'  then call DELSTRING
    When Verb = 'REPSTRING'   | verb = 'RS'  then call REPSTRING
    When flag.0test then iterate     /* exclude functions that don't call KeyEnvExpand */
    When Verb = 'COMMENTLINE' | verb = 'CL'  then call COMMENTL
    Otherwise rc=OnErrorDo(p,"Don't know what to do")
  end
  if flag.0pause then Pull .
end
if flag.0chkmd then call exitCube 2 os.0prg 'ended.'      /*                         */
else call exitCube 1 os.0prg 'ended.'      /* It's OVER !! and OK !!  */

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  Error report and action (based on Onerr setting, from ONERROR cmd)   Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
OnErrorDo:
   parse arg line,msg
   Number.Errors = Number.Errors + 1
   say "Error" Number.Errors "line" line':' msg
   if flag.0test then return 0
   if flag.0StopOnErr then call exitCube 0 os.0prg 'stopped.'
   else return 0

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  UpperCase string if flag.0CaseIns.                                     Æ
   ³  Strip leading space.                                                 Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
StrTranslate: procedure expose flag. bootPath LineID.
    parse arg str
    If flag.0CaseIns then str = translate(str)
    if LineID.profileFlag then str = strip(str,'L')
    return str

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  Searches All or First or Last lines in Target starting with string   Æ
   ³  Returns the line number(s) found.                                    Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
Whereis: procedure expose Target. flag. LineID. comment. bootPath
    parse arg string,direction,mode
    if wordpos(direction,'F A')>0 then do; de=comment.0Top; a=Target.0; par=1; end
    else do; de=Target.0; a=comment.0Top; par=-1; end
    S = StrTranslate(string)
    stringlength=length(S); ret = ''
    LspS = pos(' ',string)=1
    CommentFlag = 0
    if flag.0debug then  say "match=" S "mode=" mode
    do i = de to a by par
        T = Target.i
        if pos(comment.0Begin,T)=1 then iterate   /* ignore comment */
        LspT = pos(' ',T)=1
        If length(LineID.strip) = 1 then T = strip(T,'L',LineID.strip)
        T = StrTranslate(T)
        if pos( comment.0Tail,T)=1 then iterate   /* ignore comment */
        if \CommentFlag then
            if pos(comment.0BlockBegin,T)=1 then CommentFlag = \CommentFlag
        if CommentFlag then do
            if pos(comment.0BlockEnd,T)>0 then CommentFlag = \CommentFlag
            iterate
        end
                if flag.0debug then  say "match=" S "T=" T
        if mode=1 then do   /* exact match */
            /* if source has leading space then target must also have */
            if LspS & \LspT then iterate
            if left(T,stringlength)=S then do
                if flag.0debug then  say "match=" S "at=" i
                ret = ret i
                if direction \= 'A' then leave
            end
        end
        else do     /* floating match (*ID) */
            if pos(S,T) > 0 then do
                if pos(comment.0Tail,T) > 0 then
                   if pos(comment.0Tail,T) < pos(S,T) then iterate
                if pos(comment.0BlockBegin,T) > 0 then
                   if pos(comment.0BlockBegin,T) < pos(S,T) then iterate
                ret = ret i
                if direction \= 'A' then leave
            end
        end
    end
    return ret

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  Update Target file from Target. stem. Remove '       ' lines Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
SaveFile:
    if flag.0vback then call VBACK Tfile 'backing existing target'
    if Number.Changes=0 then return 0
    if Bkup <> "" then do
        address cmd 'copy' Tfile Bkup '1>nul 2>nul'
        if rc = 0 then say 'target:' Tfile 'is backed to:' Bkup
    end
    address cmd 'erase' TFile
    src = rc
    if src = 0 then do
        do i = 1 to Target.0
            if Target.i = '       ' then iterate
            rc=lineout(TFile,Target.i)
        end
        call close Tfile
        if flag.0vback then call VBACK Tfile 'backing new target'
    end
    return src


/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  InsertLine a line in Target file (stem) after line number i.             Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
InsertLine: procedure  expose Target. Number. flag. Proc. comment.
   parse arg i string
   if i = Target.0 then k = Target.0 + 1
   else do
      if i<comment.0Top then i = comment.0Top - 1
      do j = Target.0 to i+1 by -1
         k = j + 1
         Target.k = Target.j
      end
      k = i + 1
   end
   Target.k = string
   Target.0 = Target.0 + 1
   call logChange 'Inserted' k, Target.k
   return

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  returns a procedure command line  with all key words uppercased and
       spaced by 1, but delimited strings are both space and case preserved.
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
upkw: procedure expose delimit.
  parse arg sent
  dq = '"'
  quote = translate(sent,delimit.asciiless,delimit.ascii,dq)
  phrase = ""
  do forever
    if sent='' then leave
    pdq = pos(dq,quote)
    if pdq>0 then do
      parse var sent key =(pdq) d +1  str (d) sent
      phrase = phrase  translate(space(key)) d || str || d
      quote = right(quote,length(sent))
    end
    else do
       phrase = phrase translate(sent)
       leave
    end
  end
  return phrase

/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³  apply command line-specified substitutions within a string           Æ
   ³  apply env. variables substitutions to STRING if req. in OPTION.      Æ
   ³  return string, if missing value or flag.0test then ''                       Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
KeyEnvExpand: procedure expose KeyOpt. Flag. p Number.
  use arg String,opt.
  err = 0
   /* key */
   if GetOpt('KEY',opt.) then do
      c = GetStrOpt('#',opt.)
      out = ''
      do while string\=''
         parse var string x (c) skey (c) string
         out = out || x
         if skey = "" then leave
         if GetOpt(translate(skey),KeyOpt.) then val = GetStrOpt('',KeyOpt.)
         else val = ''
         out = out || val
         if val\='' then iterate
         rc=OnErrorDo(p,'No value for key' skey)          /*   process error         */
         err = 1
      end
      string = out
   end
      /* env */
   if GetOpt('ENV',opt.) then do
      c = GetStrOpt('%',opt.)
      out = ''
      do while string\=''
         parse var String x (c) name (c) String
         out = out || x
         if name = "" then leave
         env = value(name,,'OS2ENVIRONMENT')
         out = out || env
         if env\='' then iterate
         rc=OnErrorDo(p,'No value for enviroment variable' name)          /*   process error         */
         err = 1
      end
      String = out
   end
   if flag.0test | err then  return ''
   return String


/* ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
   ³ All that must be done to quit and more: say msg, save Target file if  Æ
   ³ necessary (type=1).                                                   Æ
   ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾  */
exitCube:
    parse arg type msg
    src=0
    Select
    When type=1 then do
        src = SaveFile()
        if src <> 0 then msg = msg 'Error writing' TFile
        else msg = msg 'commands:' Number.Commands 'changes:' Number.Changes 'errors:' Number.Errors
    end
    When type=2 then do
        src = Number.Changes
        msg = msg 'commands:' Number.Commands 'changes:' Number.Changes 'errors:' Number.Errors
    end
    Otherwise nop
    End
    say msg
    Exit src


/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ ONERROR [CONTINUE] [STOP] : what to do on syntax errors ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
ONERROR:
   select
      when Parms="CONTINUE" then flag.0StopOnErr = 0
      when Parms="STOP" then flag.0StopOnErr = 1
   otherwise rc=OnErrorDo(p,'On Error what ?')
   end  /* select */
   return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ WHEN     ... wordlist of when codes ...                 ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
APPLYWHEN:
   MWhen = strip(Parms,'B')
/**   say "WHEN" left(MWhen,1) "In" delimit.str
   if pos(left(MWhen,1),delimit.str)>0 then parse upper var MWhen d +1 MWhen (d)*/
   flag.0when = whenselected(Make,MWhen)
   if flag.0test then do
      if flag.0when then msg = "selected"
      else msg = "ignored"
      say "line" p msg "When" MWhen
   end /* do */
   return


/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ CASE [SENSITIVE] [IGNORE] : string compare mode         ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
CASE:
   if wordpos(Parms,'SENSITIVE IGNORE')>0 then flag.0CaseIns = left(Parms,1) == 'I'
      else rc=OnErrorDo(p,'Case what ?')
   return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ LINEID [NOSTRIP] [STRIP "x"]                            ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
LINEID:
   Parse var Parms type Parms
   Select
      When type = 'NOSTRIP' then LineID.strip = ""
      When type = 'STRIP' then do
         Parse value strip(Parms) with d +1 str (d)
         if length(str) <> 1 then rc=OnErrorDo(p,'Strip leading what ?')
         else LineID.strip = str
      end
      when type="PROFILE" then LineID.profileFlag = 1
   Otherwise rc=OnErrorDo(p,'Lineid what ?')
 end
 return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ COMMENT BEGIN "x" | BLOCK "x" TO "y" | TRAIL "x" | TOP "x"
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
COMMENT:
    Parse var Parms type Parms
    Parse value strip(Parms) with d +1 x (d) 'TO' Parms
    select
        when type='BEGIN' then comment.0Begin = x
        when type='BLOCK' then do
            Parse value strip(Parms) with d +1 y (d) Parms
            comment.0BlockBegin = x
            comment.0BlockEnd = y
        end /* do */
        when type='TOP' then do
           if datatype(x,'n') then comment.0Top = x + 1
           else do
              do i=1 to target.0
                 if pos(x,target.i)>0 then leave
              end
              comment.0Top = i + 1
           end /* do */
        end /* do */
        when type='TRAIL' then comment.0Tail = x
        otherwise rc=onerrordo(p,'unknown comment type!')
    end
    return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ REPLINE lineid WITH replacement [( options]             ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
REPLINE:
   parse var Parms d +1 Lineid (d) 'WITH' Parms
   parse value strip(Parms) with d +1 replace (d)  '(' Opt
   if Lineid = '' then do                           /* No line identifier      */
      rc=OnErrorDo(p,'Replace what line ?')
      return
   end
   if replace = '' then do                             /* No replacement string   */
      rc=OnErrorDo(p,'Replace line with ?')          /*   process error         */
      return                                         /*   ignore command        */
   end
   call ParseOpt Opt, fopt.
   replace = KeyEnvExpand(replace,fopt.)                           /* env substitution if req */
   direction = Searchdir(fopt.)                             /* What target lines ?     */
   mod = Lidmod(fopt.)                                /* floating line id ?      */
   select                                           /* What if no target lines?*/
      when GetOpt('ADDTOP',fopt.) then after=0      /* add after line 0        */
      when GetOpt('ADDBOTTOM',fopt.) then after=Target.0 /* add after last line     */
      when GetOpt('DONTADD',fopt.) then after=-1    /* don't add               */
      otherwise after=-1                             /* don't add is the default*/
   end
   if Ififnot(mod, fopt.) then return                         /* Process only when       */
   if replace='' then return
   where = Whereis(Lineid,direction,mod)                  /* Get target lines numbers*/
   if where \= '' then do                           /* if target(s) found      */
      do until where = ''                            /*   process all targets   */
         parse var where w where                      /*     1 at a time         */
         was = Target.w                               /* save old value for log  */
         Target.w = replace                              /*     target = replacmnt. */
         call logrep w,was,Target.w                   /*     log action          */
         if direction \= 'A' then leave                     /*     quit if not ALL     */
      end
   end
   else if after>-1 then call InsertLine after replace     /* if no target, try add   */
   return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ ADDLINE     line  [( options]                             ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         */
ADDLINE:
   parse var Parms d +1 Line (d)  '(' Opt
   if Line = '' then do                             /* No line identifier      */
      rc=OnErrorDo(p,'Add what line ?')              /*    process error        */
      return                                         /*    ignore command       */
   end
   call ParseOpt Opt, fopt.
   Line = KeyEnvExpand(Line,fopt.)                         /* env substitution if req */
   mod = Lidmod(fopt.)                                /* floating line id ?      */
   if Ififnot(mod, fopt.) then return
   if Line='' then return
   exist = Whereis(Line,'A',mod)                    /* all line exist */
   select                                           /* copies to add ?           */
      when GetOpt('COPY',fopt.) then do
          ncopy = KeyEnvExpand(GetStrOpt('0',fopt.), fopt.)  /* env substitution if req */
          if \datatype(ncopy,'n') then ncopy = 0
      end
      when GetOpt('IFNEW',fopt.) then ncopy = 1      /*   if not already there  */
      when GetOpt('ALWAYS',fopt.) then ncopy = words(exist) + 1     /*   even if already there */
      otherwise ncopy = 1                             /*   IFNEW is the default  */
   end
   ncopy = ncopy - words(exist)

   do while ncopy<0
      parse var exist w exist                      /*    one at a time        */
      call logChange 'Deleted' w, Target.w
      Target.w = '       '                 /*    mark for delete      */
      ncopy = ncopy + 1
   end

   do while ncopy>0
      select                                           /* Where to add ?          */
         when GetOpt('AFTER',fopt.) then do           /* 1) After a given line   */
            astr = GetStrOpt('',fopt.)      /*    line identifier ?    */
            if astr = '' then after = Target.0           /*    no id = add bottom   */
            else after = Whereis(astr,'F',mod)           /*    else get # of 1st    */
            parse var after after .                      /*    line with this id.   */
            if after='' then do                          /*    no match found       */
               if GetOpt('ONLY',fopt.) then after=-1     /*      if ONLY, don't add */
               else after=Target.0                     /*      else add bottom    */
            end
         end
         when GetOpt('BEFORE',fopt.) then do          /* 2) Before a given line  */
            bstr = GetStrOpt('',fopt.)     /*    line identifier ?    */
            if bstr = '' then after = 0                  /*    no id = add top      */
            else after = Whereis(bstr,'F',mod)           /*    else get # of 1st    */
            parse var after after .                      /*    line with this id.   */
            if after ='' then do                         /*    no match found       */
               if GetOpt('ONLY',fopt.) then after=-1     /*      if ONLY don't add  */
               else after=0                            /*      else add top       */
            end
            else after=max(0,after-1)                    /*    match found          */
         end
         otherwise after=Target.0                       /* 3) default = add bottom */
      end
      if after \= -1 then call InsertLine after Line       /* add the line            */
      ncopy = ncopy - 1
   end

   return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ ADDSTRING string IN lineid [(Options]                     ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         */
ADDSTRING:
   parse var Parms d1 +1 Woth (d1)  'IN' Parms
   parse value strip(Parms) with d2 +1 Lineid (d2)   '(' Opt
   if Lineid = '' then do                           /* No line identifier      */
      rc=OnErrorDo(p,'Add string where ?')           /*    process error        */
      return                                         /*    ignore command       */
   end
   if Woth = '' then do                             /* No string to add        */
      rc=OnErrorDo(p,'Add what string ?')            /*    process error        */
      return                                         /*    ignore command       */
   end
   call ParseOpt Opt, fopt.
   Woth = KeyEnvExpand(Woth,fopt.)                           /* env substitution if req */
   direction=Searchdir(fopt.)                               /* Which target line ?     */
   mod=Lidmod(fopt.)                                  /* floating line id ?      */
   where = Whereis(Lineid,direction,mod)                  /* Select target(s)        */
   flag.0debug = 1
   flag.0debug = 0
   if Woth='' then return
   if where \= '' then do                           /*   if target found       */
      do until where = ''                            /*     process target(s)   */
         parse var where w where                      /*     1 at a time         */
         if \flag.0CaseIns then do
            Tar= Target.w; Wi = Woth; end             /*     string compare mode */
         else do
            Tar = translate(Target.w); Wi=translate(Woth); end  /*     string compare mode */
         sep = right(Woth,1)                           /* make sure Tar is terminated */
         if right(Tar,1) \= sep then
            Tar = Tar || sep
         start = length(lineid) + 1

         begin = pos(Wi,Tar,start)
         select                                       /* Where to add ?          */
            when begin>0 & \GetOpt('ALWAYS',fopt.) then begin = 0     /* ALWAYS not specified.   */
            when GetOpt('AFTER',fopt.) then do        /* 1) After a given string */
               astr=GetStrOpt('',fopt.)                                  /*    defaulted to null    */
               If flag.0CaseIns then astr=translate(astr)
               if astr = '' | pos(astr,Tar,start)=0           /* if no string or no match*/
                  then begin = length(Tar)+1
               else begin = pos(astr,Tar,start)  + length(astr)
            end
            when GetOpt('BEFORE',fopt.) then do       /* 2) Before a given string*/
               bstr=GetStrOpt('',fopt.)                                  /*    defaulted to null    */
               If flag.0CaseIns then bstr=translate(bstr)
               if bstr = '' | pos(bstr,Tar,start)=0           /* if no string or no match*/
                  then begin = start
               else begin = pos(bstr,Tar,start)
            end
            otherwise nop
         end
         if begin>0 then do
            was = Target.w                          /*     save for logging    */
            Tar = was                               /*  delete using original target */
            if right(Tar,1) \= sep then
               Tar = Tar || sep
            parse var Tar first =(begin) rest
            Tar = first || Woth || rest
            if GetOpt('NOTERM',fopt.) then
               Tar = left(Tar,length(Tar)-1)
            Target.w = Tar
            call logrep w,was,Target.w              /*     log action          */
         end /* do */
         if direction \= 'A' then leave                     /* leave if not ALL targets*/
      end
   end
   else do                                          /* no target : add line ?  */
      if GetOpt('NOTERM',fopt.) then
         Woth = left(Woth,length(Woth)-1)
      if GetOpt('ADDTOP',fopt.) then call InsertLine 0 Lineid || Woth
      if GetOpt('ADDBOTTOM',fopt.) then call InsertLine Target.0 Lineid || Woth
   end
   return


/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ DELSTRING string IN lineid [(Options]                     ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ         */
DELSTRING:
   parse var Parms d1 +1 Woth (d1) 'IN' Parms
   parse value strip(Parms) with d2 +1 Lineid (d2)  '(' Opt
   if Lineid = '' then do                           /* No line identifier      */
      rc=OnErrorDo(p,'Add string where ?')           /*    process error        */
      return                                         /*    ignore command       */
   end
   if Woth = '' then do                             /* No string to add        */
      rc=OnErrorDo(p,'Add what string ?')            /*    process error        */
      return                                         /*    ignore command       */
   end
   call ParseOpt Opt, fopt.
   Woth = KeyEnvExpand(Woth,fopt.)                           /* env substitution if req */
   direction=Searchdir(fopt.)                               /* Which target line ?     */
   mod=Lidmod(fopt.)                                  /* floating line id ?      */
   if Woth='' then return
   where = Whereis(Lineid,direction,mod)                  /* Select target(s)        */
   if where \= '' then do                           /*   if target found       */
      do until where = ''                            /*     process target(s)   */
         parse var where w where                      /*     1 at a time         */
         if \flag.0CaseIns then do
            Tar= Target.w; Wi = Woth; end             /*     string compare mode */
         else do
            Tar = translate(Target.w); Wi=translate(Woth); end  /*     string compare mode */
         sep = right(Woth,1)                           /* make sure Tar is terminated */
         if right(Tar,1) \= sep then
            Tar = Tar || sep
         begin = pos(Wi,Tar)

        if begin > 0 then do                        /*     String is there?    */
            was = Target.w                          /*     save for logging    */
            Tar = was                               /*  delete using original target */
            sep = right(woth,1)                           /* make sure Tar is terminated */
            if right(Tar,1) \= sep then
               Tar = Tar || sep
            mid = length(woth)
            parse var Tar  first =(begin) +(mid) rest
            Tar = first || rest
            if GetOpt('NOTERM',fopt.) then
               Tar = left(Tar,length(Tar)-1)
            Target.w = Tar
            call logrep w,was,Target.w              /*     log action          */
        end
         if direction \= 'A' then leave                     /* leave if not ALL targets*/
      end
   end
   return


/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ REPSTRING ostring WITH nstring [IN lineid] [(Options]   ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
REPSTRING:
   parse var Parms d +1 Ostr (d)  'WITH' Parms
   parse value strip(Parms) with d +1 Woth (d)  type Parms
   if type="IN" then parse value strip(Parms) with d +1 Lineid (d)  '(' Opt
   else parse value type Parms with '(' Opt
   if Ostr = '' then do                             /* No old string specif.   */
      rc=OnErrorDo(p,'Replace what string ?')        /*    process error        */
      return                                         /*    ignore command       */
   end
  call ParseOpt Opt, fopt.
   Woth = KeyEnvExpand(Woth,fopt.)                           /* env substitution if req.*/
   direction=Searchdir(fopt.)                               /* Which target line ?     */
   mod=Lidmod(fopt.)                                  /* floating line id ?      */
   if Woth='' then return
   if flag.0CaseIns then Ostr = translate(Ostr)
   lenOstr = length(Ostr)
   where = Whereis(Lineid,direction,mod)                  /* Select target(s)        */
   do while where \= ''                             /*   if target found       */
         parse var where w where                      /*     1 at a time         */
         was = Target.w
         oldtar = was
         newtar = ''
         if flag.0CaseIns then Tar = translate(oldtar)
         do while Tar\=''
            begin = pos(Ostr,Tar)
            if begin=0 then leave
            parse var oldtar first =(begin) +(lenOstr) oldtar              /*     isolate string      */
            newtar = newtar || first || Woth           /*     replace occurrence  */
            Tar = oldtar
            if flag.0CaseIns then Tar = translate(Tar)
         end
         Target.w = newtar || oldtar
         call logrep w,was,Target.w                   /* log action              */
         if direction \= 'A' then leave                     /* leave if not ALL targets*/
   end
   return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ COMMENTLINE lineid WITH type [(options ]                ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
COMMENTL:
  parse var Parms d +1 Lineid (d) 'WITH' Parms
  parse value strip(Parms) with d +1 cmnt (d)  '(' Opt
  if Lineid = '' then do                           /* No identifier           */
    rc=OnErrorDo(p,'Comment what ?')               /*    process error        */
    return                                         /*    ignore command       */
  end
  if cmnt = '' then do                             /* No comment string       */
    rc=OnErrorDo(p,'Comment how ?')                /*    process error        */
    return                                         /*    ignore command       */
  end
   call ParseOpt Opt, fopt.
  direction=Searchdir(fopt.)                               /* Which target lines ?    */
  mod=Lidmod(fopt.)                                  /* floating line id ?      */
  if Ififnot(mod, fopt.) then return
  where= whereis(Lineid,direction,mod)                   /* get target lines #s     */
  if where \= '' then do                           /* if match(es) found      */
    do until where = ''                            /*   process target(s)     */
      parse var where w where                      /*   1 at a time           */
      was = Target.w                               /*  save for logging       */
      Target.w = cmnt Target.w                     /*   comment target        */
      call logrep w,was,Target.w                   /*   log action            */
      if direction \= 'A' then leave                     /* leave if not ALL targets*/
    end
  end
  return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ DELLINE lineid [(options ]                              ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
DELLINE:
  parse var Parms d +1 Lineid (d)   '(' Opt
  if Lineid = '' then do                           /* No identifier           */
    rc=OnErrorDo(p,'Delete what line ?')           /*    process error        */
    return                                         /*    ignore command       */
  end
   call ParseOpt Opt, fopt.
  Lineid = KeyEnvExpand(Lineid,fopt.)                       /* env substitution if req */
  direction=Searchdir(fopt.)                               /* Which target line(s) ?  */
  mod=Lidmod(fopt.)                                  /* floating line id ?      */
  if Ififnot(mod, fopt.) then return
   if Lineid='' then return
  where= whereis(Lineid,direction,mod)                   /* Get target lin(s) #s    */
  if where \= '' then do                           /* if match(es) found      */
    do until where = ''                            /*    process all targets  */
      parse var where w where                      /*    one at a time        */
      call logChange 'Deleted' w, Target.w
      Target.w = '       '                 /*    mark for delete      */
      if direction \= 'A' then leave                     /* leave if not ALL targets*/
    end
  end
  return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ SEARCHDIR: Direction for line search in Target File     ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
Searchdir: procedure
   use arg sdopt.
  select                                           /* What target lines ?     */
    when GetOpt('LAST', sdopt.) then direction='L'     /* set reverse search      */
    when GetOpt('FIRST', sdopt.) then direction='F'    /* set forward search      */
    otherwise direction='A'                              /* default is all lines    */
  end
  return direction

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ LIDMOD: Identify line at 1st col or anywhere in line    ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
Lidmod: procedure
   use arg sdopt.
  if GetOpt('*ID', sdopt.) then return(0)
                             else return(1)


/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ Stream functions (close & exists)                       ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
close:
  return stream(arg(1),'C','CLOSE')

exists:
  return stream(arg(1),'C','QUERY EXISTS')

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ Log a change in a target line                           ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
logrep: procedure expose Number. flag. Proc.
    parse arg ln,old,new
    if old<>new then call logChange 'Changed' ln, old, 'new', new
    return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ Log a change in a target line                           ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
logChange: procedure expose Number. flag. Proc.
    parse arg msg1,line1,msg2,line2
    if \flag.0verbose & proc.0lp\=proc.0p then do
        say
        say '>>>'  Proc.0proc
        proc.0lp = proc.0p
    end /* do */
    len1 = length(msg1)
    msg1 = ' 'msg1': "'line1'"'
    say msg1
    if msg2<>'' then say ' 'right(msg2,len1)': "'line2'"'
    Number.Changes = Number.Changes + 1
    return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ Print the usage.                                        ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
printUsage: procedure expose delimit. prgver
    say "CUBE" prgver 'Text configuration file updater.'
    say 'Usage:CUBE PFile TFile [Bkup] [(Opt]'
    say 'where'
    say '   PFile   name of CUBE command file'
    say '        or QUEUE (uppercase) REXX QUEUE'
    say '        or $single CUBE command$  (dynamic delimiter or braces {command})'
    say '   TFile   name of target file'
    say '   Bkup    name of backed up target file'
    say '   Opt     following options (can specify several)'
    say '       PAUSE            pause at each CUBE command line'
    say '       CHECK            do not save file'
    say '       VBACK            call VBACK at start and at end of program'
    say '       MAKE "cond"                  conditional execution'
    say '       KEY "k1 #v1# k2 #v2# ..."    assign key value pairs'
    say '       TEST             test MAKE, KEY and enviroment var. in dummy run'
    say 'note that all strings are dynamic delimit from the set' delimit.STR
    exit  -1
    return

/*      ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
        ³ Process IF/IFNOT  logic for Lines commands              ³
        ³    returns 1 if either condition is false !!            ³
        ³    returns 0 otherwise                                  ³
        ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ           */
Ififnot: procedure expose LineID. Target. Flag. comment.
   use arg mod, iifopt.
   if GetOpt('IF', iifopt.) then do
      istr = GetStrOpt('', iifopt.)
      if length(Whereis(istr,'F',mod))=0 then return 1
   end
   if GetOpt('IFNOT', iifopt.) then do
      istr = GetStrOpt('', iifopt.)
      if length(Whereis(istr,'F',mod))>0 then return 1
   end
   return 0


