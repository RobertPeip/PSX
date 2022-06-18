; PSX 'Bare Metal' Test
.psx
.create "Load816Unalign.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro report, ps1value_full32, ps1value_b1, ps1value_b2, ps1value_b3, ps1value_h2

   li s2,ps1value_full32
   PrintHexValue 80,s6,s2  
   
   li s2,ps1value_b1
   PrintHexValue8 150,s6,s2  
   
   li s2,ps1value_b2
   PrintHexValue8 170,s6,s2  

   li s2,ps1value_b3
   PrintHexValue8 190,s6,s2   
   
   li s2,ps1value_h2
   PrintHexValue16 210,s6,s2   

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

.macro StoreValue, writevalue, writedata

   li t1,writedata
   beqz t1,skipwrite
   nop
   
   li t1, 0
   sw t1,0(s4)

   li t2, writevalue
   srl t2,16
   sh t2,2(s4)
   
   li t2, writevalue
   sw t2,0(s4)
   
   skipwrite:

.endmacro

.macro Widthtest,text, addr, writevalue, write16, ps1value_full32, ps1value_b1, ps1value_b2, ps1value_b3, ps1value_h2

   li s4,addr

   StoreValue writevalue, write16
   ; load full data
   lw s1,0(s4)
   nop
   PrintHexValue 80,s6,s1
   compareresult ps1value_full32
   
   StoreValue writevalue, write16
   ; byte 1
   lb s1,1(s4)
   nop
   PrintHexValue8 150,s6,s1
   compareresult ps1value_b1
   
   StoreValue writevalue, write16
   ; byte 2
   lb s1,2(s4)
   nop
   PrintHexValue8 170,s6,s1
   compareresult ps1value_b2

   StoreValue writevalue, write16
   ; byte 3
   lb s1,3(s4)
   nop
   PrintHexValue8 190,s6,s1
   compareresult ps1value_b3

   StoreValue writevalue, write16
   ; halfword 2
   lh s1,2(s4)
   nop
   PrintHexValue16 210,s6,s1
   compareresult ps1value_h2


   PrintText 20,s6,text
   addiu s6,9

   report ps1value_full32, ps1value_b1, ps1value_b2, ps1value_b3, ps1value_h2

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
PrintText 20, s6,TEXT_AREA
PrintText 80, s6,TEXT_32BIT
PrintText 150,s6,TEXT_81
PrintText 170,s6,TEXT_82 
PrintText 190,s6,TEXT_83  
PrintText 215,s6,TEXT_162 
addiu s6,10

; tests
Widthtest TEXT_SPAD, 0x1F800000, 0x12345678, 1, 0x12345678, 0x56, 0x34, 0x12, 0x1234 
Widthtest TEXT_DMA,  0x1F8010F0, 0x12345678, 1, 0x12345678, 0x56, 0x34, 0x12, 0x1234
Widthtest TEXT_SIO,  0x1F801058, 0x12345678, 1, 0x12240078, 0x00, 0x24, 0x12, 0x1224
Widthtest TEXT_JOY,  0x1F801048, 0x12345678, 1, 0x12240038, 0x00, 0x24, 0x12, 0x1224
Widthtest TEXT_IRQ,  0x1F801074, 0x12345678, 1, 0x12340678, 0x06, 0x34, 0x12, 0x1234
Widthtest TEXT_SPU,  0x1F801C04, 0x12345678, 1, 0x12345678, 0x56, 0x34, 0x12, 0x1234
Widthtest TEXT_MEMC, 0x1F801000, 0x12345678, 1, 0x1F345678, 0x56, 0x34, 0x1F, 0x1F34

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
TEXT_32BIT:      .db "32BIT",0
TEXT_81:         .db "81",0
TEXT_82:         .db "82",0
TEXT_83:         .db "83",0
TEXT_162:        .db "162",0
TEXT_PS1:        .db "PS1",0

TEXT_SPAD:       .db "SPAD",0

TEXT_DMA:        .db "DMA",0
TEXT_JOY:        .db "JOY",0
TEXT_IRQ:        .db "IRQ",0
TEXT_CD:         .db "CD",0
TEXT_SPU:        .db "SPU",0
TEXT_SIO:        .db "SIO",0
TEXT_MEMC:       .db "MEMC",0

.close