; PSX 'Bare Metal' Test
.psx
.create "GTETiming.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"
.include "../../LIB/PSX_GTE.INC" ; Include PSX GTE Definitions & Macros

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest,text,testfunction,ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048

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
   
   sub s2,s1
   li t0,100
   div s2,t0
   mflo s1
   PrintDezValue 120,s6,s1
   
   li s2, ps1time
   PrintDezValue 150,s6,s2

   li s2,ps1time

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
   
   PrintText 20,s6,text
   addiu s6,8

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
PrintText 110,s6,TEXT_TIME
PrintText 150,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest TEXT_NOPMFC2, test_nop     , 8
SingleTest TEXT_RTPS   , test_RTPS    , 23
SingleTest TEXT_RTPT   , test_RTPT    , 31
SingleTest TEXT_NCLIP  , test_NCLIP   , 16
SingleTest TEXT_AVSZ3  , test_AVSZ3   , 13
SingleTest TEXT_AVSZ4  , test_AVSZ4   , 14
SingleTest TEXT_MVMVA  , test_MVMVA   , 16
SingleTest TEXT_SQR    , test_SQR     , 13
SingleTest TEXT_OP     , test_OP      , 14
SingleTest TEXT_NCS    , test_NCS     , 22
SingleTest TEXT_NCT    , test_NCT     , 38
SingleTest TEXT_NCCS   , test_NCCS    , 25
SingleTest TEXT_NCCT   , test_NCCT    , 47
SingleTest TEXT_NCDS   , test_NCDS    , 27
SingleTest TEXT_NCDT   , test_NCDT    , 52
SingleTest TEXT_CC     , test_CC      , 19
SingleTest TEXT_CDP    , test_CDP     , 21
SingleTest TEXT_DCPL   , test_DCPL    , 16
SingleTest TEXT_DPCS   , test_DPCS    , 16
SingleTest TEXT_DPCT   , test_DPCT    , 25
SingleTest TEXT_INTPL  , test_INTPL   , 16
SingleTest TEXT_GPF    , test_GPF     , 13
SingleTest TEXT_GPL    , test_GPL     , 13

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
test_nop:  
   nop
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_RTPS:  
   cop2 RTPS
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_RTPT:  
   cop2 RTPT
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCLIP:  
   cop2 NCLIP
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_AVSZ3:  
   cop2 AVSZ3
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_AVSZ4:  
   cop2 AVSZ4
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_MVMVA:  
   cop2 MVMVA
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_SQR:  
   cop2 SQR
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_OP:  
   cop2 OP
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCS:  
   cop2 NCS
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCT:  
   cop2 NCT
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCCS:  
   cop2 NCCS
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCCT:  
   cop2 NCCT
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCDS:  
   cop2 NCDS
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_NCDT:  
   cop2 NCDT
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_CC:  
   cop2 CC
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_CDP:  
   cop2 CDP
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_DCPL:  
   cop2 DCPL
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_DPCS:  
   cop2 DPCS
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_DPCT:  
   cop2 DPCT
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_INTPL:  
   cop2 INTPL
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_GPF:  
   cop2 GPF
   mfc2 s5,MAC2
jr $31
nop

.align 64
test_GPL:  
   cop2 GPL
   mfc2 s5,MAC2
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
  
TEXT_TEST:       .db "TEST",0
TEXT_OUTOF:      .db "OUT OF ",0
TEXT_TP:         .db "TESTS PASS",0
TEXT_TIME:       .db "TIME",0
TEXT_PS1:        .db "PS1",0

TEXT_NOPMFC2:    .db "NOPMFC2",0
TEXT_RTPS:       .db "RTPS",0
TEXT_RTPT:       .db "RTPT",0
TEXT_NCLIP:      .db "NCLIP",0
TEXT_AVSZ3:      .db "AVSZ3",0
TEXT_AVSZ4:      .db "AVSZ4",0
TEXT_MVMVA:      .db "MVMVA",0
TEXT_SQR:        .db "SQR",0
TEXT_OP:         .db "OP",0
TEXT_NCS:        .db "NCS",0
TEXT_NCT:        .db "NCT",0
TEXT_NCCS:       .db "NCCS",0
TEXT_NCCT:       .db "NCCT",0
TEXT_NCDS:       .db "NCDS",0
TEXT_NCDT:       .db "NCDT",0
TEXT_CC:         .db "CC",0
TEXT_CDP:        .db "CDP",0
TEXT_DCPL:       .db "DCPL",0
TEXT_DPCS:       .db "DPCS",0
TEXT_DPCT:       .db "DPCT",0
TEXT_INTPL:      .db "INTPL",0
TEXT_GPF:        .db "GPF",0
TEXT_GPL:        .db "GPL",0

.close