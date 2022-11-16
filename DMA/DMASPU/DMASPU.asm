; PSX 'Bare Metal' Test
.psx
.create "DMASPU.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testfunction, testname, DMAlength, ps1time_low, ps1time_high

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,2 ; runcount
   
   li s5, DMAlength
   
   checkloop:
   
      jal test_PREPAREDMA
      nop
   
      WRIOH T0_CNTM,0x0008 ; reset
      RDIOH T0_CNT,s1
      move s2, s1
      
      jal testfunction
      nop
      RDIOH T0_CNT,s2
      sub s2,s1
      
      bne s3,1,checkloop
      subiu s3,1
      
   move s1, s2
   
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
   PrintDezValue 130,s6,s5
   
   PrintDezValue 160,s6,s1
   PrintDezValue 210,s6,s2
   PrintDezValue 270,s6,s3
   
   b singletest_end
   nop

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

; set new timings
li s1, 0x220931E1
sw s1,SPU_DELAY(a0)

li s1, 0x132C 
sw s1,COM_DELAY(a0)

li s6, 10 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 140,s6,TEXT_CYCLES
PrintText 200,s6,TEXT_PS1_LOW
PrintText 260,s6,TEXT_PS1_HIGH
addiu s6,10

; instruction tests

li s4, 0x00100000

SingleTest  test_EMPTY     , TEXT_EMPTY      ,    0,  11,  11
SingleTest  test_SETUP     , TEXT_SETUP      ,    0,  22,  22
SingleTest  test_WAITDONE  , TEXT_WAITDONE   ,    0,  31,  31

PrintText 20,s6,TEXT_DMA_START
PrintHexValue 100,s6,s4
addiu s6,10

SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    1,  44,  44
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    2,  52,  52
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    3,  60,  60
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    4,  68,  73
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    5,  76,  81
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,   10, 116, 116
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,   16, 164, 164
                                                                
SingleTest  test_RUNDMA_OUT   , TEXT_DMA_OUT_LEN   ,    1,  41,  41
SingleTest  test_RUNDMA_OUT   , TEXT_DMA_OUT_LEN   ,    2,  49,  49
SingleTest  test_RUNDMA_OUT   , TEXT_DMA_OUT_LEN   ,   16, 161, 168
                                                                
li s4, 0x0010FFFC                                               
PrintText 20,s6,TEXT_DMA_START                                  
PrintHexValue 100,s6,s4                                         
addiu s6,10                                                     
                                                                
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    1,  44,  44
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    2,  52,  52
SingleTest  test_RUNDMA_IN    , TEXT_DMA_IN_LEN    ,    3,  60,  60
                                                                
SingleTest  test_RUNDMA_OUT   , TEXT_DMA_OUT_LEN   ,    1,  41,  41
SingleTest  test_RUNDMA_OUT   , TEXT_DMA_OUT_LEN   ,    3,  57,  57

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
test_PREPAREDMA:  
   move t0,s4
   li t1,0
   move t2,s5
   PREPAREDMA_loop:
   
      sw t1,0(t0)
      subiu t0,4
      
      bnez t2,PREPAREDMA_loop 
      subiu t2,1
jr $31
nop

.align 64
test_EMPTY:
jr $31
nop

.align 64
test_SETUP:  
   move t0,s4
   sw t0,D4_MADR(a0)
   sw s5,D4_BCR(a0)
   lui t0,0x0000
   addiu t0,0x2    
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
jr $31
nop

.align 64
test_WAITDONE:  
   move t0,s4
   sw t0,D4_MADR(a0)
   sw s5,D4_BCR(a0)
   lui t0,0x0000 ; write like this to have same timing behavior as real test
   addiu t0,0x2  ; write like this to have same timing behavior as real test  
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   WAITDONE_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,WAITDONE_wait 
   nop
jr $31
nop

.align 64
test_RUNDMA_IN:  
   move t0,s4
   sw t0,D4_MADR(a0)
   sw s5,D4_BCR(a0)
   li t0,0x11000001
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMA_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait 
   nop
jr $31
nop

.align 64
test_RUNDMA_OUT:  
   move t0,s4
   sw t0,D4_MADR(a0)
   sw s5,D4_BCR(a0)
   li t0,0x11000000
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMA_OUT_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_OUT_wait 
   nop
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
   
TEXT_EMPTY:          .db "EMPTY",0
TEXT_SETUP:          .db "SETUP",0
TEXT_WAITDONE:       .db "WAITDONE",0
TEXT_DMA_IN_LEN:     .db "DMA IN LEN",0
TEXT_DMA_OUT_LEN:    .db "DMA OUT LEN",0
TEXT_DMA_START:      .db "DMA START",0
TEXT_ERROR:          .db "ERROR",0

.close