pushd %~dp0
armips CPUSRLV.asm
bin2exe.py CPUSRLV.bin CPUSRLV.exe
popd
