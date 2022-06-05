; PSX 'Bare Metal' Test of random VRAm2CPU, red line when failed, white line when passed
.psx
.create "MemoryTransferRandom2CPU.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros

.org 0x80010000 ; Entry Point Of Code

la a0,IO_BASE ; A0 = I/O Port Base Address ($1F80XXXX)


.macro PrintValue,X,Y,WIDTH,HEIGHT,FONT,STRING,LENGTH ; Print HEX Chars To VRAM Using Width,Height Font At X,Y Position
  la a1,FONT   ; A1 = Font Address
  la a2,STRING+LENGTH ; A2 = Text Address
  li t0,LENGTH ; T0 = Number of Text Characters to Print
  li t1,X ; T1 = X Position
  li t2,Y ; T2 = Y Position

  DrawHEXChars:
    lbu t3,0(a2) ; T3 = Next 2 HEX Chars
    subiu a2,1 ; Decrement Text Offset

    srl t4,t3,4 ; T4 = 2nd Nibble
    andi t4,0xF
    subiu t5,t4,9
    bgtz t5,HEXLetters
    addiu t4,0x30 ; Delay Slot
    j HEXEnd
    nop ; Delay Slot

    HEXLetters:
    addiu t4,7
    HEXEnd:

    sll a3,t4,7 ; Add Shift to Correct Position in Font (*128: WIDTH*HEIGHT*BYTES_PER_PIXEL)
    addu a3,a1 ; A3 = Texture RAM Font Offset

    ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height

    ; Write GP0 Command Word (Command)
    li t4,0xA0<<24 ; T4 = DATA Word
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Destination Coord: X Counted In Halfwords)
    sll t4,t2,16 ; T4 = Y<<16
    addu t4,t1 ; T4 = DATA Word (Y<<16)+X
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Width+Height:  Width Counted In Halfwords)
    li t4,(HEIGHT<<16)+WIDTH ; T4 = DATA Word
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Data)
    li t4,(WIDTH*HEIGHT/2)-1 ; T4 = Data Copy Word Count
    CopyTextureA:
      lw t5,0(a3) ; T5 = DATA Word
      addiu a3,4  ; A3 += 4 (Delay Slot)
      sw t5,GP0(a0) ; Write GP0 Packet Word
      bnez t4,CopyTextureA ; IF (T4 != 0) Copy Texture A
      subiu t4,1 ; T4-- (Delay Slot)

    addiu t1,WIDTH ; Add Width To X Position

    andi t4,t3,0xF ; T4 = 1st Nibble
    subiu t5,t4,9
    bgtz t5,HEXLettersB
    addiu t4,0x30 ; Delay Slot
    j HEXEndB
    nop ; Delay Slot

    HEXLettersB:
    addiu t4,7
    HEXEndB:

    sll a3,t4,7 ; Add Shift to Correct Position in Font (*128: WIDTH*HEIGHT*BYTES_PER_PIXEL)
    addu a3,a1 ; A3 = Texture RAM Font Offset

    ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height

    ; Write GP0 Command Word (Command)
    li t4,0xA0<<24 ; T4 = DATA Word
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Destination Coord: X Counted In Halfwords)
    sll t4,t2,16 ; T4 = Y<<16
    addu t4,t1 ; T4 = DATA Word (Y<<16)+X
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Width+Height:  Width Counted In Halfwords)
    li t4,(HEIGHT<<16)+WIDTH ; T4 = DATA Word
    sw t4,GP0(a0) ; I/O Port Register Word = T4

    ; Write GP0  Packet Word (Data)
    li t4,(WIDTH*HEIGHT/2)-1 ; T4 = Data Copy Word Count
    CopyTextureB:
      lw t5,0(a3) ; T5 = DATA Word
      addiu a3,4  ; A3 += 4 (Delay Slot)
      sw t5,GP0(a0) ; Write GP0 Packet Word
      bnez t4,CopyTextureB ; IF (T4 != 0) Copy Texture B
      subiu t4,1 ; T4-- (Delay Slot)

    addiu t1,WIDTH ; Add Width To X Position
    bnez t0,DrawHEXChars ; Continue to Print Characters
    subiu t0,1 ; Subtract Number of Text Characters to Print (Delay Slot)
.endmacro


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

; fill vram with defined values
CopyRectCPU 0,0,1024,512 ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height

li t7, 262143

li t3, 0
li t4, 1

vram2cpuLoop:
   move t1,t4
   sll t1, 16
   addu t1, t3
   addiu t3, 2 
   addiu t4, 2
   andi t3, 0xFFFF   
   andi t4, 0xFFFF   
   
   sw t1,GP0(a0) ; Write GP0 Packet Word
   
   bnez t7,vram2cpuLoop ; IF (T7 != 0)
   subiu t7,1 ; T7-- (Delay Slot)
   



multu t3,t4   ;used as breakpoint


;read and check all vram cells with single access

; T3 = x
; T4 = y
; T5 = pos x
; T6 = pos y
; T7 = target value
; T8 = sizeX 
; T9 = sizeY 
; S1 = EndX 
; S2 = EndY

li s1, 1023
li s2, 39

li s3, 1020
xloop:
   li s4, 0
   yloop:
   
      li t0, 1024
      mult s4, t0
      mflo s7
      addu s7, s3
      andi s7, 0xFFFF
      
      li t0, 1024
      mult s4, t0
      mflo t1
      move t2, s3
      addiu t2, 1
      andi t2, 0x3FF
      addu t1, t2
      andi t1, 0xFFFF
      sll t1, 16
      or s7, t1
      
      move t5, s3
      move t6, s4
      
      li t8, 1
      li t9, 1
      
      CopyRectVRAMCPUV t5, t6, t8, t9  ; X,Y,WIDTH,HEIGHT ; GP0($C0) - Copy Rectangle (VRAM To CPU)
      WAITVRAM2CPUREADY

      LW s0,GP0(a0)
      nop
      
      beq s0, s7, noerror
      
         la a2,VALUEWORDG
         sw s7, 0(a2)
         PrintValue  40,40, 8,8, FontBlack,VALUEWORDG,3 ; X,Y,WIDTH,HEIGHT,FONT,STRING,LENGTH
         
         la a2,VALUEWORDG
         sw s0, 0(a2)
         PrintValue  40,80, 8,8, FontBlack,VALUEWORDG,3 ; X,Y,WIDTH,HEIGHT,FONT,STRING,LENGTH
      
         bne s0, s7, error
         nop
         
      noerror:

      addi s4, 1
      ble s4, s2, yloop
      nop
      
   addi s3, 1
   ble s3, s1, xloop
   nop

;read and check all vram cells with random access size

; T1 = check x
; T2 = check y
; T3 = x
; T4 = y
; T5 = pos x
; T6 = pos y
; T7 = target temp
; T8 = sizeX 
; T9 = sizeY 
; S1 = EndX 
; S2 = EndY
; S3 = target value
; S4 = wordcounter
; S5 = wordcheck

li s5, 2

li s1, 32
li s2, 32

li t3, 1
xloop2:
   li t4, 1
   yloop2:
      
      li t5, 0
      li t6, 0
      
      move t8, t3
      move t9, t4
   
      CopyRectVRAMCPUV t5, t6, t8, t9  ; X,Y,WIDTH,HEIGHT ; GP0($C0) - Copy Rectangle (VRAM To CPU)
      WAITVRAM2CPUREADY

      li s4, 0
      li s3, 0
   
      li t2, 0
      ycheck:
         li t1, 0
         xcheck:
         
            li t0, 1024
            mult t2, t0
            mflo t7
            addu t7, t1
            andi t7, 0xFFFF
            
            sll  t7, 16
            srl  s3, 16
            addu s3, t7
            
            addiu s4, 1
            
            bne s4, s5, nocheck
            nop
            
               LW t0,GP0(a0)
               nop
               
               bne t0, s3, error
               nop
               
               li s4, 0 ; reset wordcounter
            
            nocheck:
            
            addi t1, 1
            blt t1, t3, xcheck
            nop
            
         addi t2, 1
         blt t2, t4, ycheck
         nop
  
      ; check remaining word if any
      beqz s4, noendcheck
      nop
      
         srl  s3, 16
         
         LW t0,GP0(a0)
         nop
         andi t0, 0xFFFF
         
         bne t0, s3, error
         nop
      
      noendcheck:
  
      addi t4, 1
      ble t4, s2, yloop2
      nop
      
   addi t3, 1
   ble t3, s1, xloop2
   nop






FillRectVRAM 0xFFFFFF, 0,60, 1023,10 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height
Loop:
  b Loop
  nop ; Delay Slot

error:
WRGP1 GPURESETCB,0 ; reset command buffer
FillRectVRAM 0x0000FF, 0,60, 1023,10 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height
errorloop:
  b errorloop
  nop ; Delay Slot

FontBlack:
  .incbin "FontBlack8x8.bin"
  
VALUEWORDG:
  .dw 0xFFFFFFFF

.close