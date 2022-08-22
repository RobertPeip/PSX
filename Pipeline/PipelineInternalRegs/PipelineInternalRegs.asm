; PSX 'Bare Metal' Test
.psx
.create "PipelineInternalRegs.bin", 0x80010000

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
SingleTest   TEXT_BASE_9_NOPS          , test_BASE_9_NOPS            ,   8
                                                                              
SingleTest   TEXT_SH                   , test_SH                     ,   8
SingleTest   TEXT_2SH                  , test_2SH                    ,   8
SingleTest   TEXT_3SH                  , test_3SH                    ,   8
SingleTest   TEXT_4SH                  , test_4SH                    ,   8
SingleTest   TEXT_5SH                  , test_5SH                    ,   11
SingleTest   TEXT_6SH                  , test_6SH                    ,   12
SingleTest   TEXT_7SH                  , test_7SH                    ,   14

SingleTest   TEXT_LH_NOP_MOVE          , test_LH_NOP_MOVE            ,   12
SingleTest   TEXT_2xLH_NOP_MOVE        , test_2xLH_NOP_MOVE          ,   16
      
SingleTest   TEXT_SH_LH_NOP_MOVE       , test_SH_LH_NOP_MOVE         ,   13
SingleTest   TEXT_2SH_LH_NOP_MOVE      , test_2SH_LH_NOP_MOVE        ,   14
SingleTest   TEXT_3SH_LH_NOP_MOVE      , test_3SH_LH_NOP_MOVE        ,   15
SingleTest   TEXT_4SH_LH_NOP_MOVE      , test_4SH_LH_NOP_MOVE        ,   16

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
test_BASE_9_NOPS:  
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
test_SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   nop
   nop
   sh t0,T2_CNTM(a1)
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
test_2SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   nop
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   nop
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
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
test_5SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_6SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_7SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   nop
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
   nop
   nop
   nop
   nop
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2xLH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_SH_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   nop
   sh t0,T2_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SH_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   nop
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SH_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   nop
   nop
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SH_LH_NOP_MOVE:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   nop
   sh t0,T2_CNT(a1)
   sh t0,T2_CNTT(a1)
   sh t0,T2_CNTM(a1)
   sh t0,T2_CNT(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
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
  
TEXT_TEST:                       .db "TEST",0
TEXT_OUTOF:                      .db "OUT OF ",0
TEXT_TP:                         .db "TESTS PASS",0
TEXT_CYCLES:                     .db "CYCLES",0
TEXT_PS1:                        .db "PS1",0
               
TEXT_BASE_9_NOPS:                .db "BASE 9 NOPS",0

TEXT_SH:                         .db "SH",0
TEXT_2SH:                        .db "2SH",0
TEXT_3SH:                        .db "3SH",0
TEXT_4SH:                        .db "4SH",0
TEXT_5SH:                        .db "5SH",0
TEXT_6SH:                        .db "6SH",0
TEXT_7SH:                        .db "7SH",0

TEXT_LH_NOP_MOVE:                .db "LH NOP MOVE",0
TEXT_2xLH_NOP_MOVE:              .db "2x LH NOP MOVE",0

TEXT_SH_LH_NOP_MOVE:             .db "SH LH NOP MOVE",0
TEXT_2SH_LH_NOP_MOVE:            .db "2SH LH NOP MOVE",0
TEXT_3SH_LH_NOP_MOVE:            .db "3SH LH NOP MOVE",0
TEXT_4SH_LH_NOP_MOVE:            .db "4SH LH NOP MOVE",0

TEXT_ERROR:                      .db "ERROR",0

.close