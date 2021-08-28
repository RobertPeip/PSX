pushd %~dp0
armips CPUADDU.asm
bin2exe.py CPUADDU.bin CPUADDU.exe
popd
