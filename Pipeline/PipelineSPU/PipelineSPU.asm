; PSX 'Bare Metal' Test
.psx
.create "PipelineSPU.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

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
PrintText 20,s6,TEXT_COM_DELAY

lw s1,COM_DELAY(a0)
nop
PrintHexValue 120,s6,s1

li s1, 0x132C 
sw s1,COM_DELAY(a0)

lw s1,COM_DELAY(a0)
nop
PrintHexValue 220,s6,s1

; header
addiu s6,10

; timings -> print read out values and what is assumed for test -> should be equal
PrintText 20,s6,TEXT_MEMCONTROL
li s1, 0x200931E1
PrintHexValue 140,s6,s1
lw s1,SPU_DELAY(a0)
nop
PrintHexValue 240,s6,s1
addiu s6,10


; instruction tests
SingleTest   TEXT_BASE_NO_TEST         , test_BASE_NO_TEST           ,   7

SingleTest   TEXT_1SB                  , test_1SB                    ,   9
SingleTest   TEXT_1SH                  , test_1SH                    ,   9
SingleTest   TEXT_2SH                  , test_2SH                    ,   13
SingleTest   TEXT_1SW                  , test_1SW                    ,   9
SingleTest   TEXT_2SW                  , test_2SW                    ,   27

SingleTest   TEXT_1LB                  , test_1LB                    ,   26
SingleTest   TEXT_1LH                  , test_1LH                    ,   26
SingleTest   TEXT_2LH                  , test_2LH                    ,   54
SingleTest   TEXT_1LW                  , test_1LW                    ,   53
SingleTest   TEXT_2LW                  , test_2LW                    ,   108

SingleTest   TEXT_1SHLH                , test_1SHLH                  ,   41

; set new timings
li s1, 0x200931F2 
sw s1,SPU_DELAY(a0)

; print new timings
PrintText 20,s6,TEXT_MEMCONTROL
lw s1,SPU_DELAY(a0)
nop
PrintHexValue 140,s6,s1
addiu s6,10

SingleTest   TEXT_1SH                  , test_1SH                    ,   9
SingleTest   TEXT_2SH                  , test_2SH                    ,   14

SingleTest   TEXT_1LH                  , test_1LH                    ,   27
SingleTest   TEXT_2LH                  , test_2LH                    ,   56
SingleTest   TEXT_1LW                  , test_1LW                    ,   55
SingleTest   TEXT_2LW                  , test_2LW                    ,   112

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
test_1SB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sh t0,SPUEVOL(a1)
   
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
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sh t0,SPUEVOL(a1)
   sh t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1SW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2SW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,SPUEVOL(a1)
   sw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1LB:  
   la a1,0xBF800000
   li t0,0x0008 
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2LB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lb t0,SPUEVOL(a1)
   lb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1LH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lh t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2LH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1LW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_2LW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1SHLH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
   
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
  
TEXT_MEMCONTROL:                 .db "MEMCONTROL",0

TEXT_COM_DELAY:                  .db "COM_DELAY",0
TEXT_OUTOF:                      .db "OUT OF ",0
TEXT_TP:                         .db "TESTS PASS",0
TEXT_CYCLES:                     .db "CYCLES",0
TEXT_PS1:                        .db "PS1",0
               
TEXT_BASE_NO_TEST:               .db "BASE NO TEST",0

TEXT_1SB:                        .db "1SB",0
TEXT_2SB:                        .db "2SB",0
TEXT_1SH:                        .db "1SH",0
TEXT_2SH:                        .db "2SH",0
TEXT_1SW:                        .db "1SW",0
TEXT_2SW:                        .db "2SW",0

TEXT_1LB:                        .db "1LB",0
TEXT_2LB:                        .db "2LB",0
TEXT_1LH:                        .db "1LH",0
TEXT_2LH:                        .db "2LH",0
TEXT_1LW:                        .db "1LW",0
TEXT_2LW:                        .db "2LW",0

TEXT_1SHLH:                      .db "1SHLH",0

TEXT_ERROR:                      .db "ERROR",0

.close