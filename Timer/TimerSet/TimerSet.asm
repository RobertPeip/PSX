; PSX 'Bare Metal' Test
.psx
.create "TimerSet.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

OTC_START equ 0x00100000

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testname, testfunction, ps1time

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
   
   li s2, ps1time

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   bne s1,s2,testfail
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfail:
   
   PrintText 20,s6,testname
   PrintDezValue 200,s6,s1
   PrintDezValue 260,s6,s2
   
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
PrintText 200,s6,TEXT_CYCLES
PrintText 260,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest   TEXT_9_NOPKSEG1           , test_timer9KSEG1            ,   8
            
SingleTest   TEXT_CURRENT_1            , test_CURRENT_1              ,   9
SingleTest   TEXT_CURRENT_3            , test_CURRENT_3              ,   11
         
SingleTest   TEXT_RESET_CURRENT_1      , test_RESET_CURRENT_1        ,   9
      
SingleTest   TEXT_CURRENT_3_reset_0    , test_CURRENT_3_RESET_0      ,   0
SingleTest   TEXT_CURRENT_3_reset_1    , test_CURRENT_3_RESET_1      ,   0
SingleTest   TEXT_CURRENT_3_reset_2    , test_CURRENT_3_RESET_2      ,   1

; using range 7-9 as 1-3 would result in the target value already being reached at the same time the current is written, so the test is not possible
; but it shows that setting the value from CPU is ignored when the target value is reached in the same cycle!

SingleTest   TEXT_TARGET_7_CURRENT_9_0 , test_TARGET_7_CURRENT_9_0   ,   9
SingleTest   TEXT_TARGET_7_CURRENT_9_1 , test_TARGET_7_CURRENT_9_1   ,   9
SingleTest   TEXT_TARGET_7_CURRENT_9_2 , test_TARGET_7_CURRENT_9_2   ,  10
SingleTest   TEXT_TARGET_7_CURRENT_9_3 , test_TARGET_7_CURRENT_9_3   ,  11

SingleTest   TEXT_TARGET_8_CURRENT_9_0 , test_TARGET_8_CURRENT_9_0   ,   9
SingleTest   TEXT_TARGET_8_CURRENT_9_1 , test_TARGET_8_CURRENT_9_1   ,   9
SingleTest   TEXT_TARGET_8_CURRENT_9_2 , test_TARGET_8_CURRENT_9_2   ,  10

SingleTest   TEXT_TARGET_9_CURRENT_9_0 , test_TARGET_9_CURRENT_9_0   ,   9
SingleTest   TEXT_TARGET_9_CURRENT_9_1 , test_TARGET_9_CURRENT_9_1   ,   9
SingleTest   TEXT_TARGET_9_CURRENT_9_2 , test_TARGET_9_CURRENT_9_2   ,   0
SingleTest   TEXT_TARGET_9_CURRENT_9_3 , test_TARGET_9_CURRENT_9_3   ,   0
SingleTest   TEXT_TARGET_9_CURRENT_9_4 , test_TARGET_9_CURRENT_9_4   ,   1

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
test_timer9KSEG1:  
   la a1,0xBF800000
   li t0,0x0000     
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
test_CURRENT_1:  
   la a1,0xBF800000
   li t0,0x0001     
   sh t0,T0_CNT(a1) ; set value
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
test_CURRENT_3:  
   la a1,0xBF800000
   li t0,0x0003     
   sh t0,T0_CNT(a1) ; set value
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
test_RESET_CURRENT_1:  
   la a1,0xBF800000
   li t0,0x0000     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0001     
   sh t0,T0_CNT(a1) ; set value
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
test_CURRENT_3_RESET_0:  
   la a1,0xBF800000
   li t0,0x0003     
   sh t0,T0_CNT(a1) ; set value
   li t0,0x0000     
   sh t0,T0_CNTM(a1) ; reset
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_CURRENT_3_RESET_1:  
   la a1,0xBF800000
   li t0,0x0003     
   sh t0,T0_CNT(a1) ; set value
   li t0,0x0000     
   sh t0,T0_CNTM(a1) ; reset
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_CURRENT_3_RESET_2:  
   la a1,0xBF800000
   li t0,0x0003     
   sh t0,T0_CNT(a1) ; set value
   li t0,0x0000     
   sh t0,T0_CNTM(a1) ; reset
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_7_CURRENT_9_0:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0007     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_7_CURRENT_9_1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0007     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_7_CURRENT_9_2:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0007     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_7_CURRENT_9_3:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0007     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_8_CURRENT_9_0:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0008    
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_8_CURRENT_9_1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0008     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_8_CURRENT_9_2:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0008     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_9_CURRENT_9_0:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0009     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_9_CURRENT_9_1:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0009     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_9_CURRENT_9_2:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0009     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_9_CURRENT_9_3:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0009     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_TARGET_9_CURRENT_9_4:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1) ; reset
   li t0,0x0009     
   sh t0,T0_CNTT(a1) ; target
   li t0,0x0009     
   sh t0,T0_CNT(a1) ; set value
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
  
TEXT_TEST:                 .db "TEST",0
TEXT_OUTOF:                .db "OUT OF ",0
TEXT_TP:                   .db "TESTS PASS",0
TEXT_CYCLES:               .db "CYCLES",0
TEXT_PS1:                  .db "PS1",0
         
TEXT_9_NOPKSEG1:           .db "9 NOP KSEG1",0
      
TEXT_CURRENT_1:            .db "CURRENT 1",0
TEXT_CURRENT_3:            .db "CURRENT 3",0
   
TEXT_RESET_CURRENT_1:      .db "RESET CURRENT 1",0
   
TEXT_CURRENT_3_reset_0:    .db "CURRENT 3 RESET 0",0
TEXT_CURRENT_3_reset_1:    .db "CURRENT 3 RESET 1",0
TEXT_CURRENT_3_reset_2:    .db "CURRENT 3 RESET 2",0

TEXT_TARGET_7_CURRENT_9_0: .db "TARGET 7 CURRENT 9 0",0
TEXT_TARGET_7_CURRENT_9_1: .db "TARGET 7 CURRENT 9 1",0
TEXT_TARGET_7_CURRENT_9_2: .db "TARGET 7 CURRENT 9 2",0
TEXT_TARGET_7_CURRENT_9_3: .db "TARGET 7 CURRENT 9 3",0

TEXT_TARGET_8_CURRENT_9_0: .db "TARGET 8 CURRENT 9 0",0
TEXT_TARGET_8_CURRENT_9_1: .db "TARGET 8 CURRENT 9 1",0
TEXT_TARGET_8_CURRENT_9_2: .db "TARGET 8 CURRENT 9 2",0

TEXT_TARGET_9_CURRENT_9_0: .db "TARGET 9 CURRENT 9 0",0
TEXT_TARGET_9_CURRENT_9_1: .db "TARGET 9 CURRENT 9 1",0
TEXT_TARGET_9_CURRENT_9_2: .db "TARGET 9 CURRENT 9 2",0
TEXT_TARGET_9_CURRENT_9_3: .db "TARGET 9 CURRENT 9 3",0
TEXT_TARGET_9_CURRENT_9_4: .db "TARGET 9 CURRENT 9 4",0

TEXT_ERROR:             .db "ERROR",0

.close