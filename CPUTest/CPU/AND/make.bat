pushd %~dp0
armips CPUAND.asm
bin2exe.py CPUAND.bin CPUAND.exe
popd
