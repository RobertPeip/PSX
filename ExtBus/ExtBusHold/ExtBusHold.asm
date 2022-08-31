; PSX 'Bare Metal' Test
.psx
.create "ExtBusHold.bin", 0x80010000

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
      
      li t0,100
      makeidle:
      bne t0,1,makeidle
      subiu t0,1
      
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
   
   
   
.endmacro

.macro  MultiTest, testname, testfunction1, testfunction2, testfunction3, ps1time1, ps1time2, ps1time3

   PrintText 20,s6,testname

   SingleTest  testname, testfunction1, ps1time1
   PrintDezValue 90,s6,s1
   PrintDezValue 130,s6,s2
   
   SingleTest  testname, testfunction2, ps1time2
   PrintDezValue 170,s6,s1
   PrintDezValue 210,s6,s2
   
   SingleTest  testname, testfunction3, ps1time3
   PrintDezValue 250,s6,s1
   PrintDezValue 290,s6,s2
   
   
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

li s6, 10 ; y pos

; header
PrintText 20,s6,TEXT_BASE
PrintText 90,s6,TEXT_8B
PrintText 130,s6,TEXT_PS1
PrintText 170,s6,TEXT_16B
PrintText 210,s6,TEXT_PS1
PrintText 250,s6,TEXT_32B
PrintText 290,s6,TEXT_PS1
addiu s6,10

; hold of 0 = no effect
; hold of 1 => +1 cycle for every write
; hold has no effect on any read

; settings
li s1, 0x00000200 
sw s1,SPU_DELAY(a0)
li s1, 0x0000
sw s1,COM_DELAY(a0)
PrintText 10,s6,TEXT_TEST1
addiu s6,10

; tests
MultiTest TEXT_OFF_S_1, test_1SB,   test_1SH,   test_1SW,      9,    9,    9
MultiTest TEXT_OFF_S_2, test_2SB,   test_2SH,   test_2SW,     12,   14,   18
MultiTest TEXT_OFF_S_3, test_3SB,   test_3SH,   test_3SW,     15,   19,   27
MultiTest TEXT_OFF_S_4, test_4SB,   test_4SH,   test_4SW,     18,   24,   36
        
MultiTest TEXT_OFF_L_1, test_1LB,   test_1LH,   test_1LW,     12,   14,   18
MultiTest TEXT_OFF_L_2, test_2LB,   test_2LH,   test_2LW,     18,   22,   30
MultiTest TEXT_OFF_L_3, test_3LB,   test_3LH,   test_3LW,     24,   30,   42
MultiTest TEXT_OFF_L_4, test_4LB,   test_4LH,   test_4LW,     30,   38,   54

MultiTest TEXT_OFF_SL,  test_1SBLB, test_1SHLH, test_1SWLW,   15,   19,   27

; settings updated
li s1, 0x00000200 
sw s1,SPU_DELAY(a0)
li s1, 0x0050 
sw s1,COM_DELAY(a0)
PrintText 10,s6,TEXT_TEST2
addiu s6,10

; tests
MultiTest TEXT_OFF_S_1, test_1SB,   test_1SH,   test_1SW,      9,    9,    9
MultiTest TEXT_OFF_S_2, test_2SB,   test_2SH,   test_2SW,     17,   24,   38
MultiTest TEXT_OFF_S_3, test_3SB,   test_3SH,   test_3SW,     25,   39,   67
MultiTest TEXT_OFF_S_4, test_4SB,   test_4SH,   test_4SW,     33,   54,   96
        
MultiTest TEXT_OFF_L_1, test_1LB,   test_1LH,   test_1LW,     12,   14,   18
MultiTest TEXT_OFF_L_2, test_2LB,   test_2LH,   test_2LW,     18,   22,   30
MultiTest TEXT_OFF_L_3, test_3LB,   test_3LH,   test_3LW,     24,   30,   42
MultiTest TEXT_OFF_L_4, test_4LB,   test_4LH,   test_4LW,     30,   38,   54

MultiTest TEXT_OFF_SL,  test_1SBLB, test_1SHLH, test_1SWLW,   20,   29,   47

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
test_2SB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sb t0,SPUEVOL(a1)
   sb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_3SB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sb t0,SPUEVOL(a1)
   sb t0,SPUEVOL(a1)
   sb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sb t0,SPUEVOL(a1)
   sb t0,SPUEVOL(a1)
   sb t0,SPUEVOL(a1)
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
test_3SH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sh t0,SPUEVOL(a1)
   sh t0,SPUEVOL(a1)
   sh t0,SPUEVOL(a1)
   
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
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sh t0,SPUEVOL(a1)
   sh t0,SPUEVOL(a1)
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
test_3SW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,SPUEVOL(a1)
   sw t0,SPUEVOL(a1)
   sw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4SW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,SPUEVOL(a1)
   sw t0,SPUEVOL(a1)
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
test_3LB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lb t0,SPUEVOL(a1)
   lb t0,SPUEVOL(a1)
   lb t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4LB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lb t0,SPUEVOL(a1)
   lb t0,SPUEVOL(a1)
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
test_3LH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4LH:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
   lh t0,SPUEVOL(a1)
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
test_3LW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_4LW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   
   lhu s4,T0_CNT(a1)
   nop
   move s1,s4
jr $31
nop

.align 64
test_1SBLB:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sb t0,SPUEVOL(a1)
   lb t0,SPUEVOL(a1)
   
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

.align 64
test_1SWLW:  
   la a1,0xBF800000
   li t0,0x0008     
   sh t0,T0_CNTM(a1)
   lh t0,T2_CNTM(a1)
   nop
   move t1,t0
   
   sw t0,SPUEVOL(a1)
   lw t0,SPUEVOL(a1)
   
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

TEXT_BASE:                       .db "BASE=7",0
TEXT_TEST1:                      .db "MEMCTRL=00000200 COM_DELAY=0000 HOLD=0",0
TEXT_TEST2:                      .db "MEMCTRL=00000200 COM_DELAY=0050 HOLD=5",0
TEXT_OUTOF:                      .db "OUT OF ",0
TEXT_TP:                         .db "TESTS PASS",0
TEXT_8B:                         .db "8B",0
TEXT_16B:                        .db "16B",0
TEXT_32B:                        .db "32B",0
TEXT_PS1:                        .db "PS1",0
               
TEXT_OFF_S_1:                    .db "OFF S 1",0
TEXT_OFF_S_2:                    .db "OFF S 2",0
TEXT_OFF_S_3:                    .db "OFF S 3",0
TEXT_OFF_S_4:                    .db "OFF S 4",0
TEXT_OFF_L_1:                    .db "OFF L 1",0
TEXT_OFF_L_2:                    .db "OFF L 2",0
TEXT_OFF_L_3:                    .db "OFF L 3",0
TEXT_OFF_L_4:                    .db "OFF L 4",0
TEXT_OFF_SL:                     .db "OFF SL",0

TEXT_ERROR:                      .db "ERROR",0

.close