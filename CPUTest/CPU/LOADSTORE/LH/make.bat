pushd %~dp0
armips CPULH.asm
bin2exe.py CPULH.bin CPULH.exe
popd
