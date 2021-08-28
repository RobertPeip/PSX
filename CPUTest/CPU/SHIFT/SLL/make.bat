pushd %~dp0
armips CPUSLL.asm
bin2exe.py CPUSLL.bin CPUSLL.exe
popd
