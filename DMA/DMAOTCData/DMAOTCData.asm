; PSX 'Bare Metal' Test
.psx
.create "DMAOTCData.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

OTC_START equ 0x00100000

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,otclength, ps1time_low, ps1time_high

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,100 ; runcount
   li s2,0
   
   li s5, otclength
   
   checkloop:
   
      jal test_PREPAREOTC
      nop
   
      WRIOH T0_CNTM,0x0008 ; reset
      RDIOH T0_CNT,s1
      jal test_RUNOTC
      nop
      RDIOH T0_CNT,s4
      sub s4,s1
      add s2,s4
      
      jal test_COMPAREOTC
      nop
      
      beq t7,0,SingleTest_noerror
      nop
      li s3,0
      
      SingleTest_noerror:
      
      bne s3,1,checkloop
      subiu s3,1

   li t0,100
   div s2,t0
   mflo s1
   
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
   
   PrintText 20,s6,TEXT_OTC_LEN
   PrintDezValue 80,s6,s5
   
   bnez t7,singletest_error
   nop

   PrintDezValue 140,s6,s1
   PrintDezValue 200,s6,s2
   PrintDezValue 260,s6,s3
   
   b singletest_end
   nop

   singletest_error:
   PrintText 140,s6,TEXT_ERROR
   
   move s1,t7
   PrintDezValue 200,s6,s1
   
   singletest_end:
   
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
; init DMA
;-----------------------------------------------------------------------------

li t0,0x0FEDCBA9 ; activate all DMAs
sw t0,DPCR(a0)
li t0,0          ; disable all interrupts
sw t0,DICR(a0)

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
SingleTest   1,  31,  31
SingleTest   2,  37,  37
SingleTest   3,  38,  38
SingleTest   4,  39,  39
SingleTest   5,  41,  41
SingleTest  10,  45,  45
SingleTest  16,  52,  52
SingleTest  31,  66,  66
SingleTest  64, 102, 102
SingleTest 127, 167, 167
SingleTest 256, 302, 302
SingleTest 511, 575, 576

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
test_PREPAREOTC:  
   li t0,OTC_START
   li t1,0
   move t2,s5
   PREPAREOTC_loop:
   
      sw t1,0(t0)
      subiu t0,4
      
      bnez t2,PREPAREOTC_loop 
      subiu t2,1
jr $31
nop

.align 64
test_RUNOTC:  
   li t0,OTC_START
   sw t0,D6_MADR(a0)
   sw s5,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait 
   nop
jr $31
nop

.align 64
test_COMPAREOTC:  
   li t0,OTC_START
   li t1,OTC_START
   subiu t1,4
   move t2,s5
   li t7,0
   COMPAREOTC_loop:
   
      ; exchange expected data for last word
      bne t2,1,COMPAREOTC_notlast
      nop
      li t1,0xFFFFFF
      COMPAREOTC_notlast:
      
      ; compare data
      lw t3,0(t0)
      nop
      beq t1,t3,COMPAREOTC_noerror
      nop
      move t7,t2
      jr $31
      nop
      COMPAREOTC_noerror:
      
      ;adjust address and data for next check
      subiu t0,4
      subiu t1,4
      
      bnez t2,COMPAREOTC_loop 
      subiu t2,1
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
   
TEXT_OTC_LEN:        .db "OTC LEN",0
TEXT_ERROR:          .db "ERROR",0

.close