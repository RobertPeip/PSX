; PSX 'Bare Metal' Test
.psx
.create "TimingCPU.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro IdleLoop,text,count,ps1time

   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T0_CNTM,0x0008 ; reset
   
   li s3,count
   RDIOH T0_CNT,s1
   
   checkloop:
      bnez s3,checkloop
      subiu s3,1
   
   RDIOH T0_CNT,s2
   
   sub s2,s1
   PrintDezValue 110,s6,s2
   
   li t0,count
   div s2,t0
   mflo s1
   PrintDezValue 190,s6,s1
   
   li s2, ps1time
   PrintDezValue 240,s6,s2
   
   PrintText 20,s6,text
   
   addiu s6,10

.endmacro

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

; IDLE loops
IdleLoop TEXT_IDLE100 ,100  , 2
IdleLoop TEXT_IDLE200 ,200  , 2
IdleLoop TEXT_IDLE1000,1000 , 2

; instruction tests
SingleTest TEXT_EMPTY ,test_empty , 6
SingleTest TEXT_NOP   ,test_nop   , 7
SingleTest TEXT_ADDIU ,test_addiu , 7

SingleTest TEXT_multu0 ,test_multu0 , 17
SingleTest TEXT_multu1 ,test_multu1 , 20
SingleTest TEXT_multu2 ,test_multu2 , 25
SingleTest TEXT_multu3 ,test_multu3 , 17
SingleTest TEXT_multu4 ,test_multu4 , 18
SingleTest TEXT_multu5 ,test_multu5 , 25
SingleTest TEXT_multu6 ,test_multu6 , 24

SingleTest TEXT_divu0 ,test_divu0 , 48
SingleTest TEXT_divu1 ,test_divu1 , 48
SingleTest TEXT_divu2 ,test_divu2 , 48

endloop:
  b endloop
  nop ; Delay Slot

;-----------------------------------------------------------------------------
; tests
;-----------------------------------------------------------------------------

.align 64 ; make sure it fits in cache together with executing loop
test_empty:
jr $31
nop

.align 64
test_nop:  
   nop
jr $31
nop

.align 64
test_addiu:  
   addiu t0,0x1234
jr $31
nop

.align 64
test_multu0:   ; 1*1
   li t0, 1
   li t1, 1
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu1:   ; 0xFFFF*1
   li t0, 0xFFFF
   li t1, 1
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu2:   ; 0xFFFFFFFF*1
   lui t0, 0xFFFF
   addiu t0,0xFFFF
   li t1, 1
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu3:   ; 1*0xFFFF
   li t0, 1
   li t1, 0xFFFF
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu4:   ; 1*0xFFFFFFFF
   li t0, 1
   lui t1, 0xFFFF
   addiu t1,0xFFFF
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu5:   ; 0xFFFFFFFF*0xFFFFFFFF
   lui t0, 0xFFFF
   addiu t0,0xFFFF
   move t1,t0
   multu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_multu6:   ; 0xFFFFFFFF*0xFFFFFFFF but only 1 move
   lui t0, 0xFFFF
   addiu t0,0xFFFF
   move t1,t0
   multu t0,t1
   mflo t2
jr $31
nop

.align 64
test_divu0:   ; 1 / 0
   li t0, 1
   nop
   li t1, 1
   divu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_divu1:   ; 0xFFFF / 0xAAAA
   li t0, 0xFFFF
   nop
   li t1, 0xAAAA
   divu t0,t1
   mflo t2
   mfhi t3
jr $31
nop

.align 64
test_divu2:   ; 0xFFFFFFFF / 0xFFFFFFFF
   lui t0, 0xFFFF
   addiu t0,0xFFFF
   move t1,t0
   divu t0,t1
   mflo t2
   mfhi t3
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

TEXT_IDLE100:    .db "IDLE100",0
TEXT_IDLE200:    .db "IDLE200",0
TEXT_IDLE1000:   .db "IDLE1000",0

TEXT_EMPTY:      .db "EMPTY",0
TEXT_NOP:        .db "NOP",0
TEXT_ADDIU:      .db "ADDIU",0

TEXT_MULTU0:     .db "MULTU 1x1",0
TEXT_MULTU1:     .db "M 16x1",0
TEXT_MULTU2:     .db "M 32x1",0
TEXT_MULTU3:     .db "M 1x16",0
TEXT_MULTU4:     .db "M 1x32",0
TEXT_MULTU5:     .db "M 32x32HL",0
TEXT_MULTU6:     .db "M 32x32L",0

TEXT_DIVU0:      .db "DIVU 1/0",0
TEXT_DIVU1:      .db "D 16/16",0
TEXT_DIVU2:      .db "D 32/32",0

.close