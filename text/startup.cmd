/* test cube */
call cube 'startup.cub' 'sam\startup.cmd' 'sam\startup.bak'
pause
'gfc' 'sam\startup.cmd' 'sam\startup.bak'
epm 'startup.cub' 'sam\startup.*'
