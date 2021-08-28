pushd %~dp0
armips CPUSH.asm
bin2exe.py CPUSH.bin CPUSH.exe
popd
