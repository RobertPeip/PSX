; PSX 'Bare Metal' Test
.psx
.create "PipelineInstructionBIOS.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro SingleTest, testname, testfunction, cacheclear, ps1time

   .align 4096 ;make sure it fits in cache together with executing function
   nop
   .align 2048
   
   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T2_CNTT,0x8000 ; target
   
   li s3,10 ; runcount 10, to get lowest time to ignore sdram refresh
   li s2,0
   
   li s1, 999  ; initial time, overwritten when lower
   
   checkloop:
   
      ; clear cache
      ; first set up a function in ram at target address
      li a2, cacheclear
      
      ; now overwrite it with jr31 and nop
      li t0, 0x03E00008
      sw t0, 0(a2)
      li t0, 0x00000000
      sw t0, 4(a2)
      
      ; execute it -> will fill cache line
      jalr a2
      nop
      
      ; overwrite pointer with bios function
      li a2, testfunction
   
      la a1,0xBF800000
      li t0,0x0008     
      sh t0,T0_CNTM(a1)
      lh t0,T2_CNTM(a1)
      nop
      move t1,t0
   
      jalr a2
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
   PrintDezValue 220,s6,s1
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
SingleTest   TEXT_2_NOCACHE  ,     0xbfc03980  , 0x00103980  ,  74                                                                                                            
SingleTest   TEXT_2_CACHE    ,     0x9fc03980  , 0x00103980  ,  74   
                                                     
SingleTest   TEXT_3_NOCACHE  ,     0xbfc0397C  , 0x0010397C  ,  107                                                                                                            
SingleTest   TEXT_3_CACHE3   ,     0x9fc0397C  , 0x0010397C  ,  107                                                                                                          
SingleTest   TEXT_3_CACHE2   ,     0x9fc0397C  , 0x00103980  ,  75                                                                                                          


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

; 0xbfc03980
;jr $31
;nop

; 0xbfc0397C
;nop
;jr $31
;nop

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
               
TEXT_2_NOCACHE:                  .db "NOCACHE   RET NOP",0
TEXT_2_CACHE:                    .db "CACHE     RET NOP",0

TEXT_3_NOCACHE:                  .db "NOCACHE   NOP RET NOP",0
TEXT_3_CACHE3:                   .db "CACHE3    NOP RET NOP",0
TEXT_3_CACHE2:                   .db "CACHE2    NOP RET NOP",0

TEXT_ERROR:                      .db "ERROR",0

.close