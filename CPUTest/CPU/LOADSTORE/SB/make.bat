pushd %~dp0
armips CPUSB.asm
bin2exe.py CPUSB.bin CPUSB.exe
popd
