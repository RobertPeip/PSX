pushd %~dp0
armips CPUADD.asm
bin2exe.py CPUADD.bin CPUADD.exe
popd