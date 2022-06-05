; PSX 'Bare Metal' Test
.psx
.create "TimingLoadRAM.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction, ps1time

   .align 64 ;make sure it fits in cache together with executing function

   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   nop

   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T0_CNTM,0x0008 ; reset
   
   li s3,100
   RDIOH T0_CNT,s1
   
   checkloop:
      jal testfunction
      nop
      bnez s3,checkloop
      subiu s3,1
   
   RDIOH T0_CNT,s2
   
   sub s2,s1
   PrintDezValue 110,s6,s2
   
   li t0,100
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

li s4,0x4710 
li s5,0x0714 

SingleTest TEXT_LWNOUSE,test_lwnouse, 18

SingleTest TEXT_LWUSE0 ,test_lwuse0, 18
SingleTest TEXT_LWUSE1 ,test_lwuse1, 22
SingleTest TEXT_LWUSE2 ,test_lwuse2, 22
SingleTest TEXT_LWUSE3 ,test_lwuse3, 21
SingleTest TEXT_LWUSE4 ,test_lwuse4, 20
SingleTest TEXT_LWUSE5 ,test_lwuse5, 19
SingleTest TEXT_LWUSE6 ,test_lwuse6, 18
SingleTest TEXT_LWUSE7 ,test_lwuse7, 18

SingleTest TEXT_LBUSE1 ,test_lbuse1, 22

SingleTest TEXT_LW2X   ,test_lw2x, 28
SingleTest TEXT_LW3X1  ,test_lw3x1, 32
SingleTest TEXT_LW3X2  ,test_lw3x2, 34

lui s4, 0x1F80
SingleTest TEXT_LWSPAD1 ,test_lwuse1, 16 ; same test as LW but using different address

endloop:
  b endloop
  nop ; Delay Slot

;-----------------------------------------------------------------------------
; tests
;-----------------------------------------------------------------------------

.align 64 ; make sure it fits in cache together with executing loop
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
test_lwnouse:  
   lw t0,0(s4)
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
test_lwuse0:  
   lw t0,0(s4)
   move t1,t0
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
test_lwuse1:  
   lw t0,0(s4)
   nop
   move t1,t0
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
test_lwuse2:  
   lw t0,0(s4)
   nop
   nop
   move t1,t0
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_lwuse3:  
   lw t0,0(s4)
   nop
   nop
   nop
   move t1,t0
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_lwuse4:  
   lw t0,0(s4)
   nop
   nop
   nop
   nop
   move t1,t0
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_lwuse5:  
   lw t0,0(s4)
   nop
   nop
   nop
   nop
   nop
   move t1,t0
   nop
   nop
   nop
jr $31
nop

.align 64
test_lwuse6:  
   lw t0,0(s4)
   nop
   nop
   nop
   nop
   nop
   nop
   move t1,t0
   nop
   nop
jr $31
nop

.align 64
test_lwuse7:  
   lw t0,0(s4)
   nop
   nop
   nop
   nop
   nop
   nop
   nop
   move t1,t0
   nop
jr $31
nop

.align 64
test_lbuse1:  
   lb t0,0(s4)
   nop
   move t1,t0
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
test_lw2x:  
   lw t0,0(s4)
   lw t1,0(s5)
   move t2,t0
   move t3,t1
   nop
   nop
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_lw3x1:  
   lw t0,0(s4)
   lw t1,0(s5)
   lw t2,0(s4)
   move t3,t0
   move t4,t1
   move t5,t2
   nop
   nop
   nop
   nop
jr $31
nop

.align 64
test_lw3x2:  
   lw t0,0(s4)
   lw t1,0(s5)
   move t3,t0
   move t4,t1
   lw t2,0(s4)
   nop
   move t5,t2
   nop
   nop
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

TEXT_LWNOUSE:   .db "LWNOUSE",0

TEXT_LWUSE0:    .db "LWUSE0",0
TEXT_LWUSE1:    .db "LWUSE1",0
TEXT_LWUSE2:    .db "LWUSE2",0
TEXT_LWUSE3:    .db "LWUSE3",0
TEXT_LWUSE4:    .db "LWUSE4",0
TEXT_LWUSE5:    .db "LWUSE5",0
TEXT_LWUSE6:    .db "LWUSE6",0
TEXT_LWUSE7:    .db "LWUSE7",0

TEXT_LBUSE1:    .db "LBUSE1",0

TEXT_LW2X:      .db "LW2X",0
TEXT_LW3X1:     .db "LW3X1",0
TEXT_LW3X2:     .db "LW3X2",0

TEXT_LWSPAD1:   .db "LWSPAD1",0

.close