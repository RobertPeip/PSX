pushd %~dp0
armips CPUORI.asm
bin2exe.py CPUORI.bin CPUORI.exe
popd
