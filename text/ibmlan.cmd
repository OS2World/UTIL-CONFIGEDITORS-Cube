/* test cube */
call cube 'ibmlan.cub' 'sam\ibmlan.ini' 'sam\ibmlan.bak' '(brief'
pause
'gfc' 'sam\ibmlan.ini' 'sam\ibmlan.bak'
epm 'ibmlan.cub' 'sam\ibmlan.*'
