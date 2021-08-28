pushd %~dp0
armips CPUSRA.asm
bin2exe.py CPUSRA.bin CPUSRA.exe
popd
