## PSX Tests

Collection of assembler applications by Krom.
Expanded to test more details of the original PSX hardware.

Timing: 
- TimingCPU: test internal CPU performance - normal commands, mul and div
- TimingLoadRAM: test sdram read performance and pipelinging behavior
- TimingStoreRAM: test sdram write performance and writefifo behavior
- TimingLoadReg: test read performance from different busses
- TimingStoreReg: test write performance to different busses

Timer:
- TimerCalib: test resetting timer and reading it for calibration. Also TMR2 in Div8 mode and wraparound at 0xFFFF
- TimerWrap: test wraparounds at different target values
- TimerSet: Test various combinations of writing current, target and reset

Bus:
- LoadStoreReg: check 4 byte aligned reads/writes to different busses
- LoadStoreRegUnalign8: check byte reads/writes to different busses with offset 1,2 or 3
- LoadStoreRegUnalign16: check halfword reads/writes to different busses with offset 0 and 2
- Load816Unalign: check readback with bus rotation from different busses

GTE:
- GTETransfer: check all GTE opcodes timing and pipeline behavior 
- GTETiming: check execution time of all GTE commands

DMA:
- DMATimingToDevice: testing DMA to SPU performance and delays. TODO: should be renamed or contain more devices
- DMAOTCData: check data integrity and speed or different OTC DMA sizes

Pipeline:
- PipelineInternelRegs: testing write pipelining and write queue using writes and (stalling) reads to Timer registers
- PipelineRAMwrite: testing write pipelining and write queue using writes and Main RAM
- PipelineRAMread: testing timing of reads from Main RAM
- PipelineSPU: testing write pipelining and write queue using writes and (stalling) reads to SPU registers
- PipelineCD: testing write pipelining and write queue using writes and (stalling) reads to CD registers

ExtBUS:
- ExtBusBusWidth: testing timing using different width
- ExtBusDelay: testing timing using different read/write delays
- ExtBusFloatRelease: testing timing with FloatRelease on/off
- ExtBusHold: testing timing with Hold on/off
- ExtBusPreStrobe: testing timing with Pre-Strobe on/off
- ExtBusRecovery: testing timing Recovery on/off

-------------
Original readme from Krom

<br />
PSX Bare Metal Code by krom (Peter Lemon).<br />
<br />
All code compiles out of box with the Armips assembler by Kingcom.<br />
https://github.com/Kingcom/armips/<br />
http://buildbot.orphis.net/armips/<br />
I have included binaries & executables of all the demos.<br />
<br />
Special thanks to the Hitmen demo group, who with their asm sources, helped me get into PSX Coding =D<br />
http://hitmen.c02.at/html/psx_sources.html<br />
<br />
Also I'd like to thank ARM9, who made the bin2exe.py file, to convert my PSX binaries into PSX exectuables.<br />
https://github.com/ARM9/psxdev/blob/master/libpsx/tools/bin2exe.py<br />
<br />
Please check out NO$PSX, a PSX emulator/debugger by Martin Korth:<br />
http://problemkaputt.de/psx.htm<br />
<br />
Also MAME has a great PSX emulator/debugger by smf:<br />
https://www.mamedev.org/<br />
<br />
Howto Compile:<br />
All the code compiles into a single binary & executable (NAME.EXE) file.<br />
Using Armips Run: make.bat<br />
<br />
Howto Run:<br />
I only test with a real PSX.<br />
<br />
You can also use PSX emulators like NO$PSX which can load PSX executables directly, & MAME using this command:<br />
mame pse -quik NAME.EXE
