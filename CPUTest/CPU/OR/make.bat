pushd %~dp0
armips CPUOR.asm
bin2exe.py CPUOR.bin CPUOR.exe
popd
