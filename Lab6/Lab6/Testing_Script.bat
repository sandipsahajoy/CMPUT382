@echo off

set TEST_DIR=Dataset\Test\
set APP=Submission\Convolution.exe
set NAME=Convolution

DEL /S %TEST_DIR%*myOutput.ppm

echo var timestamp = '%time%'; > Marks.js

echo var text = '{"Marks": [' + >> Marks.js
echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,7) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 7 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']},' +  >> Marks.js

set APP=Submission\Tiled_Convolution.exe
set NAME=Tiled Convolution

DEL /S %TEST_DIR%*myOutput.ppm

echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,7) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 7 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']}' +  >> Marks.js
echo ']}'; >> Marks.js

echo.&goto:eof

:runTest
%APP% -e %TEST%output.ppm -i %TEST%input0.ppm,%TEST%input1.raw -o %TEST%myOutput.ppm -t image > tmp.txt
for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a,' + >> Marks.js
)

echo '{"data": {"Done": true, "message": "The test is done"}, "type": "Done"}' + >> Marks.js

DEL tmp.txt

goto:eof