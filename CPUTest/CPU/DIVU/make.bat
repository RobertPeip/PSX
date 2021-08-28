pushd %~dp0
armips CPUDIVU.asm
bin2exe.py CPUDIVU.bin CPUDIVU.exe
popd
