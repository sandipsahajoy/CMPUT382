@echo off

set TEST_DIR=%1
set APP=Submission\Lab3.exe
set NAME=Parallel Merge

DEL /S %TEST_DIR%*myOutput.raw

echo var timestamp = '%time%'; > Marks.js

echo var text = '{"Marks": [' + >> Marks.js
echo '{"Section": "%NAME%", "Tests": [' +   >> Marks.js

FOR /L %%x IN (0,1,19) DO (
echo '{"Test": "Test %%x", "Output": [' +  >> Marks.js
set TEST=%TEST_DIR%%%x\
call:runTest
IF %%x LSS 19 (
	echo ']},' +  >> Marks.js
) ELSE (
	echo ']}' +  >> Marks.js
)
)

echo ']}' +  >> Marks.js
echo ']}'; >> Marks.js

echo.&goto:eof

:runTest
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t integral_vector > tmp.txt
for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a,' + >> Marks.js
)

echo Marking.exe -i %TEST%myOutput.raw,%TEST%output.raw -t integral_vector
Marking.exe -i %TEST%myOutput.raw,%TEST%output.raw -t integral_vector > tmp.txt

for /f "tokens=*" %%a in (tmp.txt) do (
	echo '%%a' + >> Marks.js
)

DEL tmp.txt

goto:eof