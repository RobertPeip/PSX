pushd %~dp0
armips CPUSUB.asm
bin2exe.py CPUSUB.bin CPUSUB.exe
popd
