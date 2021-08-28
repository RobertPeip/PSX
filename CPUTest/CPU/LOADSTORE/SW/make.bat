pushd %~dp0
armips CPUSW.asm
bin2exe.py CPUSW.bin CPUSW.exe
popd
