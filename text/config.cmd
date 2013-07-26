/* test cube config.sys */
copy "c:\vback\config.sys.000 sam\config.sys"
address cmd 'start "config" /b/c cube config.cub sam\config.sys sam\config.bak >sam\config.log'
pause
'gfc' 'sam\config.sys' 'sam\config.bak'
epm 'config.*' 'sam\config.*'  '..\orx\cube.cmd ..\doc\cube.html'
