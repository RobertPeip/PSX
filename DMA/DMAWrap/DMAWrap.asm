; PSX 'Bare Metal' Test
.psx
.create "DMAWrap.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80050000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testfunction, testname

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,2 ; runcount
   
   jal test_PREPAREMEM
   nop
   
   jal testfunction
   nop 
   
   jal test_OUTPUTRESULT
   nop 
      
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
addiu s6,10

; tests 
addiu s6,10

SingleTest  test_EMPTY        , TEXT_EMPTY
SingleTest  test_OTC_100000_1 , TEXT_OTC_100000_1
SingleTest  test_OTC_000000_1 , TEXT_OTC_000000_1
SingleTest  test_OTC_000004_2 , TEXT_OTC_000004_2
SingleTest  test_OTC_000000_2 , TEXT_OTC_000000_2
SingleTest  test_OTC_000004_0 , TEXT_OTC_000004_0
SingleTest  test_OTC_040000_0 , TEXT_OTC_040000_0
SingleTest  test_OTC_03FFFC_0 , TEXT_OTC_03FFFC_0
SingleTest  test_OTC_FFFFFC_0 , TEXT_OTC_FFFFFC_0
SingleTest  test_OTC_FFFFFC_2 , TEXT_OTC_FFFFFC_2
SingleTest  test_OTC_7FFFFC_2 , TEXT_OTC_7FFFFC_2
SingleTest  test_OTC_3FFFFC_2 , TEXT_OTC_3FFFFC_2
SingleTest  test_OTC_1FFFFC_2 , TEXT_OTC_1FFFFC_2

SingleTest  test_CD_1FFFFC_1  , TEXT_CD_1FFFFC_1
SingleTest  test_CD_1FFFFC_2  , TEXT_CD_1FFFFC_2
SingleTest  test_CD_3FFFFC_2  , TEXT_CD_3FFFFC_2
SingleTest  test_CD_7FFFFC_2  , TEXT_CD_7FFFFC_2
;SingleTest  test_CD_FFFFFC_2  , TEXT_CD_FFFFFC_2 -> skipped because write to 8-16mbyte area crashes on PSX, why only for CD?
SingleTest  test_CD_1FFF04_512, TEXT_CD_1FFF04_512

endloop:
  b endloop
  nop ; Delay Slot

;-----------------------------------------------------------------------------
; tests
;-----------------------------------------------------------------------------

.align 4096 ; make sure it fits in cache together with executing loop

.align 64
test_PREPAREMEM:  

   li t0,0
   li t1,0xFE000000
   sw t1,0(t0)
   
   li t0,0x1FFFFC
   li t1,0xFF1FFFFC
   sw t1,0(t0)
   
jr $31
nop

.align 64
test_OUTPUTRESULT:  

   li t0,0
   lw s5,0(t0)
   nop
   PrintHexValue 150,s6,s5
   
   li t0,0x1FFFFC
   lw s5,0(t0)
   nop
   PrintHexValue 250,s6,s5
   
jr $31
nop

.align 64
test_EMPTY:
jr $31
nop

.align 64
test_OTC_100000_1:  
   li t0,0x00100000
   sw t0,D6_MADR(a0)
   li t0,0x00000001
   sw t0,D6_BCR(a0)
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
test_OTC_000000_1:  
   li t0,0x00000000
   sw t0,D6_MADR(a0)
   li t0,0x00000001
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait1:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait1
   nop
jr $31
nop

.align 64
test_OTC_000004_2:  
   li t0,0x00000004
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait2:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait2
   nop
jr $31
nop

.align 64
test_OTC_000000_2:  
   li t0,0x00000000
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait3:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait3
   nop
jr $31
nop

.align 64
test_OTC_000004_0:  
   li t0,0x00000004
   sw t0,D6_MADR(a0)
   li t0,0x00000000
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait4:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait4
   nop
jr $31
nop

.align 64
test_OTC_040000_0:  
   li t0,0x00040000
   sw t0,D6_MADR(a0)
   li t0,0x00000000
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait5:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait5
   nop
jr $31
nop

.align 64
test_OTC_03FFFC_0:  
   li t0,0x0003FFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000000
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait6:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait6
   nop
jr $31
nop

.align 64
test_OTC_FFFFFC_0:  
   li t0,0x00FFFFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000000
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait7:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait7
   nop
jr $31
nop

.align 64
test_OTC_FFFFFC_2:  
   li t0,0x00FFFFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait8:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait8
   nop
jr $31
nop

.align 64
test_OTC_7FFFFC_2:  
   li t0,0x007FFFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait9:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait9
   nop
jr $31
nop

.align 64
test_OTC_3FFFFC_2:  
   li t0,0x003FFFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait10:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait10
   nop
jr $31
nop

.align 64
test_OTC_1FFFFC_2:  
   li t0,0x001FFFFC
   sw t0,D6_MADR(a0)
   li t0,0x00000002
   sw t0,D6_BCR(a0)
   li t0,0x11000002
   sw t0,D6_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNOTC_wait11:
      lw t0, D6_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNOTC_wait11
   nop
jr $31
nop

.align 64
test_CD_1FFFFC_1:  
   li t0,0x001FFFFC
   sw t0,D3_MADR(a0)
   li t0,0x00000001
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait0:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait0
   nop
jr $31
nop

.align 64
test_CD_1FFFFC_2:  
   li t0,0x001FFFFC
   sw t0,D3_MADR(a0)
   li t0,0x00000002
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait 
   nop
jr $31
nop

.align 64
test_CD_3FFFFC_2:  
   li t0,0x003FFFFC
   sw t0,D3_MADR(a0)
   li t0,0x00000002
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait1:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait1
   nop
jr $31
nop

.align 64
test_CD_7FFFFC_2:  
   li t0,0x007FFFFC
   sw t0,D3_MADR(a0)
   li t0,0x00000002
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait2:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait2
   nop
jr $31
nop

.align 64
test_CD_FFFFFC_2:  
   li t0,0x00FFFFFC
   sw t0,D3_MADR(a0)
   li t0,0x00000002
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait3:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait3
   nop
jr $31
nop

.align 64
test_CD_1FFF04_512:  
   li t0,0x001FFF04
   sw t0,D3_MADR(a0)
   li t0,0x00000200
   sw t0,D3_BCR(a0)
   li t0,0x11000000
   sw t0,D3_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   RUNDMACD_wait4:
      lw t0, D3_CHCR(a0)
      nop
      and t0, t1
      bnez t0,RUNDMACD_wait4
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
  
TEXT_TEST:           .db "TEST        DATA AT 0X0   AT 0X1FFFFC",0
TEXT_OUTOF:          .db "OUT OF ",0
TEXT_TP:             .db "TESTS PASS",0
   
TEXT_EMPTY:          .db "EMPTY",0

TEXT_OTC_100000_1:   .db "OTC 100000 1",0
TEXT_OTC_000000_1:   .db "OTC 000000 1",0
TEXT_OTC_000004_2:   .db "OTC 000004 2",0
TEXT_OTC_000000_2:   .db "OTC 000000 2",0
TEXT_OTC_000004_0:   .db "OTC 000004 0",0
TEXT_OTC_040000_0:   .db "OTC 040000 0",0
TEXT_OTC_03FFFC_0:   .db "OTC 03FFFC 0",0
TEXT_OTC_FFFFFC_0:   .db "OTC FFFFFC 0",0
TEXT_OTC_FFFFFC_2:   .db "OTC FFFFFC 2",0
TEXT_OTC_7FFFFC_2:   .db "OTC 7FFFFC 2",0
TEXT_OTC_3FFFFC_2:   .db "OTC 3FFFFC 2",0
TEXT_OTC_1FFFFC_2:   .db "OTC 1FFFFC 2",0

TEXT_CD_1FFFFC_1:    .db "CD  1FFFFC 1",0
TEXT_CD_1FFFFC_2:    .db "CD  1FFFFC 2",0
TEXT_CD_3FFFFC_2:    .db "CD  3FFFFC 2",0
TEXT_CD_7FFFFC_2:    .db "CD  7FFFFC 2",0
TEXT_CD_FFFFFC_2:    .db "CD  FFFFFC 2",0
TEXT_CD_1FFF04_512:  .db "CD  1FFF04 512",0

.close