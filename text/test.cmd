/* test cube */
'@echo off > test.txt'
"set name=Smith"
/*"start cube test.cub test.txt (make !advance usb!  key @name #John Smith#@" "> test.log"*/
call cube "test.cub test.txt (make !advance usb!  key @name #John Smith#@ test"
'pause'
call cube "test.cub test.txt (make !advance usb!  key @name #John Smith#@"
'pause'
'epm test.*'
