; PSX 'Bare Metal' Test
.psx
.create "DMACPUStall.bin", 0x80010000

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
   
   PrintDezValue 160,s6,s1
   PrintDezValue 210,s6,s2
   PrintDezValue 270,s6,s3
   
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

; Turn On GTE (Set Bit 30 Of The System Control Coprocessor (COP0) Status Register)
li t0,1<<30 ; T0 = 1 << 30
mtc0 t0,sr  ; COP0 Status Register = T0

li s1, 0x132C 
sw s1,COM_DELAY(a0)

li s1, 0x200931F2 
sw s1,SPU_DELAY(a0)

li s6, 20 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 140,s6,TEXT_CYCLES
PrintText 200,s6,TEXT_PS1_LOW
PrintText 260,s6,TEXT_PS1_HIGH
addiu s6,10

; instruction tests

li s4, 0x00100000

SingleTest  test_EMPTY                    , TEXT_EMPTY           ,  0,  11,  11
SingleTest  test_SETUP                    , TEXT_SETUP           ,  0,  18,  18
SingleTest  test_WAITDONE                 , TEXT_WAITDONE        ,  0,  27,  27
                                                                 
SingleTest  test_RUNDMA2                  , TEXT_DMA_2_NOPS      ,  1,  35,  35
SingleTest  test_RUNDMA11                 , TEXT_DMA_11_NOPS     ,  1,  38,  48
SingleTest  test_RUNDMA_LI_ADD            , TEXT_DMA_LI_ADD      ,  1,  38,  48
SingleTest  test_RUNDMA_READ_SCRATCHPAD   , TEXT_DMA_READ_SPAD   ,  1,  38,  48
SingleTest  test_RUNDMA_WRITE_SCRATCHPAD  , TEXT_DMA_WRITE_SPAD  ,  1,  38,  48
SingleTest  test_RUNDMA_READ_RAM          , TEXT_DMA_READ_RAM    ,  1,  44,  44
SingleTest  test_RUNDMA_WRITE_RAM         , TEXT_DMA_WRITE_RAM   ,  1,  38,  38
SingleTest  test_RUNDMA_READ_GTE          , TEXT_DMA_READ_GTE    ,  1,  38,  38
SingleTest  test_RUNDMA_WRITE_GTE         , TEXT_DMA_WRITE_GTE   ,  1,  38,  38
SingleTest  test_RUNDMA_READ_TIMER        , TEXT_DMA_READ_TIMER  ,  1,  43,  43
SingleTest  test_RUNDMA_WRITE_TIMER       , TEXT_DMA_WRITE_TIMER ,  1,  38,  38
SingleTest  test_RUNDMA_READ_SPU          , TEXT_DMA_READ_SPU    ,  1,  59,  59
SingleTest  test_RUNDMA_WRITE_SPU         , TEXT_DMA_WRITE_SPU   ,  1,  38,  38


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
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   lui t0,0x0000
   addiu t0,0x2    
   sw t0,D0_CHCR(a0)
   li t1, 0x01000000
jr $31
nop

.align 64
test_WAITDONE:  
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   lui t0,0x0000 ; write like this to have same timing behavior as real test
   addiu t0,0x2  ; write like this to have same timing behavior as real test  
   sw t0,D0_CHCR(a0)
   li t1, 0x01000000
   WAITDONE_wait:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,WAITDONE_wait 
   nop
jr $31
nop

.align 64
test_RUNDMA2:  
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   nop
   nop
   li t1, 0x01000000
   RUNDMA_wait0:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait0 
   nop
jr $31
nop

.align 64
test_RUNDMA11:  
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait11:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait11
   nop
jr $31
nop

.align 64
test_RUNDMA_LI_ADD:  
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   li t0,1
   li t1,2
   add t0,t1
   li t0,3
   li t1,4
   add t0,t1
   li t0,5
   li t1,6
   add t0,t1
   li t0,7
   li t1,8
   
   li t1, 0x01000000
   RUNDMA_wait_LI_ADD:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_LI_ADD
   nop
jr $31
nop

.align 64
test_RUNDMA_READ_SCRATCHPAD: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lui t0, 0x1F80
   lw t1,0(t0)
   nop
   move t0,t1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_READ_SCRATCHPAD:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_READ_SCRATCHPAD
   nop
jr $31
nop

.align 64
test_RUNDMA_WRITE_SCRATCHPAD: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lui t0, 0x1F80
   sw t1,0(t0)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_WRITE_SCRATCHPAD:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_WRITE_SCRATCHPAD
   nop
jr $31
nop

.align 64
test_RUNDMA_READ_RAM: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lui t0, 0x0010
   lw t1,0(t0)
   nop
   move t0,t1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_READ_RAM:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_READ_RAM
   nop
jr $31
nop

.align 64
test_RUNDMA_WRITE_RAM: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lui t0, 0x0010
   sw t1,0(t0)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_WRITE_RAM:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_WRITE_RAM
   nop
jr $31
nop

.align 64
test_RUNDMA_READ_GTE: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   mfc2 t0,MAC1
   nop
   move t0,t1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_READ_GTE:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_READ_GTE
   nop
jr $31
nop

.align 64
test_RUNDMA_WRITE_GTE: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   mtc2 t0,MAC1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_WRITE_GTE:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_WRITE_GTE
   nop
jr $31
nop

.align 64
test_RUNDMA_READ_TIMER: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lh t0,T1_CNT(a0)
   nop
   move t0,t1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_READ_TIMER:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_READ_TIMER
   nop
jr $31
nop

.align 64
test_RUNDMA_WRITE_TIMER: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   sh t0,T1_CNT(a0)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_WRITE_TIMER:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_WRITE_TIMER
   nop
jr $31
nop

.align 64
test_RUNDMA_READ_SPU: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   lh t0,SPUFRQ0(a0)
   nop
   move t0,t1
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_READ_SPU:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_READ_SPU
   nop
jr $31
nop

.align 64
test_RUNDMA_WRITE_SPU: 
   move t0,s4
   sw t0,D0_MADR(a0)
   sw s5,D0_BCR(a0)
   li t0,0x11000001
   sw t0,D0_CHCR(a0)
   
   sh t0,SPUFRQ0(a0)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   
   li t1, 0x01000000
   RUNDMA_wait_WRITE_SPU:
      lw t0, D0_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMA_wait_WRITE_SPU
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
  
TEXT_TEST:              .db "TEST",0
TEXT_OUTOF:             .db "OUT OF ",0
TEXT_TP:                .db "TESTS PASS",0
TEXT_CYCLES:            .db "CYCLES",0
TEXT_PS1_LOW:           .db "PS1LO",0
TEXT_PS1_HIGH:          .db "PS1HI",0
      
TEXT_EMPTY:             .db "EMPTY",0
TEXT_SETUP:             .db "SETUP",0
TEXT_WAITDONE:          .db "WAITDONE",0
   
TEXT_DMA_2_NOPS:        .db "DMA 2 NOPS",0
TEXT_DMA_11_NOPS:       .db "DMA 11 NOPS",0
TEXT_DMA_LI_ADD:        .db "DMA LI ADD",0
TEXT_DMA_READ_SPAD:     .db "DMA READ SPAD",0
TEXT_DMA_WRITE_SPAD:    .db "DMA WRITE SPAD",0
TEXT_DMA_READ_RAM:      .db "DMA READ RAM",0
TEXT_DMA_WRITE_RAM:     .db "DMA WRITE RAM",0
TEXT_DMA_READ_GTE:      .db "DMA READ GTE",0
TEXT_DMA_WRITE_GTE:     .db "DMA WRITE GTE",0
TEXT_DMA_READ_TIMER:    .db "DMA READ TIMER",0
TEXT_DMA_WRITE_TIMER:   .db "DMA WRITE TIMER",0
TEXT_DMA_READ_SPU:      .db "DMA READ SPU",0
TEXT_DMA_WRITE_SPU:     .db "DMA WRITE SPU",0
   
TEXT_ERROR:             .db "ERROR",0

.close