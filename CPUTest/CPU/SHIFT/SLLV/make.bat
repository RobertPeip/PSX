pushd %~dp0
armips CPUSLLV.asm
bin2exe.py CPUSLLV.bin CPUSLLV.exe
popd
