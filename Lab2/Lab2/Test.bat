@echo off
set TEST_DIR=Dataset\VectorAdd\Test\
set APP=Test\VectorAdd.exe

DEL /S %TEST_DIR%*myOutput.raw

echo Vector Add Testing Test 0...
set TEST=%TEST_DIR%0\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 1...
set TEST=%TEST_DIR%1\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error

echo Vector Add Testing Test 2...
set TEST=%TEST_DIR%2\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 3...
set TEST=%TEST_DIR%3\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 4...
set TEST=%TEST_DIR%4\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 5...
set TEST=%TEST_DIR%5\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 6...
set TEST=%TEST_DIR%6\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 7...
set TEST=%TEST_DIR%7\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 8...
set TEST=%TEST_DIR%8\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 

echo Vector Add Testing Test 9...
set TEST=%TEST_DIR%9\

echo %APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector
%APP% -e %TEST%output.raw -i %TEST%input0.raw,%TEST%input1.raw -o %TEST%myOutput.raw -t vector >NUL

FC %TEST%output.raw %TEST%myOutput.raw >NUL && Echo Same || Echo Different or error 
@echo on