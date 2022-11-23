## PSX Tests

Collection of assembler applications. Many tests and library by Krom.

Expanded with the following tests to cover more details of the original PSX hardware:

Timing: 
- TimingCPU: test internal CPU performance - normal commands, mul and div
- TimingLoadRAM: test sdram read performance and pipelinging behavior
- TimingStoreRAM: test sdram write performance and writefifo behavior
- TimingLoadReg: test read performance from different busses
- TimingStoreReg: test write performance to different busses
- TimingGPUSTAT_Vsync240p: test GPUSTAT behavior starting with vsync(tested against 7502) -> timing measured in div/8 clk cycles and line count
- TimingGPUSTAT_Vsync480i: test GPUSTAT behavior starting with vsync(tested against 7502) -> timing measured in div/8 clk cycles

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
- DMAPARALLEL: testing DMA and CPU running in parallel(CPU does not stall when DMA is running unless memory or IO regs are accessed)
- DMACPUStall: testing which actions will stop DMA and CPU running in parallel
- DMAAling: testing DMA speed for different start addresses
- DMATimingToDevice: testing DMA to SPU performance and delays. TODO: should be renamed or contain more devices
- DMAOTCData: check data integrity and speed of different OTC DMA sizes
- DMACD: check speed of different DMA sizes
- DMAGPU: check speed of different DMA sizes
- DMAMDECIN: check speed of different DMA sizes
- DMAMDECOUT: check speed of different DMA sizes
- DMASPU: check speed of different DMA sizes
- DMASPUDELAY: check SPU DMA speed for different memctrl settings
- DMABLOCKGPU: check DMA speed and pausing between blocks in request mode for different block sizes and block counts
- DMALINKEDLIST: check DMA speed and pausing between blocks in linked list mode for different block sizes and list lengths
- DMAWrap: check if data is written to RAM when wrapping around 2/8MByte address borders -> screenshot attached to compare against HW 

Pipeline:
- PipelineInternelRegs: testing write pipelining and write queue using writes and (stalling) reads to Timer registers
- PipelineRAMwrite: testing write pipelining and write queue using writes and Main RAM
- PipelineRAMread: testing timing of reads from Main RAM
- PipelineSPU: testing write pipelining and write queue using writes and (stalling) reads to SPU registers
- PipelineCD: testing write pipelining and write queue using writes and (stalling) reads to CD registers
- PipelineCPULoadDelay: testing loaded data for various load and load-after-load situation
- PipelineInstructionCache: testing cache fetch timing from aligned and unaligned addresses
- PipelineInstructionNoCache: testing execution timing without instruction cache and combination with parallel store/load
- PipelineInstructionBIOS: testing execution timing with cached and uncached BIOS instruction (tested against 7502)

ExtBUS:
- ExtBusBusWidth: testing timing using different width
- ExtBusDelay: testing timing using different read/write delays
- ExtBusFloatRelease: testing timing with FloatRelease on/off
- ExtBusHold: testing timing with Hold on/off
- ExtBusPreStrobe: testing timing with Pre-Strobe on/off
- ExtBusRecovery: testing timing Recovery on/off

JOY:
- Joypad: tests data connection and latency/timing for any pad connected to port 1

Hint: most timing tests will fail if the basic TimerCalib tests are not pass

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
