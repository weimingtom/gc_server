@echo off

del game.zip

md .\game
xcopy .\project .\game /E
cd game
md sql
md doc
xcopy ..\sql\ss .\sql /E
xcopy ..\doc\Readme .\doc /E
cd ..
del game\log\*.* /q
del game\Debug\*.* /q
del game\Release\*.pdb /q
del game\Release\*.lib /q
del game\Release\*.exp /q
del game\Release\GameFishing.exe
del game\Release\GameFishingDLL.exe

7z a -tzip game.zip -r ".\game\*"

rd game /s /q

pause
