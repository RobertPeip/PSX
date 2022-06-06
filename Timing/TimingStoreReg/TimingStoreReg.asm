; PSX 'Bare Metal' Test
.psx
.create "TimingStoreReg.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction, addr, ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   li s4,addr

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

   li t0,100
   div s2,t0
   mflo s1
   
   li s2, ps1time
   
.endmacro

.macro Widthtest,text, addr, ps1time_b, ps1time_h, ps1time_w

   SingleTest text,test_sb, addr, ps1time_b
   PrintDezValue 80,s6,s1
   PrintDezValue 110,s6,s2

   SingleTest text,test_sh, addr, ps1time_h
   PrintDezValue 160,s6,s1
   PrintDezValue 190,s6,s2
   
   SingleTest text,test_sw, addr, ps1time_w
   PrintDezValue 240,s6,s1
   PrintDezValue 280,s6,s2

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
PrintText 80,s6,TEXT_B
PrintText 110,s6,TEXT_PS1
PrintText 160,s6,TEXT_H
PrintText 190,s6,TEXT_PS1
PrintText 240,s6,TEXT_W
PrintText 270,s6,TEXT_PS1
addiu s6,10

; instruction tests
Widthtest TEXT_SPAD , 0x1F800000, 16, 16, 16
Widthtest TEXT_RAM  , 0x00000000, 16, 16, 16
Widthtest TEXT_DMA  , 0x1F8010F0, 16, 16, 16
Widthtest TEXT_JOY  , 0x1F801044, 16, 16, 16
Widthtest TEXT_IRQ  , 0x1F801070, 16, 16, 16
Widthtest TEXT_TMR  , 0x1F801110, 16, 16, 16
Widthtest TEXT_CD   , 0x1F801800, 16, 32, 63
Widthtest TEXT_GPU  , 0x1F801810, 16, 16, 16
Widthtest TEXT_MDEC , 0x1F801824, 16, 16, 16
Widthtest TEXT_SPU  , 0x1F801DA8, 16, 16, 28
Widthtest TEXT_SIO  , 0x1F801054, 16, 16, 16
Widthtest TEXT_EXP1 , 0x1F000000, 17, 34, 67
Widthtest TEXT_EXP2 , 0x1F802000, 22, 44, 89
Widthtest TEXT_EXP3 , 0x1FA00000, 16, 16, 16

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
test_sb:  
   sb t0,0(s4)
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
test_sh:  
   sh t0,0(s4)
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
test_sw:  
   sw t0,0(s4)
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

;-----------------------------------------------------------------------------
; constants area
;-----------------------------------------------------------------------------

.align 4

FontBlack: .incbin "../../LIB/FontBlack8x8.bin"
  
VALUEWORDG: .dw 0xFFFFFFFF
  
TEXT_TEST:       .db "TEST",0
TEXT_CYCLES:     .db "CYCLES",0
TEXT_B:          .db "B",0
TEXT_H:          .db "H",0
TEXT_W:          .db "W",0
TEXT_PS1:        .db "PS1",0

TEXT_10NOP:      .db "10NOP",0

TEXT_SPAD:       .db "SPAD",0
TEXT_RAM:        .db "RAM",0

TEXT_DMA:        .db "DMA",0
TEXT_JOY:        .db "JOY",0
TEXT_IRQ:        .db "IRQ",0
TEXT_TMR:        .db "TMR",0
TEXT_CD:         .db "CD",0
TEXT_GPU:        .db "GPU",0
TEXT_MDEC:       .db "MDEC",0
TEXT_SPU:        .db "SPU",0
TEXT_SIO:        .db "SIO",0
TEXT_BIOS:       .db "BIOS",0
TEXT_CTRL:       .db "CTRL",0
TEXT_EXP1:       .db "EXP1",0
TEXT_EXP2:       .db "EXP2",0
TEXT_EXP3:       .db "EXP3",0

.close