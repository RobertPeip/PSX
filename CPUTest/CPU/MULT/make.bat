pushd %~dp0
armips CPUMULT.asm
bin2exe.py CPUMULT.bin CPUMULT.exe
popd
