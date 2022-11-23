; PSX 'Bare Metal' Test
.psx
.create "TimingGPUSTAT_Vsync240p.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"
.include "../../LIB/Variables.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; initialize video
;-----------------------------------------------------------------------------

la a0,IO_BASE ; A0 = I/O Port Base Address ($1F80XXXX)

; Setup Screen Mode
WRGP1 GPURESET,0  ; Write GP1 Command Word (Reset GPU)
WRGP1 GPUDISPEN,0 ; Write GP1 Command Word (Enable Display)
WRGP1 GPUDISPM,HRES320+VRES240+BPP15+VNTSC ; Write GP1 Command Word (Set Display Mode: 320x240, 15BPP, NTSC)
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

WRIOH T0_CNTT,0x8000 ; target

li t0,0
mtc0 t0,sr

;-----------------------------------------------------------------------------
; test execution
;-----------------------------------------------------------------------------

li s6, 20 ; y pos

; header
PrintText 40,s6,TEXT_TEST
PrintText 110,s6,TEXT_PS1
PrintText 160,s6,TEXT_CYCLES
PrintText 220,s6,TEXT_PS1MIN
PrintText 270,s6,TEXT_PS1MAX
addiu s6,10

; wait for 2 vsyncs after reset
li t1,0
sw t1,I_STAT(a0)
jal waitVsync :: nop 
jal waitVsync :: nop

WRIOH T1_CNTM,0x0300 ; reset and hblank as counter

; run test
storeVariableConstantWord 0,TESTCOUNT

li s1,260
jal waitLine :: nop  

WRIOH T2_CNTM,0x0200 ; reset and clk/8
RDIOH T2_CNTM,t0

li s2,0 ; mode = tmr0
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop

loadVariableWord t1,TESTRUNS
addiu t1,1
storeVariableWord t1,TESTRUNS

jal waitLine :: nop 

WRIOH T2_CNTM,0x0200 ; reset and clk/8

li s2,1 ; mode = tmr1
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop
jal captureChanges :: nop


; print out all status changes and check for errors
li s3,0
loadVariableWord s4,TESTRUNS
print_loop:
   ; print
   loadArrayWord s1, DATARECEIVE, s3
   li t0,0xFFFFFFFF
   bne s1,t0,noIRQPrintDATARECEIVE
   nop
   PrintText 30,s6,TEXT_VSYNC
   b endPrintDATARECEIVE
   nop
   noIRQPrintDATARECEIVE:
   PrintHexValue 30,s6,s1
   endPrintDATARECEIVE:
   
   loadArrayWord s1, DATAPS1, s3
   li t0,0xFFFFFFFF
   bne s1,t0,noIRQPrintDATAPS1
   nop
   PrintText 100,s6,TEXT_VSYNC
   b endPrintDATAPS1
   nop
   noIRQPrintDATAPS1:
   PrintHexValue 100,s6,s1
   endPrintDATAPS1:
   
   loadArrayWord s1, TIMERECEIVE, s3
   PrintDezValue 170,s6,s1
   loadArrayWord s1, TIMEMIN, s3
   PrintDezValue 220,s6,s1
   loadArrayWord s1, TIMEMAX, s3
   PrintDezValue 280,s6,s1

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
   b testok
   nop
   
   testfail:
   PrintText 10,s6,TEXT_FAIL
   
   testok:
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
; test functions
;-----------------------------------------------------------------------------

waitVsync: 
   li t1,0x0001
   RDIOH I_STAT,t0
   nop
   and t0,t1
   bne t0,t1,waitVsync 
   nop
   li t1,0
   sw t1,I_STAT(a0)
jr $31
nop

waitLine: 
   RDIOH T1_CNT,t2
   bne t2,s1,waitLine 
   nop
jr $31
nop


captureChanges:
   RDIOW GPUSTAT,t0
   
   changeLoop:
   ; check GPUSTAT change
   RDIOW GPUSTAT,t2
   beq t0,t2,noStatChange
   nop
   ; use tmr 1 = lines
   beqz s2,useTMR2
   nop
   RDIOH T1_CNT,t5
   b useTMRdone
   nop
   ; use tmr2 = clk / 8
   useTMR2:
   RDIOH T2_CNT,t5
   RDIOH T2_CNTM,t6
   WRIOH T2_CNTM,0x0200 ; reset and clk/8
   ; add 0x10000 in case of overflow
   li t0, 0x1000
   and t6, t0
   beqz t6,useTMRdone
   nop
   li t0,0x10000
   addu t5,t0
   nooverflow:
   
   useTMRdone:
   move t0,t2
   move t4,t2
   b saveChange
   nop
   
   noStatChange:
   b changeLoop
   nop
   
   saveChange:

   loadVariableWord t1,TESTRUNS
   storeArrayWord t4, DATARECEIVE, t1
   storeArrayWord t5, TIMERECEIVE, t1
   addiu t1,1
   storeVariableWord t1,TESTRUNS
   
   RDIOW I_STAT,t3
   nop
   andi t3,1
   beqz t3,noIRQChange
   nop
   li t1,0
   sw t1,I_STAT(a0)
   WRIOH T1_CNTM,0x0300 ; reset and hblank as counter
   li t4,0xFFFFFFFF
   li t5,0
   loadVariableWord t1,TESTRUNS
   storeArrayWord t4, DATARECEIVE, t1
   storeArrayWord t5, TIMERECEIVE, t1
   addiu t1,1
   storeVariableWord t1,TESTRUNS
   noIRQChange:

jr $31
nop

;-----------------------------------------------------------------------------
; constants area
;-----------------------------------------------------------------------------

.align 4

FontBlack: .incbin "../../LIB/FontBlack8x8.bin"
  
VALUEWORDG: .dw 0xFFFFFFFF

TESTCOUNT: .dw 0x0
TESTSPASS: .dw 0x0

TESTRUNS: .dw 0x0

DATARECEIVE: .dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
TIMERECEIVE: .dw 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

DATAPS1    : .dw 0x94022400,0x14022400,0x94022400,0x14022400,0xFFFFFFFF,0x94022400,0x14022400,0x94022400,0x00000000,0x94022400,0x14022400,0x94022400,0x14022400,0xFFFFFFFF,0x94022400,0x14022400,0x94022400
TIMEMIN    : .dw 16,268,268,268,0,6514,268,268,0,260,261,262,263,0,24,25,26
TIMEMAX    : .dw 17,271,271,271,0,6516,271,271,0,260,261,262,263,0,24,25,26
  
TEXT_TEST:       .db "TEST",0
TEXT_PS1:        .db "PS1",0
TEXT_OUTOF:      .db "OUT OF ",0
TEXT_TP:         .db "TESTS PASS",0
TEXT_CYCLES:     .db "CYCLES",0
TEXT_PS1MIN:     .db "PS1MIN",0
TEXT_PS1MAX:     .db "PS1MAX",0
TEXT_VSYNC:      .db "VSYNC",0
TEXT_FAIL:      .db "F",0

.close