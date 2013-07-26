/* test */

parse source sys .
say "Running" sys

parse version rxver
say "REXX interpeter" rxver

/* OS independent */
call rxfuncadd sysloadfuncs, rexxutil, sysloadfuncs
call sysloadfuncs

If RxFuncQuery("SysUtilVersion") = 0  then
    say 'REXX util version' SysUtilVersion()

If RxFuncQuery("SysVersion") = 0 then
    osver = SysVersion()
else do
    say  "can not determine OS"
    exit -1
end

/* OS specific */
select
   when pos(osver,'OS/2') = 0 then do
        ver = Sysos2ver()
        osver = translate('123458796', osver, '123456789')
        parse value value('PATH',,'OS2ENVIRONMENT') with .  ":\OS2;" -1 bootpath +3 .
/*        bootPath = drive || ':\'*/
        unixflag = 0
        osver = osver 'on' bootpath
    end
   when pos(osver,'Linux') = 0 then do
        osver = SysLinver()
        bootPath = 'C:\' /* replace C:\ with C:\ = don't do anything */
        unixflag = 1
    end
otherwise
    say  "No support for" osver
    exit -1
end  /* select */

/* generic code */
        say 'running' osver

