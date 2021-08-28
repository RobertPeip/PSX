pushd %~dp0
armips CPULB.asm
bin2exe.py CPULB.bin CPULB.exe
popd
