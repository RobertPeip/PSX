; PSX 'Bare Metal' Test
.psx
.create "DMALINKEDLIST.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, preparefunction, testfunction, testname, ps1time, ps1runcount

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,2 ; runcount
   
   WRGP1 GPUDMA,1
   
   checkloop:
   
      jal preparefunction
      nop
      
      li t4,0
   
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
   
   move s3,t4
   
   li s2, ps1time
   li s0, ps1runcount

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   bne s1, s2,testfail
   nop
   bne s3, s0,testfail
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfail:
   
   PrintText 20,s6,testname
   
   PrintDezValue 160,s6,s1
   PrintDezValue 200,s6,s3
   PrintDezValue 240,s6,s2
   PrintDezValue 280,s6,s0
   
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
PrintText 200,s6,TEXT_RUNS
PrintText 260,s6,TEXT_PS1
addiu s6,10

; instruction tests

li s4, 0x00100000

SingleTest  test_EMPTY                 , test_EMPTY        , TEXT_EMPTY              ,  11 , 0
SingleTest  test_EMPTY                 , test_SETUP        , TEXT_SETUP              ,  18 , 0
SingleTest  test_EMPTY                 , test_WAITDONE     , TEXT_WAITDONE           ,  27 , 0
                                                                                       
SingleTest  prepare_BLOCKWRITE_1       , test_BLOCKWRITE_1 , TEXT_BLOCKWRITE_1       ,  35 , 1
                                                                                         
SingleTest  prepare_LL_1_BL_LEN_0      , test_LL           , TEXT_LL_1_BL_LEN_0      ,  46 , 2
SingleTest  prepare_LL_2_BL_LEN_0      , test_LL           , TEXT_LL_2_BL_LEN_0      ,  56 , 3
SingleTest  prepare_LL_3_BL_LEN_0      , test_LL           , TEXT_LL_3_BL_LEN_0      ,  66 , 4
                                                                                        
SingleTest  prepare_LL_1_BL_LEN_1      , test_LL           , TEXT_LL_1_BL_LEN_1      ,  49 , 2
SingleTest  prepare_LL_2_BL_LEN_1      , test_LL           , TEXT_LL_2_BL_LEN_1      ,  63 , 3
SingleTest  prepare_LL_3_BL_LEN_1      , test_LL           , TEXT_LL_3_BL_LEN_1      ,  77 , 4
                                                                                        
SingleTest  prepare_LL_1_BL_LEN_2      , test_LL           , TEXT_LL_1_BL_LEN_2      ,  50 , 2
SingleTest  prepare_LL_2_BL_LEN_2      , test_LL           , TEXT_LL_2_BL_LEN_2      ,  65 , 3
SingleTest  prepare_LL_3_BL_LEN_2      , test_LL           , TEXT_LL_3_BL_LEN_2      ,  80 , 4
                                                                                         
SingleTest  prepare_LL_1_BL_LEN_3      , test_LL           , TEXT_LL_1_BL_LEN_3      ,  51 , 2
SingleTest  prepare_LL_2_BL_LEN_3      , test_LL           , TEXT_LL_2_BL_LEN_3      ,  67 , 3
SingleTest  prepare_LL_3_BL_LEN_3      , test_LL           , TEXT_LL_3_BL_LEN_3      ,  83 , 4

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
test_EMPTY:
jr $31
nop

.align 64
test_SETUP:  
   move t0,s4
   sw t0,D2_MADR(a0)
   sw r0,D2_BCR(a0)
   lui t0,0x0000
   addiu t0,0x2    
   sw t0,D2_CHCR(a0)
   li t1, 0x01000000
jr $31
nop

.align 64
test_WAITDONE:  
   move t0,s4
   sw t0,D2_MADR(a0)
   sw r0,D2_BCR(a0)
   lui t0,0x0000 ; write like this to have same timing behavior as real test
   addiu t0,0x2  ; write like this to have same timing behavior as real test  
   sw t0,D2_CHCR(a0)
   li t1, 0x01000000
   WAITDONE_wait:
      lw t0, D2_CHCR(a0)
      nop
      and t0, t1
      bnez t0,WAITDONE_wait 
   nop
jr $31
nop

prepare_BLOCKWRITE_1:  
   li t0,0x00000000
   sw t0,0(s4)
jr $31
nop

.align 64
test_BLOCKWRITE_1:  
   li s5,1
   sw s4,D2_MADR(a0)
   sw s5,D2_BCR(a0)
   li t0,0x11000001
   sw t0,D2_CHCR(a0)
   nop
   nop
   li t1, 0x01000000
   RUNDMA_wait_BLOCKWRITE_1:
      lw t0, D2_CHCR(a0)
      addi t4,1
      and t0, t1
      bnez t0,RUNDMA_wait_BLOCKWRITE_1
   nop
jr $31
nop

.align 64
test_LL:  
   move t0,s4
   sw t0,D2_MADR(a0)
   sw r0,D2_BCR(a0)
   li t0,0x01000401
   sw t0,D2_CHCR(a0)
   nop
   nop
   li t1, 0x01000000
   RUNDMA_wait_LL:
      lw t0, D2_CHCR(a0)
      addi t4,1
      and t0, t1
      bnez t0,RUNDMA_wait_LL 
   nop
jr $31
nop

prepare_LL_1_BL_LEN_0:  
   li t0,0x00800000
   sw t0,0(s4)
jr $31
nop

prepare_LL_2_BL_LEN_0:  
   li t0,0x00100004
   sw t0,0(s4)   
   li t0,0x00800000
   sw t0,4(s4)
jr $31
nop

prepare_LL_3_BL_LEN_0:  
   li t0,0x00100004
   sw t0,0(s4)
   li t0,0x00100008
   sw t0,4(s4)
   li t0,0x00800000
   sw t0,8(s4)
jr $31
nop

prepare_LL_1_BL_LEN_1:  
   li t0,0x01800000
   sw t0,0(s4)
   li t0,0x00000000
   sw t0,4(s4)
jr $31
nop

prepare_LL_2_BL_LEN_1:  
   li t0,0x01100008
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)   
   li t0,0x01800000
   sw t0,8(s4)
   li t0,0x00000000
   sw t0,12(s4)
jr $31
nop

prepare_LL_3_BL_LEN_1:  
   li t0,0x01100008
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)   
   li t0,0x01100010
   sw t0,8(s4)
   li t0,0x00000000
   sw t0,12(s4)
   li t0,0x01800000
   sw t0,16(s4)
   li t0,0x00000000
   sw t0,20(s4)
jr $31
nop

prepare_LL_1_BL_LEN_2:  
   li t0,0x02800000
   sw t0,0(s4)
   li t0,0x00000000
   sw t0,4(s4)   
   li t0,0x00000000
   sw t0,8(s4)
jr $31
nop

prepare_LL_2_BL_LEN_2:  
   li t0,0x0210000C
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)      
   li t0,0x00000000
   sw t0,8(s4)   
   li t0,0x02800000
   sw t0,12(s4)
   li t0,0x00000000
   sw t0,16(s4)   
   li t0,0x00000000
   sw t0,20(s4)
jr $31
nop

prepare_LL_3_BL_LEN_2:  
   li t0,0x0210000C
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)      
   li t0,0x00000000
   sw t0,8(s4)   
   li t0,0x02100018
   sw t0,12(s4)  
   li t0,0x00000000
   sw t0,16(s4)      
   li t0,0x00000000
   sw t0,20(s4)   
   li t0,0x02800000
   sw t0,24(s4)
   li t0,0x00000000
   sw t0,28(s4)   
   li t0,0x00000000
   sw t0,32(s4)
jr $31
nop

prepare_LL_1_BL_LEN_3:  
   li t0,0x03800000
   sw t0,0(s4)
   li t0,0x00000000
   sw t0,4(s4)   
   li t0,0x00000000
   sw t0,8(s4)   
   li t0,0x00000000
   sw t0,12(s4)
jr $31
nop

prepare_LL_2_BL_LEN_3:  
   li t0,0x03100010
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)      
   li t0,0x00000000
   sw t0,8(s4)   
   li t0,0x00000000
   sw t0,12(s4)   
   li t0,0x03800000
   sw t0,16(s4)
   li t0,0x00000000
   sw t0,20(s4)   
   li t0,0x00000000
   sw t0,24(s4)   
   li t0,0x00000000
   sw t0,28(s4)
jr $31
nop

prepare_LL_3_BL_LEN_3:  
   li t0,0x03100010
   sw t0,0(s4)  
   li t0,0x00000000
   sw t0,4(s4)      
   li t0,0x00000000
   sw t0,8(s4)  
   li t0,0x00000000
   sw t0,12(s4)      
   li t0,0x03100020
   sw t0,16(s4)  
   li t0,0x00000000
   sw t0,20(s4)      
   li t0,0x00000000
   sw t0,24(s4)
   li t0,0x00000000
   sw t0,28(s4)   
   li t0,0x03800000
   sw t0,32(s4)
   li t0,0x00000000
   sw t0,36(s4)   
   li t0,0x00000000
   sw t0,40(s4)   
   li t0,0x00000000
   sw t0,44(s4)
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
TEXT_RUNS:           .db "RUNS",0
TEXT_PS1:            .db "PS1",0
   
TEXT_EMPTY:          .db "EMPTY",0
TEXT_SETUP:          .db "SETUP",0
TEXT_WAITDONE:       .db "WAITDONE",0
TEXT_BLOCKWRITE_1:   .db "BLOCKWRITE 1",0

TEXT_LL_1_BL_LEN_0:  .db "1 BL LEN 0",0
TEXT_LL_2_BL_LEN_0:  .db "2 BL LEN 0",0
TEXT_LL_3_BL_LEN_0:  .db "3 BL LEN 0",0

TEXT_LL_1_BL_LEN_1:  .db "1 BL LEN 1",0
TEXT_LL_2_BL_LEN_1:  .db "2 BL LEN 1",0
TEXT_LL_3_BL_LEN_1:  .db "3 BL LEN 1",0

TEXT_LL_1_BL_LEN_2:  .db "1 BL LEN 2",0
TEXT_LL_2_BL_LEN_2:  .db "2 BL LEN 2",0
TEXT_LL_3_BL_LEN_2:  .db "3 BL LEN 2",0

TEXT_LL_1_BL_LEN_3:  .db "1 BL LEN 3",0
TEXT_LL_2_BL_LEN_3:  .db "2 BL LEN 3",0
TEXT_LL_3_BL_LEN_3:  .db "3 BL LEN 3",0

TEXT_ERROR:          .db "ERROR",0

.close