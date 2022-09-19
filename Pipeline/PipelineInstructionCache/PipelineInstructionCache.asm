; PSX 'Bare Metal' Test
.psx
.create "PipelineInstructionCache.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testname, setupfunction, testfunction, ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T2_CNTT,0x8000 ; target
   
   li s3,10 ; runcount 10, to get lowest time to ignore sdram refresh
   li s2,0
   
   li s1, 999  ; initial time, overwritten when lower
   
   checkloop:
   
      jal setupfunction
      nop
   
      la a1,0xBF800000
      li t0,0x0008     
      sh t0,T0_CNTM(a1)
      lh t0,T2_CNTM(a1)
      nop
      move t1,t0
   
      jal testfunction
      nop
      
      lhu t2,T0_CNT(a1)
      nop
      move t1, t2
      
      sltu t0, t1, s1
      beqz t0,notlower
      nop
      move s1,t1
      notlower:
      
      bne s3,1,checkloop
      subiu s3,1
   
   li s2, ps1time

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
   
   PrintText 20,s6,testname
   PrintDezValue 200,s6,s1
   PrintDezValue 260,s6,s2
   
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
PrintText 200,s6,TEXT_CYCLES
PrintText 260,s6,TEXT_PS1
addiu s6,10

; instruction tests
SingleTest   TEXT_8_CACHED_0_NOT  , setup_invalidate_8     ,     test_0_7   ,  17                                                       
SingleTest   TEXT_7_CACHED_1_NOT  , setup_invalidate_7     ,     test_0_7   ,  22
SingleTest   TEXT_6_CACHED_2_NOT  , setup_invalidate_6     ,     test_0_7   ,  22
SingleTest   TEXT_5_CACHED_3_NOT  , setup_invalidate_5     ,     test_0_7   ,  22
SingleTest   TEXT_4_CACHED_4_NOT  , setup_invalidate_4     ,     test_0_7   ,  22
SingleTest   TEXT_3_CACHED_5_NOT  , setup_invalidate_3     ,     test_0_7   ,  27
SingleTest   TEXT_2_CACHED_6_NOT  , setup_invalidate_2     ,     test_0_7   ,  27
SingleTest   TEXT_1_CACHED_7_NOT  , setup_invalidate_1     ,     test_0_7   ,  27
SingleTest   TEXT_0_CACHED_8_NOT  , setup_invalidate_all   ,     test_0_7   ,  27

SingleTest   TEXT_0_NOT_7_CACHED  , setup_invalidate_8     ,     test_1_7   ,  16
SingleTest   TEXT_3_NOT_4_CACHED  , setup_invalidate_0     ,     test_1_7   ,  21
SingleTest   TEXT_7_NOT_0_CACHED  , setup_invalidate_all   ,     test_1_7   ,  26

SingleTest   TEXT_0_NOT_6_CACHED  , setup_invalidate_8     ,     test_2_7   ,  15
SingleTest   TEXT_2_NOT_4_CACHED  , setup_invalidate_0     ,     test_2_7   ,  20
SingleTest   TEXT_6_NOT_0_CACHED  , setup_invalidate_all   ,     test_1_7   ,  26

SingleTest   TEXT_0_NOT_7_CACHED  , setup_invalidate_8     ,     test_3_7   ,  14
SingleTest   TEXT_1_NOT_4_CACHED  , setup_invalidate_0     ,     test_3_7   ,  19
SingleTest   TEXT_5_NOT_0_CACHED  , setup_invalidate_all   ,     test_1_7   ,  26


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

.align 4096
setup_invalidate_all:  
   nop
   nop
   nop
   jr $31
   nop
   
.align 4096
setup_invalidate_0:
   nop
   nop
   jr $31
   nop

.align 4096
nop
setup_invalidate_1:  
   nop
   nop
   jr $31
   nop
   
.align 4096
nop
nop
setup_invalidate_2:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
setup_invalidate_3:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
nop
setup_invalidate_4:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
nop
nop
setup_invalidate_5:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
nop
nop
nop
setup_invalidate_6:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
nop
nop
nop
nop
setup_invalidate_7:  
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
nop
nop
nop
nop
nop
setup_invalidate_8:  
   nop
   nop
   jr $31
   nop


.align 4096
test_0_7:  
   nop
   nop
   nop
   nop
   nop
   nop
   jr $31
   nop

.align 4096
nop
test_1_7:  
   nop
   nop
   nop
   nop
   nop
   jr $31
   nop
   
.align 4096
nop
nop
test_2_7:  
   nop
   nop
   nop
   nop
   jr $31
   nop

.align 4096
nop
nop
nop
test_3_7:  
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
  
TESTCOUNT: .dw 0x0
TESTSPASS: .dw 0x0
  
TEXT_TEST:                       .db "TEST",0
TEXT_OUTOF:                      .db "OUT OF ",0
TEXT_TP:                         .db "TESTS PASS",0
TEXT_CYCLES:                     .db "CYCLES",0
TEXT_PS1:                        .db "PS1",0
               
TEXT_8_CACHED_0_NOT:             .db "8 CACHED 0 NOT",0
TEXT_7_CACHED_1_NOT:             .db "7 CACHED 1 NOT",0
TEXT_6_CACHED_2_NOT:             .db "6 CACHED 2 NOT",0
TEXT_5_CACHED_3_NOT:             .db "5 CACHED 3 NOT",0
TEXT_4_CACHED_4_NOT:             .db "4 CACHED 4 NOT",0
TEXT_3_CACHED_5_NOT:             .db "3 CACHED 5 NOT",0
TEXT_2_CACHED_6_NOT:             .db "2 CACHED 6 NOT",0
TEXT_1_CACHED_7_NOT:             .db "1 CACHED 7 NOT",0
TEXT_0_CACHED_8_NOT:             .db "0 CACHED 8 NOT",0

TEXT_0_NOT_7_CACHED:             .db "0 NOT 7 CACHED",0
TEXT_3_NOT_4_CACHED:             .db "3 NOT 4 CACHED",0
TEXT_7_NOT_0_CACHED:             .db "7 NOT 0 CACHED",0

TEXT_0_NOT_6_CACHED:             .db "0 NOT 6 CACHED",0
TEXT_2_NOT_4_CACHED:             .db "2 NOT 4 CACHED",0
TEXT_6_NOT_0_CACHED:             .db "6 NOT 0 CACHED",0

TEXT_0_NOT_5_CACHED:             .db "0 NOT 5 CACHED",0
TEXT_1_NOT_4_CACHED:             .db "1 NOT 4 CACHED",0
TEXT_5_NOT_0_CACHED:             .db "5 NOT 0 CACHED",0

TEXT_ERROR:                      .db "ERROR",0

.close