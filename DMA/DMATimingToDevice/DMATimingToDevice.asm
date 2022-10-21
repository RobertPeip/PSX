; PSX 'Bare Metal' Test
.psx
.create "DMATimingToDevice.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction, ps1time_low, ps1time_high

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   
   li s3,500
   li s2,0
   
   checkloop:
      WRIOH T0_CNTM,0x0008 ; reset
      RDIOH T0_CNT,s1
      jal testfunction
      nop
      RDIOH T0_CNT,s4
      sub s4,s1
      add s2,s4
      
      li t1, 0x0200
      waitbusy:
         lh t0, SPUSTAT(a0)
         nop
         and t0, t1
         beqz t0,waitbusy 
         nop
      
      bnez s3,checkloop
      subiu s3,1
      

   li t0,500
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
   
   PrintText 20,s6,text
   PrintDezValue 140,s6,s1
   PrintDezValue 200,s6,s2
   PrintDezValue 260,s6,s3
   
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
; init Devices
;-----------------------------------------------------------------------------

li t0,0xC020 ; send to SPU
sh t0,SPUCNT(a0)

;-----------------------------------------------------------------------------
; test execution
;-----------------------------------------------------------------------------

; set new timings
;li s1, 0x220931E1
li s1, 0x200931E1
sw s1,SPU_DELAY(a0)

;li s1, 0x00031125 
;li s1, 0x00001325 
li s1, 0x0000132C 
sw s1,COM_DELAY(a0)

li s6, 20 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 140,s6,TEXT_CYCLES
PrintText 200,s6,TEXT_PS1_LOW
PrintText 260,s6,TEXT_PS1_HIGH
addiu s6,10

; instruction tests
SingleTest TEXT_SPU1BLOCK1  , test_SPU1BLOCK1INSTANT  , 37, 42
SingleTest TEXT_SPU1BLOCK1  , test_SPU1BLOCK1         , 37, 42
SingleTest TEXT_SPU1BLOCK16 , test_SPU1BLOCK16        , 97, 101
SingleTest TEXT_SPU16BLOCK16, test_SPU16BLOCK16       , 16607, 16770

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
test_SPU1BLOCK1INSTANT:
   li t0,0x00010001  
   sw t0,D4_BCR(a0)
   li t0,0x11000001
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   SPU1BLOCK1INSTANT_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,SPU1BLOCK1INSTANT_wait 
   nop
jr $31
nop


.align 64
test_SPU1BLOCK1:
   li t0,0x00010001  
   sw t0,D4_BCR(a0)
   li t0,0x11000201
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   SPU1BLOCK1_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,SPU1BLOCK1_wait 
   nop
jr $31
nop

.align 64
test_SPU1BLOCK16:
   li t0,0x00010010  
   sw t0,D4_BCR(a0)
   li t0,0x11000201
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   SPU1BLOCK16_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,SPU1BLOCK16_wait 
   nop
jr $31
nop

.align 64
test_SPU16BLOCK16:
   li t0,0x00100010  
   sw t0,D4_BCR(a0)
   li t0,0x11000201
   sw t0,D4_CHCR(a0)
   nop
   nop
   nop
   nop
   li t1, 0x01000000
   SPU16BLOCK16_wait:
      lw t0, D4_CHCR(a0)
      nop
      and t0, t1
      bnez t0,SPU16BLOCK16_wait 
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
   
TEXT_SPU1BLOCK1:     .db "SPU1BLOCK1",0
TEXT_SPU1BLOCK16:    .db "SPU1BLOCK16",0
TEXT_SPU16BLOCK16:   .db "SPU16BLOCK16",0

.close