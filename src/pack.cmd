/* package cube */
"@echo off"
src = directory("..")
curpath = directory("package")
dest = curpath"\cube"
publish = left(curpath,3) || "pub_html\cube" /* my local web page mirror */

"dir /b" src"\doc\*.txt > name"
parse value linein("name") with pkg ".txt"
call stream "name", "c", "close"
say "src=" src "dest=" dest "curpath=" curpath "publish=" publish "packing" pkg
pause

call pack "*.cmd", "*.cmd.sam"
call pack "bin\*.cmd"
call pack "src\*.cmd"
call pack "doc\*.*"
call pack "text\*.cub", "text\*.cub.sam"
call pack "text\*.cmd"
call pack "text\test.cub*"
call pack "ini\*.lst", "ini\*.lst.sam"
call pack "class\*.lst", "class\*.lst.sam"
call pack "wps\*.lst", "wps\*.lst.sam"
copy  src"\doc\*.diz" curpath

md dest"\copy"
md dest"\copy\system"
md dest"\copy\network"
md dest"\package"
md dest"\package\cube"
md dest"\text\sam"

"dir /b /s" curpath ">dir"

del "/n *.zip"
address cmd "zip -mr" pkg "cube\*"
address cmd "zip -m" pkg "*.diz"

"del /n" publish"\*"
copy pkg".zip" publish
copy src"\doc\*.css" publish
copy src"\doc\*.html" publish

copy  src"\doc\*.txt" curpath

say "enter 2hobbes in directory" curpath "and run sitecopy"
exit 0


pack:  procedure expose src dest
    parse arg from, to
    if to="" then to = from
    xcopy src'\'from  dest'\'to
    return

