; PSX 'Bare Metal' Test
.psx
.create "PipelineRAMwrite.bin", 0x80010000

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
   WRIOH T2_CNTT,0x8000 ; target
   
   li s3,11 ; runcount  + 1
   li s2,0
   li s5,1000
   
   checkloop:
   
      la a2,0xA0140000
      la a3,0xA0180000
      sw t0,0(a2)
      lw t0,0(a2)
      nop
      move t1,t0
   
      jal testfunction
      nop
      
      bge s1,s5,notlower
      nop
      move s5,s1
      
      notlower:
      
      bne s3,1,checkloop
      subiu s3,1
   
   move s1,s5
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
SingleTest   TEXT_BASE_NO_TEST         , test_BASE_NO_TEST           ,   7

SingleTest   TEXT_SW_SAME              , test_SW_SAME                ,   10
SingleTest   TEXT_2SW_SAME             , test_2SW_SAME               ,   12
SingleTest   TEXT_3SW_SAME             , test_3SW_SAME               ,   14
SingleTest   TEXT_4SW_SAME             , test_4SW_SAME               ,   16

SingleTest   TEXT_SW_DIFF              , test_SW_DIFF                ,   10
SingleTest   TEXT_2SW_DIFF             , test_2SW_DIFF               ,   16
SingleTest   TEXT_3SW_DIFF             , test_3SW_DIFF               ,   22
SingleTest   TEXT_4SW_DIFF             , test_4SW_DIFF               ,   28

SingleTest   TEXT_LH_NOP_MOVE          , test_LH_NOP_MOVE            ,   14
      
SingleTest   TEXT_SW_LH_NOP_MOVE       , test_SW_LH_NOP_MOVE         ,   17
SingleTest   TEXT_2SW_LH_NOP_MOVE      , test_2SW_LH_NOP_MOVE        ,   19
SingleTest   TEXT_3SW_LH_NOP_MOVE      , test_3SW_LH_NOP_MOVE        ,   21

SingleTest   TEXT_SW_LH_SW             , test_SW_LH_SW               ,   20

SingleTest   TEXT_2SW_DIFF_DIST1       , test_2SW_DIFF_DIST1         ,   12
SingleTest   TEXT_2SW_DIFF_DIST2       , test_2SW_DIFF_DIST2         ,   16

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
test_BASE_NO_TEST:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_SW_SAME:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW_SAME:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SW_SAME:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   sw t0,0(a2)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SW_SAME:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   sw t0,0(a2)
   sw t0,0(a2)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_SW_DIFF:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW_DIFF:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SW_DIFF:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)
   sw t0,0(a2)
   sw t0,0(a3)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SW_DIFF:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)
   sw t0,0(a2)
   sw t0,0(a3)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_SW_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   sw t0,0(a2)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SW_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   sw t0,0(a2)
   sw t0,0(a2)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_SW_LH_SW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a2)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW_DIFF_DIST1: 
   la a3,0xA01403FC
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)
   sw t0,0(a2)

   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW_DIFF_DIST2:  
   la a3,0xA0140400
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,0(a3)
   sw t0,0(a2)

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
  
TEXT_TEST:                       .db "TEST",0
TEXT_OUTOF:                      .db "OUT OF ",0
TEXT_TP:                         .db "TESTS PASS",0
TEXT_CYCLES:                     .db "CYCLES",0
TEXT_PS1:                        .db "PS1",0
               
TEXT_BASE_NO_TEST:               .db "BASE NO TEST",0

TEXT_SW_SAME:                    .db "SW SAME",0
TEXT_2SW_SAME:                   .db "2SW SAME",0
TEXT_3SW_SAME:                   .db "3SW SAME",0
TEXT_4SW_SAME:                   .db "4SW SAME",0

TEXT_SW_DIFF:                    .db "SW  DIFF",0
TEXT_2SW_DIFF:                   .db "2SW DIFF",0
TEXT_3SW_DIFF:                   .db "3SW DIFF",0
TEXT_4SW_DIFF:                   .db "4SW DIFF",0
TEXT_5SW_DIFF:                   .db "5SW DIFF",0

TEXT_LH_NOP_MOVE:                .db "LH NOP MOVE",0

TEXT_SW_LH_NOP_MOVE:             .db "SW LH NOP MOVE",0
TEXT_2SW_LH_NOP_MOVE:            .db "2SW LH NOP MOVE",0
TEXT_3SW_LH_NOP_MOVE:            .db "3SW LH NOP MOVE",0

TEXT_SW_LH_SW:                   .db "SW LH SW",0

TEXT_2SW_DIFF_DIST1:             .db "2SW DIFF DIST 0x3FC",0
TEXT_2SW_DIFF_DIST2:             .db "2SW DIFF DIST 0x400",0

TEXT_ERROR:                      .db "ERROR",0

.close