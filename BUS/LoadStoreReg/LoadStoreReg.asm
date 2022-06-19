; PSX 'Bare Metal' Test
.psx
.create "LoadStoreReg.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro report, ps1value_b, ps1value_h, ps1value_w

   li s2,ps1value_b
   PrintHexValue 80,s6,s2   
   
   li s2,ps1value_h
   PrintHexValue 160,s6,s2   
   
   li s2,ps1value_w
   PrintHexValue 240,s6,s2

   PrintText 20,s6,TEXT_PS1
   addiu s6,13

.endmacro

.macro compareresult, value

   li s2,value

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   bne s1,s2,testfail
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfail:
   
.endmacro

.macro Widthtest,text, addr, ps1value_b, ps1value_h, ps1value_w

   ; 8 bit
   li t1, 0
   li t2, 0x12345678
   li s4,addr
   
   sw t1,0(s4)
   sb t2,0(s4)
   lw s1,0(s4)
   nop
   PrintHexValue 80,s6,s1
   
   compareresult ps1value_b
   
   ; 16 bit
   li t1, 0
   li t2, 0x12345678
   li s4,addr
   
   sw t1,0(s4)
   sh t2,0(s4)
   lw s1,0(s4)
   nop
   PrintHexValue 160,s6,s1
   
   compareresult ps1value_h
   
   ; 32 bit
   li t1, 0
   li t2, 0x12345678
   li s4,addr
   
   sw t1,0(s4)
   sw t2,0(s4)
   lw s1,0(s4)
   nop
   PrintHexValue 240,s6,s1
   
   compareresult ps1value_w

   PrintText 20,s6,text
   addiu s6,9
   
   report ps1value_b, ps1value_h, ps1value_w
   
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
PrintText 20,s6,TEXT_AREA
PrintText 80,s6,TEXT_8BIT
PrintText 160,s6,TEXT_16BIT
PrintText 240,s6,TEXT_32BIT
addiu s6,10

; tests
Widthtest TEXT_SPAD, 0x1F800000, 0x00000078, 0x00005678, 0x12345678
Widthtest TEXT_DMA,  0x1F8010F0, 0x12345678, 0x12345678, 0x12345678
Widthtest TEXT_SIO,  0x1F801058, 0x00000078, 0x00000078, 0x00000078
Widthtest TEXT_JOY,  0x1F801048, 0x00000038, 0x00000038, 0x00000038
Widthtest TEXT_IRQ,  0x1F801074, 0x12340678, 0x12340678, 0x12340678
Widthtest TEXT_SPU,  0x1F801C04, 0x00005678, 0x00005678, 0x12345678
Widthtest TEXT_EXP2, 0x1F802000, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF

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
; constants area
;-----------------------------------------------------------------------------

.align 4

FontBlack: .incbin "../../LIB/FontBlack8x8.bin"
  
VALUEWORDG: .dw 0xFFFFFFFF
  
TESTCOUNT: .dw 0x0
TESTSPASS: .dw 0x0
  
TEXT_OUTOF:      .db "OUT OF ",0
TEXT_TP:         .db "TESTS PASS",0
  
TEXT_AREA:       .db "AREA",0
TEXT_8BIT:       .db "8 BIT",0
TEXT_16BIT:      .db "16 BIT",0
TEXT_32BIT:      .db "32 BIT",0
TEXT_PS1:        .db "PS1",0

TEXT_SPAD:       .db "SPAD",0

TEXT_DMA:        .db "DMA",0
TEXT_JOY:        .db "JOY",0
TEXT_IRQ:        .db "IRQ",0
TEXT_CD:         .db "CD",0
TEXT_SPU:        .db "SPU",0
TEXT_SIO:        .db "SIO",0
TEXT_EXP2:       .db "EXP2",0

.close