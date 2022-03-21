; PSX 'Bare Metal' Test of random CPU2VRAM
.psx
.create "MemoryTransferRandom2VRAM.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros

.org 0x80010000 ; Entry Point Of Code

la a0,IO_BASE ; A0 = I/O Port Base Address ($1F80XXXX)

; Setup Screen Mode
WRGP1 GPURESET,0  ; Write GP1 Command Word (Reset GPU)
WRGP1 GPUDISPEN,0 ; Write GP1 Command Word (Enable Display)
WRGP1 GPUDISPM,HRES320+VRES240+BPP15+VNTSC ; Write GP1 Command Word (Set Display Mode: 320x240, 15BPP, NTSC)
WRGP1 GPUDISPH,0xC60260 ; Write GP1 Command Word (Horizontal Display Range 608..3168)
WRGP1 GPUDISPV,0x042018 ; Write GP1 Command Word (Vertical Display Range 24..264)

; Setup Drawing Area
WRGP0 GPUDRAWM,0x000400   ; Write GP0 Command Word (Drawing To Display Area Allowed Bit 10)
WRGP0 GPUDRAWATL,0x000000 ; Write GP0 Command Word (Set Drawing Area Top Left X1=0, Y1=0)
WRGP0 GPUDRAWABR,0x03BD3F ; Write GP0 Command Word (Set Drawing Area Bottom Right X2=319, Y2=239)
WRGP0 GPUDRAWOFS,0x000000 ; Write GP0 Command Word (Set Drawing Offset X=0, Y=0)

; clear screen
FillRectVRAM 0xFFFFFF, 0,0, 1023,511 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height

; T1 = Data transfer dword
; T2 = color value
; T3 = size x
; T4 = size y
; T5 = pos x
; T6 = pos y
; T7 = Data Copy Word Count
; T8 = RandomX 
; T9 = RandomY 
; S1 = EndX 
; S2 = EndY

li s1, 1024
li s2, 512

li t2, 0
li t8, 1 

xloop:
   li t9, 1
   yloop:
      move t3, t8
      move t4, t9
      li t5, 0
      li t6, 0
      
      ; generate copy size in DWords - 1
      mult t3, t4
      mflo t7
      move t0, t7
      srl t7, 1 
      andi t0, 1
      bnez t0, skipreduce
      nop
         subi t7, 1
      skipreduce:
      
      CopyRectCPUV t5,t6,t3,t4 ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height
      
      vram2cpuLoop:
         move t1,t2
         addiu t2, 1 
         
         sw t1,GP0(a0) ; Write GP0 Packet Word
         
         bnez t7,vram2cpuLoop ; IF (T7 != 0)
         subiu t7,1 ; T7-- (Delay Slot)
   
      addi t9, 1
      ble t9, s2, yloop
      nop
      
   addi t8, 1
   ble t8, s1, xloop
   nop



Loop:
  b Loop
  nop ; Delay Slot

.close