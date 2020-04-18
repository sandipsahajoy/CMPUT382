@echo off

set TEST_DIR=Dataset\Test\
set APP=Submission\OpenCL.exe
set NAME=OpenCL

DEL /S %TEST_DIR%*myOutput.raw

echo var timestamp = '%time%'; > Marks.js

echo var text = '{"Marks": [' + >> Marks.js
echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,9) DO (
echo Testing %NAME% with test %%x
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 9 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']}' +  >> Marks.js
echo ']}'; >> Marks.js

echo.&goto:eof

:runTest
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector > tmp.txt
for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a,' + >> Marks.js
)

echo '{"data": {"Done": true, "message": "The test is done"}, "type": "Done"}' + >> Marks.js

DEL tmp.txt

goto:eof
