pushd %~dp0
armips CPUXORI.asm
bin2exe.py CPUXORI.bin CPUXORI.exe
popd
