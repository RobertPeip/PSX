pushd %~dp0
armips CPUMULTU.asm
bin2exe.py CPUMULTU.bin CPUMULTU.exe
popd
