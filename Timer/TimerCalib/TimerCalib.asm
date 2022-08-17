; PSX 'Bare Metal' Test
.psx
.create "TimerCalib.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

OTC_START equ 0x00100000

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testname, testfunction, ps1time_low, ps1time_high

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,2 ; runcount 2, so everything is cached in testrun
   li s2,0
   
   checkloop:
   
      jal testfunction
      nop
      
      bne s3,1,checkloop
      subiu s3,1
   
   li s2, ps1time_low
   li s3, ps1time_high

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   sltu t0, s1, s2
   bnez t0,testfail
   nop
   sltu t0, s3, s1
   bnez t0,testfail
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfail:
   
   PrintText 20,s6,testname
   PrintDezValue 140,s6,s1
   PrintDezValue 200,s6,s2
   PrintDezValue 260,s6,s3
   
   addiu s6,10
   
.endmacro

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
; test execution
;-----------------------------------------------------------------------------

li s6, 20 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 140,s6,TEXT_CYCLES
PrintText 200,s6,TEXT_PS1_LOW
PrintText 260,s6,TEXT_PS1_HIGH
addiu s6,10

; instruction tests
SingleTest   TEXT_0_NOPKUSEG     , test_timer0KUSEG      ,   0,  0
SingleTest   TEXT_0_NOPKSEG0     , test_timer0KSEG0      ,   0,  0
SingleTest   TEXT_0_NOPKSEG1     , test_timer0KSEG1      ,   0,  0
SingleTest   TEXT_1_NOPKUSEG     , test_timer1KUSEG      ,   0,  0
SingleTest   TEXT_1_NOPKSEG1     , test_timer1KSEG1      ,   0,  0
SingleTest   TEXT_2_NOPKUSEG     , test_timer2KUSEG      ,   1,  1
SingleTest   TEXT_2_NOPKSEG1     , test_timer2KSEG1      ,   1,  1
SingleTest   TEXT_9_NOPKSEG1     , test_timer9KSEG1      ,   8,  8

SingleTest   TEXT_TIMERWRAP4     , test_TIMERWRAP4       ,   2,  2
SingleTest   TEXT_TIMERWRAP5     , test_TIMERWRAP5       ,   1,  1
SingleTest   TEXT_TIMERWRAP6     , test_TIMERWRAP6       ,   0,  0
SingleTest   TEXT_TIMERWRAP7     , test_TIMERWRAP7       ,   0,  0
SingleTest   TEXT_TIMERWRAP8     , test_TIMERWRAP8       ,   8,  8

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
; tests
;-----------------------------------------------------------------------------

.align 4096 ; make sure it fits in cache together with executing loop

.align 64
test_timer0KUSEG:  
   la a1,0x1F800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer0KSEG0:  
   la a1,0x9F800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer0KSEG1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer1KUSEG:  
   la a1,0x1F800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer1KSEG1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer2KUSEG:  
   la a1,0x1F800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer2KSEG1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_timer9KSEG1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TIMERWRAP4:  
   la a1,0xBF800000
   li t0,0x0004 
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TIMERWRAP5:  
   la a1,0xBF800000
   li t0,0x0005 
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TIMERWRAP6:  
   la a1,0xBF800000
   li t0,0x0006 
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TIMERWRAP7:  
   la a1,0xBF800000
   li t0,0x0007 
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TIMERWRAP8:  
   la a1,0xBF800000
   li t0,0x0008 
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
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
  
TEXT_TEST:           .db "TEST",0
TEXT_OUTOF:          .db "OUT OF ",0
TEXT_TP:             .db "TESTS PASS",0
TEXT_CYCLES:         .db "CYCLES",0
TEXT_PS1_LOW:        .db "PS1LO",0
TEXT_PS1_HIGH:       .db "PS1HI",0
   
TEXT_0_NOPKUSEG:     .db "0 NOP KUSEG",0
TEXT_0_NOPKSEG0:     .db "0 NOP KSEG0",0
TEXT_0_NOPKSEG1:     .db "0 NOP KSEG1",0
TEXT_1_NOPKUSEG:     .db "1 NOP KUSEG",0
TEXT_1_NOPKSEG1:     .db "1 NOP KSEG1",0
TEXT_2_NOPKUSEG:     .db "2 NOP KUSEG",0
TEXT_2_NOPKSEG1:     .db "2 NOP KSEG1",0
TEXT_9_NOPKSEG1:     .db "9 NOP KSEG1",0

TEXT_TIMERWRAP4:     .db "TIMERWRAP4",0
TEXT_TIMERWRAP5:     .db "TIMERWRAP5",0
TEXT_TIMERWRAP6:     .db "TIMERWRAP6",0
TEXT_TIMERWRAP7:     .db "TIMERWRAP7",0
TEXT_TIMERWRAP8:     .db "TIMERWRAP8",0

TEXT_ERROR:          .db "ERROR",0

.close