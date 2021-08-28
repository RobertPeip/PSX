pushd %~dp0
armips CPUADDIU.asm
bin2exe.py CPUADDIU.bin CPUADDIU.exe
popd
