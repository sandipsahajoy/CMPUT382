@echo off

set TEST_DIR=Dataset\Test\
set APP=Submission\CPU_MatMul.exe
set NAME=CPU Matrix Multiplication

DEL /S %TEST_DIR%*myOutput.raw

echo var timestamp = '%time%'; > Marks.js

echo var text = '{"Marks": [' + >> Marks.js
echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,8) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 8 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']},' +  >> Marks.js

set APP=Submission\GPU_MatMul.exe
set NAME=GPU Matrix Multiplication

DEL /S %TEST_DIR%*myOutput.raw

echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,8) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 8 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']},' +  >> Marks.js

set APP=Submission\OPT_MatMul.exe
set NAME=Optimized GPU Matrix Multiplication

DEL /S %TEST_DIR%*myOutput.raw

echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,8) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 8 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']},' +  >> Marks.js

echo '{"Section": "Time", "Tests": [' +  >> Marks.js

set TEST=Dataset\Test\9\
set APP=Submission\GPU_MatMul.exe

echo '{"CMD": "GPU_MatMul", "Output": [' + >> Marks.js
call:runTest
echo ']},' + >> Marks.js

set APP=Submission\OPT_MatMul.exe

echo '{"CMD": "OPT_MatMul", "Output": [' + >> Marks.js
call:runTest
echo ']}' + >> Marks.js
echo ']}' + >> Marks.js
echo ']}'; >> Marks.js

echo.&goto:eof

:runTest
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t matrix > tmp.txt
for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a,' + >> Marks.js
)

echo Marking.exe -i %TEST%myOutput.raw,%TEST%output.raw -t matrix
Marking.exe -i %TEST%myOutput.raw,%TEST%output.raw -t matrix > tmp.txt

for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a' + >> Marks.js
)

DEL tmp.txt

goto:eof