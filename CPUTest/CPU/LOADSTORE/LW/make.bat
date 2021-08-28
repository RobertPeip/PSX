pushd %~dp0
armips CPULW.asm
bin2exe.py CPULW.bin CPULW.exe
popd
