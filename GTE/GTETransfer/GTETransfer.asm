; PSX 'Bare Metal' Test
.psx
.create "GTETransfer.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"
.include "../../LIB/PSX_GTE.INC" ; Include PSX GTE Definitions & Macros

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro comparetime, value

   sub s2,s1
   li t0,100
   div s2,t0
   mflo s1
   PrintDezValue 260,s6,s1
   
   li s2, value
   PrintDezValue 290,s6,s2

   li s2,value

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   bne s1,s2,testfailtime
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfailtime:
   
.endmacro

.macro compareresult, value

   li s2,value
   
   PrintHexValue 110,s6,s5
   
   li s2, value
   PrintHexValue 180,s6,s2

   ; add 1 to testcount
   la a2,TESTCOUNT
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   
   ; add 1 to tests passed
   bne s5,s2,testfailvalue
   nop
   la a2,TESTSPASS
   lw t1, 0(a2)
   nop
   addiu t1,1
   sw t1, 0(a2)
   testfailvalue:
   
.endmacro

.macro SingleTest,text,preparefunction,testfunction,ps1value,ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   ; execute function once for value check
   jal preparefunction
   nop
   jal testfunction
   nop
   compareresult ps1value

   ; execute function 100 times for timing check
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
   
   comparetime ps1time
   
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

; Turn On GTE (Set Bit 30 Of The System Control Coprocessor (COP0) Status Register)
li t0,1<<30 ; T0 = 1 << 30
mtc0 t0,sr  ; COP0 Status Register = T0

li s6, 20 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 120,s6,TEXT_VALUE
PrintText 200,s6,TEXT_PS1
PrintText 250,s6,TEXT_TIME
PrintText 290,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest TEXT_NOP       , prepare_zero      , test_nop       , 0x00000000, 7
SingleTest TEXT_MTC2      , prepare_zero      , test_mtc2      , 0x00000000, 7
SingleTest TEXT_MFC2      , prepare_mfc2      , test_mfc2      , 0x12345678, 7
SingleTest TEXT_MTC2MFC2  , prepare_mtc2mfc2  , test_mtc2mfc2  , 0x01234567, 8
SingleTest TEXT_MTC2MFC2D1, prepare_mtc2mfc2  , test_mtc2mfc2D1, 0x01234567, 9
SingleTest TEXT_MTC2MFC2D2, prepare_mtc2mfc2  , test_mtc2mfc2D2, 0xABCDEF12, 10
SingleTest TEXT_LWC2      , prepare_lwc2      , test_lwc2      , 0x00000000, 13
SingleTest TEXT_LWC2MFC2  , prepare_lwc2      , test_lwc2mfc2  , 0x12345678, 14
; test_lwc2mfc2d1 not tested as it returns garbage values 0x0000000A or 0x0000000B randomly, but should be either 0x12345678 or 0xDEADBEEF?
SingleTest TEXT_LWC2MFC2D2, prepare_lwc2      , test_lwc2mfc2d2, 0xDEADBEEF, 16
SingleTest TEXT_SWC2      , prepare_swc2      , test_swc2      , 0x00000000, 9
SingleTest TEXT_SWC2LW    , prepare_swc2      , test_swc2lw    , 0xAFFE4711, 14
SingleTest TEXT_LWMTCMFC  , prepare_lwmtcmfc  , test_lwmtcmfc  , 0x05060708, 17
SingleTest TEXT_LWMTCMFCD1, prepare_lwmtcmfc  , test_lwmtcmfcd1, 0x01020304, 18
SingleTest TEXT_COP2      , prepare_cop2      , test_cop2      , 0x00000000, 7
SingleTest TEXT_COP2MFC2  , prepare_cop2      , test_cop2mfc2  , 0x00000090, 13
SingleTest TEXT_COP2MFC2D1, prepare_cop2      , test_cop2mfc2D1, 0x00000090, 13

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
prepare_zero:
   li s5,0
jr $31
nop

.align 64
test_nop:  
   nop
jr $31
nop

; ---------------------------

.align 64
test_mtc2:  
   mtc2 s5,MAC0
jr $31
nop

; ---------------------------

prepare_mfc2:  
   li s5,0x12345678
   mtc2 s5,MAC1
jr $31
nop

.align 64
test_mfc2:  
   mfc2 s5,MAC1
jr $31
nop

; ---------------------------

prepare_mtc2mfc2:  
   li s4,0x01234567
   mtc2 s4,MAC2
   li s4,0xABCDEF12
jr $31
nop

.align 64
test_mtc2mfc2:  
   mtc2 s4,MAC2
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_mtc2mfc2D1:  
   mtc2 s4,MAC2
   nop
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_mtc2mfc2D2:  
   mtc2 s4,MAC2
   nop
   nop
   mfc2 s5,MAC2
jr $31
nop

; ---------------------------

prepare_lwc2:  
   la a2,DEADBEEF
   li s5,0
jr $31
nop

.align 64
test_lwc2:  
   lwc2 MAC0,0(a2)
jr $31
nop

; ---------------------------

.align 64
test_lwc2mfc2:  
   lwc2 MAC1,0(a2)
   mfc2 s5,MAC1
jr $31
nop

.align 64
test_lwc2mfc2d1:  
   lwc2 MAC1,0(a2)
   nop
   mfc2 s5,MAC1
jr $31
nop

.align 64
test_lwc2mfc2d2:  
   lwc2 MAC1,0(a2)
   nop
   nop
   mfc2 s5,MAC1
jr $31
nop

; ---------------------------

prepare_swc2:
   li s5,0xAFFE4711
   mtc2 s5,MAC2
   la a2,TESTTARGET
   li s5,0
   sw s5,0(a2)
jr $31
nop

.align 64
test_swc2:  
   la a2,TESTTARGET
   swc2 MAC2,0(a2)
jr $31
nop

.align 64
test_swc2lw:  
   la a2,TESTTARGET
   swc2 MAC2,0(a2)
   lw s5,0(a2)
jr $31
nop

; ---------------------------

prepare_lwmtcmfc:
   li s4,0x05060708
   li s5,0x0A0B0C0D
   mtc2 s5,MAC3
   la a2,TESTTARGET
   li s5,0x01020304
   sw s5,0(a2)
jr $31
nop

test_lwmtcmfc:
   lw s4,0(a2)
   mtc2 s4,MAC3
   nop
   nop
   mfc2 s5,MAC3
jr $31
nop

test_lwmtcmfcd1:
   lw s4,0(a2)
   nop
   mtc2 s4,MAC3
   nop
   nop
   mfc2 s5,MAC3
jr $31
nop

; ---------------------------

prepare_cop2:
   li s5,0x1000
   ctc2 s5,ZSF3   
   li s5,0x10
   mtc2 s5,SZ1
   li s5,0x20
   mtc2 s5,SZ2
   li s5,0x60
   mtc2 s5,SZ3
   li s5,0
   mtc2 s5,OTZ
jr $31
nop

.align 64
test_cop2:  
   cop2 AVSZ3
jr $31
nop

.align 64
test_cop2mfc2:  
   cop2 AVSZ3
   mfc2 s5,OTZ
jr $31
nop

.align 64
test_cop2mfc2D1:  
   cop2 AVSZ3
   nop
   mfc2 s5,OTZ
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
  
DEADBEEF:   .dw 0xDEADBEEF
TESTTARGET: .dw 0x0
  
TEXT_TEST:       .db "TEST",0
TEXT_OUTOF:      .db "OUT OF ",0
TEXT_TP:         .db "TESTS PASS",0
TEXT_VALUE:      .db "VALUE",0
TEXT_TIME:       .db "TIME",0
TEXT_PS1:        .db "PS1",0

TEXT_NOP:        .db "NOP",0
TEXT_MTC2:       .db "MTC2",0
TEXT_MFC2:       .db "MFC2",0
TEXT_MTC2MFC2:   .db "MTC2MFC2",0
TEXT_MTC2MFC2D1: .db "MTC2MFC2D1",0
TEXT_MTC2MFC2D2: .db "MTC2MFC2D2",0
TEXT_LWC2:       .db "LWC2",0
TEXT_LWC2MFC2:   .db "LWC2MFC2",0
TEXT_LWC2MFC2D2: .db "LWC2MFC2D2",0
TEXT_SWC2:       .db "SWC2",0
TEXT_SWC2LW:     .db "SWC2LW",0
TEXT_LWMTCMFC:   .db "LWMTCMFC",0
TEXT_LWMTCMFCD1: .db "LWMTCMFCD1",0
TEXT_COP2:       .db "COP2",0
TEXT_COP2MFC2:   .db "COP2MFC2",0
TEXT_COP2MFC2D1: .db "COP2MFC2D1",0

.close