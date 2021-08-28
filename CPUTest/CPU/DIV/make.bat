pushd %~dp0
armips CPUDIV.asm
bin2exe.py CPUDIV.bin CPUDIV.exe
popd
