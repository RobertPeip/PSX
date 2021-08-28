pushd %~dp0
armips CPUSRL.asm
bin2exe.py CPUSRL.bin CPUSRL.exe
popd
