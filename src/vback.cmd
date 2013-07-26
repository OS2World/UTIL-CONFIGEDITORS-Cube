/* intelligent backup fname to vback*/
'@echo off'

call RxFuncAdd 'SysFileTree', 'RexxUtil', 'SysFileTree'
address cmd

if arg()=0 then do
    say "usage::vback <file> [msg]"
    say "file       name of file"
    say "msg        message to use"
    exit 1
end

parse arg fname msg
vback = "vback"

s = lastpos('\',fname)
if s=0 then path = vback
else path = left(fname,s)||vback
name = substr(fname,s+1)

call SysFileTree fname, 'file', 'F'
n = file.0  
if n=0 then exit 1
existDate = left(file.1,16)

call SysFileTree path, 'file', 'D'
n = file.0  
if n=1 then do
    
    call SysFileTree path'\'name'.*', 'file', 'F'
    n = file.0  
    if n>0 then do
        backDate = left(file.n,16)
        if existDate=backDate then  exit 1
        num = right(file.n,3)  + 1
    end /* do */
    else num = 0
end
else do
   address cmd 'md' path '1>nul: 2>nul:'
   num = 0
end /* do */


if length(num)=1 then
    num  =  '00'num
else do
    if length(num)=2 then
        num  = '0'num
    else
        num  = num
end
fnamenum  = path'\'name'.'num

if msg='' then msg = "Backing"
say msg fname 'with' existDate 'to vback\*.'num
address cmd 'copy'  fname fnamenum '1>nul: 2>nul:'

exit 0

