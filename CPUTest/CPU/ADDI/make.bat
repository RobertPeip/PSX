pushd %~dp0
armips CPUADDI.asm
bin2exe.py CPUADDI.bin CPUADDI.exe
popd
