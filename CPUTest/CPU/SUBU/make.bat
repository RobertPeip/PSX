pushd %~dp0
armips CPUSUBU.asm
bin2exe.py CPUSUBU.bin CPUSUBU.exe
popd
