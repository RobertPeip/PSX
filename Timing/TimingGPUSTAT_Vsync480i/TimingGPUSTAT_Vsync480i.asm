; PSX 'Bare Metal' Test
.psx
.create "TimingGPUSTAT_Vsync480i.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro storeArrayWord,source,base,index

   la a2,base
   sll t0, index, 2
   addu a2,t0
   sw source,0(a2)
   nop

.endmacro

.macro loadArrayWord,target,base,index

   la a2,base
   sll t0, index, 2
   addu a2,t0
   lw target,0(a2)
   nop

.endmacro

;-----------------------------------------------------------------------------
; initialize video
;-----------------------------------------------------------------------------

la a0,IO_BASE ; A0 = I/O Port Base Address ($1F80XXXX)

; Setup Screen Mode
WRGP1 GPURESET,0  ; Write GP1 Command Word (Reset GPU)
WRGP1 GPUDISPEN,0 ; Write GP1 Command Word (Enable Display)
WRGP1 GPUDISPM,HRES320+VRES480+INTERLACE+BPP15+VNTSC ; Write GP1 Command Word (Set Display Mode: 640x480, INTERLACE, 15BPP, NTSC)
WRGP1 GPUDISPH,0x00c58258 ; Write GP1 Command Word (Horizontal Display Range
WRGP1 GPUDISPV,0x00040010 ; Write GP1 Command Word (Vertical Display Range

; Setup Drawing Area
WRGP0 GPUDRAWM,0x000400   ; Write GP0 Command Word (Drawing To Display Area Allowed Bit 10)
WRGP0 GPUDRAWATL,0x000000 ; Write GP0 Command Word (Set Drawing Area Top Left X1=0, Y1=0)
WRGP0 GPUDRAWABR,0x03BD3F ; Write GP0 Command Word (Set Drawing Area Bottom Right X2=319, Y2=239)
WRGP0 GPUDRAWOFS,0x000000 ; Write GP0 Command Word (Set Drawing Offset X=0, Y=0)

; clear screen
FillRectVRAM 0x000000, 0,0, 1023,511 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height

;-----------------------------------------------------------------------------
; test prepare
;-----------------------------------------------------------------------------

li t0,0x0000
sw t0,I_MASK(a0)

li t0,0
mtc0 t0,sr

;-----------------------------------------------------------------------------
; test execution
;-----------------------------------------------------------------------------

li s6, 20 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 80,s6,TEXT_PS1
PrintText 140,s6,TEXT_CYCLES
PrintText 200,s6,TEXT_PS1MIN
PrintText 260,s6,TEXT_PS1MAX
addiu s6,10

; wait for 2 vsyncs
li s1, 2
waitfirstvsync:  
   li t1,0x0001
   lw t0,I_STAT(a0)
   nop
   and t0,t1
   bne t0,t1,waitfirstvsync 
   nop
   li t1,0
   sw t1,I_STAT(a0)
   bnez s1, waitfirstvsync
   subiu s1,1

; capture status before vsync and wait for vsync
li s3,0
li t1,0x0001
waitvsync:  
   move s2,s1
   lw s1,GPUSTAT(a0)
   lw t0,I_STAT(a0)
   nop
   and t0,t1
   bne t0,t1,waitvsync
   nop
   storeArrayWord s2, DATARECEIVE, s3

WRIOH T2_CNTM,0x0200 ; reset and clk/8
; capture some status changes after vsync
li s3,1
li s4,8
gpustat_loop:
   RDIOW GPUSTAT,s1
   beq s1,s2,nochange
   nop
   RDIOH T2_CNT,s5
   RDIOH T2_CNTM,s7
   WRIOH T2_CNTM,0x0200 ; reset and clk/8
   storeArrayWord s1, DATARECEIVE, s3
   
   ; add 0x10000 in case of overflow
   li t0, 0x1000
   and s7, t0
   beqz s7,nooverflow
   nop
   li t0,0x10000
   addu s5,t0
   nooverflow:
   
   storeArrayWord s5, TIMERECEIVE, s3
   move s2,s1
   addiu s3,1
   nochange:
   bne s3,s4, gpustat_loop
   nop
   
WRGP1 GPUDISPV,0x00040011 ; Write GP1 Command Word (Vertical Display Range
   
; capture more status changes after Vertical Display Range update
li s4,14
gpustat_loop2:
   RDIOW GPUSTAT,s1
   beq s1,s2,nochange2
   nop
   RDIOH T2_CNT,s5
   RDIOH T2_CNTM,s7
   WRIOH T2_CNTM,0x0200 ; reset and clk/8
   storeArrayWord s1, DATARECEIVE, s3
   
   ; add 0x10000 in case of overflow
   li t0, 0x1000
   and s7, t0
   beqz s7,nooverflow2
   nop
   li t0,0x10000
   addu s5,t0
   nooverflow2:
   
   storeArrayWord s5, TIMERECEIVE, s3
   move s2,s1
   addiu s3,1
   nochange2:
   bne s3,s4, gpustat_loop2
   nop

; print out word before vsync
li s3,0
loadArrayWord s1, DATARECEIVE, s3
PrintHexValue 10,s6,s1
loadArrayWord s2, DATAPS1, s3
PrintHexValue 80,s6,s2

; add 1 to testcount
la a2,TESTCOUNT
lw t1, 0(a2)
nop
addiu t1,1
sw t1, 0(a2)

; check value
bne s1,s2,testfail_first
nop
; add 1 to tests passed
la a2,TESTSPASS
lw t1, 0(a2)
nop
addiu t1,1
sw t1, 0(a2)
testfail_first:

addiu s6,10
PrintText 20,s6,TEXT_VSYNC
addiu s6,10

; print out all status changes and check for errors
li s3,1
li s4,14
print_loop:
   ; print
   loadArrayWord s1, DATARECEIVE, s3
   PrintHexValue 10,s6,s1
   loadArrayWord s1, DATAPS1, s3
   PrintHexValue 80,s6,s1
   loadArrayWord s1, TIMERECEIVE, s3
   PrintDezValue 150,s6,s1
   loadArrayWord s1, TIMEMIN, s3
   PrintDezValue 210,s6,s1
   loadArrayWord s1, TIMEMAX, s3
   PrintDezValue 270,s6,s1

   
   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; check value
   loadArrayWord s1, DATARECEIVE, s3
   loadArrayWord s2, DATAPS1, s3
   bne s1,s2,testfail
   nop
   
   ; check min
   loadArrayWord s1, TIMERECEIVE, s3
   loadArrayWord s2, TIMEMIN, s3
   sltu t0, s1, s2
   bnez t0,testfail
   nop
   
   ; check max
   loadArrayWord s2, TIMEMAX, s3
   sltu t0, s2, s1
   bnez t0,testfail
   nop
   
   ; add 1 to tests passed
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfail:
   
   addiu s3,1
   addiu s6,10
   bne s3,s4, print_loop

; results
la a2,TESTSPASS
lw s2, 0(a2)
nop
PrintDezValue 20,s6,s2

PrintText 40,s6,TEXT_OUTOF

la a2,TESTCOUNT
lw s2, 0(a2)
nop
PrintDezValue 100,s6,s2

PrintText 120,s6,TEXT_TP

endloop:
  b endloop
  nop ; Delay Slot

;-----------------------------------------------------------------------------
; constants area
;-----------------------------------------------------------------------------

.align 4

FontBlack: .incbin "../../LIB/FontBlack8x8.bin"
  
VALUEWORDG: .dw 0xFFFFFFFF

TESTCOUNT: .dw 0x0
TESTSPASS: .dw 0x0

.align 4
DATARECEIVE: .dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
TIMERECEIVE: .dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

DATAPS1    : .dw 0x144A2400,0x144A0400,0x944A0400,0x144A0400,0x144A2400,0x144A0400,0x944A0400,0x144A0400,0x144A2400,0x144A0400,0x944A0400,0x144A0400,0x144A2400,0x144A0400
TIMEMIN    : .dw 0,67161,4612,65167,1356,71412,4612,65167,1356,71411,4884,64896,1356,71412
TIMEMAX    : .dw 0,67163,4615,65168,1358,71414,4615,65168,1358,71414,4886,64897,1358,71414
  
TEXT_TEST:       .db "TEST",0
TEXT_PS1:        .db "PS1",0
TEXT_OUTOF:      .db "OUT OF ",0
TEXT_TP:         .db "TESTS PASS",0
TEXT_CYCLES:     .db "CYCLES",0
TEXT_PS1MIN:     .db "PS1MIN",0
TEXT_PS1MAX:     .db "PS1MAX",0
TEXT_VSYNC:      .db "VSYNC",0

.close