pushd %~dp0
armips CPUNOR.asm
bin2exe.py CPUNOR.bin CPUNOR.exe
popd
