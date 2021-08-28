pushd %~dp0
armips CPUANDI.asm
bin2exe.py CPUANDI.bin CPUANDI.exe
popd
