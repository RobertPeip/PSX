; PSX 'Bare Metal' Test
.psx
.create "TimingStoreRAM.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction, ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048

   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T0_CNTM,0x0008 ; reset
   
   li s3,400
   RDIOH T0_CNT,s1
   
   checkloop:
      jal testfunction
      nop
      bnez s3,checkloop
      subiu s3,1
   
   RDIOH T0_CNT,s2
   
   sub s2,s1
   PrintDezValue 110,s6,s2
   
   li t0,400
   div s2,t0
   mflo s1
   PrintDezValue 190,s6,s1
   
   li s2, ps1time
   PrintDezValue 240,s6,s2
   
   PrintText 20,s6,text
   
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
PrintText 100,s6,TEXT_CYCLES
PrintText 180,s6,TEXT_AVG
PrintText 240,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest TEXT_10NOP ,test_10nop, 16

lui t1, 0x0000

SingleTest TEXT_SWFIFO1, test_sw1,  16

lui t1, 0x0000
lui t2, 0x0010

SingleTest TEXT_SWFIFO2, test_sw2,  16

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020

SingleTest TEXT_SWFIFO3, test_sw3,  18

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030

SingleTest TEXT_SWFIFO4, test_sw4,  25

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030
lui t5, 0x0040

SingleTest TEXT_SWFIFO5, test_sw5,  31

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030
lui t5, 0x0040

SingleTest TEXT_SWFIFO6, test_sw6,  32

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030
lui t5, 0x0040

SingleTest TEXT_SWFIFO7, test_sw7,  43

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030
lui t5, 0x0040

SingleTest TEXT_SWFIFO8, test_sw8,  50

lui t1, 0x0000
lui t2, 0x0010
lui t3, 0x0020
lui t4, 0x0030
lui t5, 0x0040

SingleTest TEXT_SWFIFO9,test_sw9, 56

lui t1, 0xA000
lui t2, 0xA010
lui t3, 0xA020
lui t4, 0xA030
lui t5, 0xA040

SingleTest TEXT_SWNOFIFO9,test_sw9, 56

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000

SingleTest TEXT_SWFIFO3S,test_sw3, 16

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000

SingleTest TEXT_SWFIFO4S,test_sw4, 16

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000
lui t5, 0x0000

SingleTest TEXT_SWFIFO5S,test_sw5, 16

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000
lui t5, 0x0000

SingleTest TEXT_SWFIFO6S,test_sw6, 18

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000
lui t5, 0x0000

SingleTest TEXT_SWFIFO7S,test_sw7, 18

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000
lui t5, 0x0000

SingleTest TEXT_SWFIFO8S,test_sw8, 20

lui t1, 0x0000
lui t2, 0x0000
lui t3, 0x0000
lui t4, 0x0000
lui t5, 0x0000

SingleTest TEXT_SWFIFO9S,test_sw9, 22

lui t1, 0x1F80
lui t2, 0x1F80
lui t3, 0x1F80
lui t4, 0x1F80
lui t5, 0x1F80

SingleTest TEXT_SWSPAD9 ,test_sw9, 16

endloop:
  b endloop
  nop ; Delay Slot

;-----------------------------------------------------------------------------
; tests
;-----------------------------------------------------------------------------

.align 4096 ; make sure it fits in cache together with executing loop
test_10nop:
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
jr $31
nop

.align 64
test_sw1:
   sw t7,0(t1)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw2:
   sw t7,0(t1)
   sw t7,0(t2)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw3:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw4:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw5:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   sw t7,0(t5)
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw6:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   sw t7,0(t5)
   sw t7,0(t1)
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw7:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   sw t7,0(t5)
   sw t7,0(t1)
   sw t7,0(t2)
   nop
   nop
   nop
jr $31
nop

.align 64
test_sw8:
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   sw t7,0(t5)
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   nop
   nop
jr $31
nop

.align 64
test_sw9:  
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   sw t7,0(t5)
   sw t7,0(t1)
   sw t7,0(t2)
   sw t7,0(t3)
   sw t7,0(t4)
   nop
jr $31
nop

;-----------------------------------------------------------------------------
; constants area
;-----------------------------------------------------------------------------

.align 4

FontBlack: .incbin "../../LIB/FontBlack8x8.bin"
  
VALUEWORDG: .dw 0xFFFFFFFF
  
TEXT_TEST:       .db "TEST",0
TEXT_CYCLES:     .db "CYCLES",0
TEXT_AVG:        .db "AVG",0
TEXT_PS1:        .db "PS1",0

TEXT_10NOP:      .db "10NOP",0

TEXT_SWFIFO1:    .db "SWFIFO1",0
TEXT_SWFIFO2:    .db "SWFIFO2",0
TEXT_SWFIFO3:    .db "SWFIFO3",0
TEXT_SWFIFO4:    .db "SWFIFO4",0
TEXT_SWFIFO5:    .db "SWFIFO5",0
TEXT_SWFIFO6:    .db "SWFIFO6",0
TEXT_SWFIFO7:    .db "SWFIFO7",0
TEXT_SWFIFO8:    .db "SWFIFO8",0
TEXT_SWFIFO9:    .db "SWFIFO9",0

TEXT_SWNOFIFO9:  .db "SWNOFIFO9",0

TEXT_SWFIFO3S:   .db "SWFIFO3S",0
TEXT_SWFIFO4S:   .db "SWFIFO4S",0
TEXT_SWFIFO5S:   .db "SWFIFO5S",0
TEXT_SWFIFO6S:   .db "SWFIFO6S",0
TEXT_SWFIFO7S:   .db "SWFIFO7S",0
TEXT_SWFIFO8S:   .db "SWFIFO8S",0
TEXT_SWFIFO9S:   .db "SWFIFO9S",0

TEXT_SWSPAD9:    .db "SWPAD9",0

.close