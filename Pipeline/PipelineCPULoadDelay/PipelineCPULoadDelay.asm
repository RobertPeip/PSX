; PSX 'Bare Metal' Test
.psx
.create "PipelineCPULoadDelay.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction,ps1value

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   ; execute function once for value check
   la a1,0x00100000
   li t0,0xFFFFFFFF
   li s5,0
   jal testfunction
   nop
   
   ; compareresult
   PrintHexValue 180,s6,s5
   li s2, ps1value
   PrintHexValue 250,s6,s2

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
; test preparation
;-----------------------------------------------------------------------------

la a1,0x00100000

li t0,0xA1B1C1D1
sw t0,0(a1)

li t0,0xA2B2C2D2
sw t0,4(a1)

;-----------------------------------------------------------------------------
; test execution
;-----------------------------------------------------------------------------

li s6, 10 ; y pos

; header
PrintText 20,s6,TEXT_TEST
PrintText 200,s6,TEXT_VALUE
PrintText 270,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest TEXT_NOP                 , test_NOP                 , 0x00000000
SingleTest TEXT_LI                  , test_LI                  , 0xABCDEF01
SingleTest TEXT_LW_NOP_MOVE         , test_LW_NOP_MOVE         , 0xA1B1C1D1
SingleTest TEXT_LW_MOVE             , test_LW_MOVE             , 0xFFFFFFFF
SingleTest TEXT_LW_LW_NOP_MOVE      , test_LW_LW_NOP_MOVE      , 0xA2B2C2D2
SingleTest TEXT_LW_LW_MOVE          , test_LW_LW_MOVE          , 0xFFFFFFFF
SingleTest TEXT_LWR_NOP_MOVE        , test_LWR_NOP_MOVE        , 0xA1B1C1D1
SingleTest TEXT_LWR_MOVE            , test_LWR_MOVE            , 0xFFFFFFFF
SingleTest TEXT_LWR_LWR_NOP_MOVE    , test_LWR_LWR_NOP_MOVE    , 0xA2B2C2D2
SingleTest TEXT_LWR_LWR_MOVE        , test_LWR_LWR_MOVE        , 0xFFFFFFFF
SingleTest TEXT_LWR2_NOP_MOVE       , test_LWR2_NOP_MOVE       , 0xFFFFA1B1
SingleTest TEXT_LWR2_MOVE           , test_LWR2_MOVE           , 0xFFFFFFFF
SingleTest TEXT_LWR_LWR2_NOP_MOVE   , test_LWR_LWR2_NOP_MOVE   , 0xA1B1A1B1
SingleTest TEXT_LWR_LWR2_MOVE       , test_LWR_LWR2_MOVE       , 0xFFFFFFFF
SingleTest TEXT_LWL3_NOP_MOVE       , test_LWL3_NOP_MOVE       , 0xA1B1C1D1
SingleTest TEXT_LWL3_MOVE           , test_LWL3_MOVE           , 0xFFFFFFFF
SingleTest TEXT_LWL3_LWR2_NOP_MOVE  , test_LWL3_LWR2_NOP_MOVE  , 0xFFFFA1B1
SingleTest TEXT_LWL3_LWR2_MOVE      , test_LWL3_LWR2_MOVE      , 0xFFFFFFFF
SingleTest TEXT_LWL4_LWR1_NOP_MOVE  , test_LWL4_LWR1_NOP_MOVE  , 0xA2A1B1C1
SingleTest TEXT_LWL4_LWR1_MOVE      , test_LWL4_LWR1_MOVE      , 0xFFFFFFFF

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
nop

.align 64
test_NOP:  
   nop
jr $31
nop

; ---------------------------

.align 64
test_LI:  
   li s5,0xABCDEF01
jr $31
nop

; ---------------------------

.align 64
test_LW_NOP_MOVE:  
   lw t0,0(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LW_MOVE:  
   lw t0,0(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LW_LW_NOP_MOVE:  
   lw t0,0(a1)
   lw t0,4(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LW_LW_MOVE:  
   lw t0,0(a1)
   lw t0,4(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_NOP_MOVE:  
   lwr t0,0(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_MOVE:  
   lwr t0,0(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_LWR_NOP_MOVE:  
   lwr t0,0(a1)
   lwr t0,4(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_LWR_MOVE:  
   lwr t0,0(a1)
   lwr t0,4(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR2_NOP_MOVE:  
   lwr t0,2(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR2_MOVE:  
   lwr t0,2(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_LWR2_NOP_MOVE:  
   lwr t0,0(a1)
   lwr t0,2(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWR_LWR2_MOVE:  
   lwr t0,0(a1)
   lwr t0,2(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL3_NOP_MOVE:  
   lwl t0,3(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL3_MOVE:  
   lwr t0,3(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL3_LWR2_NOP_MOVE:  
   lwr t0,3(a1)
   lwr t0,2(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL3_LWR2_MOVE:  
   lwr t0,3(a1)
   lwr t0,2(a1)
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL4_LWR1_NOP_MOVE:  
   lwr t0,4(a1)
   lwr t0,1(a1)
   nop
   MOVE s5,t0
jr $31
nop

; ---------------------------

.align 64
test_LWL4_LWR1_MOVE:  
   lwr t0,4(a1)
   lwr t0,1(a1)
   MOVE s5,t0
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
TEXT_PS1:        .db "PS1",0

TEXT_NOP                : .db "NOP",0
TEXT_LI                 : .db "LI",0
TEXT_LW_NOP_MOVE        : .db "LW_NOP_MOVE",0
TEXT_LW_MOVE            : .db "LW_MOVE",0
TEXT_LW_LW_NOP_MOVE     : .db "LW_LW_NOP_MOVE",0
TEXT_LW_LW_MOVE         : .db "LW_LW_MOVE",0
TEXT_LWR_NOP_MOVE       : .db "LWR_NOP_MOVE",0
TEXT_LWR_MOVE           : .db "LWR_MOVE",0
TEXT_LWR_LWR_NOP_MOVE   : .db "LWR_LWR_NOP_MOVE",0
TEXT_LWR_LWR_MOVE       : .db "LWR_LWR_MOVE",0
TEXT_LWR2_NOP_MOVE      : .db "LWR2_NOP_MOVE",0
TEXT_LWR2_MOVE          : .db "LWR2_MOVE",0
TEXT_LWR_LWR2_NOP_MOVE  : .db "LWR_LWR2_NOP_MOVE",0
TEXT_LWR_LWR2_MOVE      : .db "LWR_LWR2_MOVE",0
TEXT_LWL3_NOP_MOVE      : .db "LWL3_NOP_MOVE",0
TEXT_LWL3_MOVE          : .db "LWL3_MOVE",0
TEXT_LWL3_LWR2_NOP_MOVE : .db "LWL3_LWR2_NOP_MOVE",0
TEXT_LWL3_LWR2_MOVE     : .db "LWL3_LWR2_MOVE",0
TEXT_LWL4_LWR1_NOP_MOVE : .db "LWL4_LWR1_NOP_MOVE",0
TEXT_LWL4_LWR1_MOVE     : .db "LWL4_LWR1_MOVE",0


.close