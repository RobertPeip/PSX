pushd %~dp0
armips CPUXOR.asm
bin2exe.py CPUXOR.bin CPUXOR.exe
popd
