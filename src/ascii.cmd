/*  ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป
    บ  ASCII for formating ini data.
    บ                                                                       บ
    บ  15/09/03: V1.0 - Initial version (gjarvis@ieee.org)                  บ
    ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ */
call newascii
say "asciiFormat(ascii)=" asciiFormat("ascii")
say "asciiFormat(asciiZ)=" asciiFormat("ascii"||D2C(0))
say "asciiFormat(binary)=" asciiFormat(x2c("02030405"))
exit 0




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
    
    
