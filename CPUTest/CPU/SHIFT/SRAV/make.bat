pushd %~dp0
armips CPUSRAV.asm
bin2exe.py CPUSRAV.bin CPUSRAV.exe
popd
