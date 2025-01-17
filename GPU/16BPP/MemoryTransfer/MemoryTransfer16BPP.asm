; PSX 'Bare Metal' GPU 16BPP Memory Transfer Demo by krom (Peter Lemon):
.psx
.create "MemoryTransfer16BPP.bin", 0x80010000

.include "../../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros

.org 0x80010000 ; Entry Point Of Code

la a0,IO_BASE ; A0 = I/O Port Base Address ($1F80XXXX)

; Setup Screen Mode
WRGP1 GPURESET,0  ; Write GP1 Command Word (Reset GPU)
WRGP1 GPUDISPEN,0 ; Write GP1 Command Word (Enable Display)
WRGP1 GPUDISPM,HRES320+VRES240+BPP15+VNTSC ; Write GP1 Command Word (Set Display Mode: 320x240, 15BPP, NTSC)
WRGP1 GPUDISPH,0xC60260 ; Write GP1 Command Word (Horizontal Display Range 608..3168)
WRGP1 GPUDISPV,0x042018 ; Write GP1 Command Word (Vertical Display Range 24..264)

; Setup Drawing Area
WRGP0 GPUDRAWM,0x000400   ; Write GP0 Command Word (Drawing To Display Area Allowed Bit 10)
WRGP0 GPUDRAWATL,0x000000 ; Write GP0 Command Word (Set Drawing Area Top Left X1=0, Y1=0)
WRGP0 GPUDRAWABR,0x03BD3F ; Write GP0 Command Word (Set Drawing Area Bottom Right X2=319, Y2=239)
WRGP0 GPUDRAWOFS,0x000000 ; Write GP0 Command Word (Set Drawing Offset X=0, Y=0)

; Memory Transfers
FillRectVRAM 0x0000FF, 0,0, 160,80   ; Fill Rectangle In VRAM: Color, X,Y, Width,Height
FillRectVRAM 0x00FF00, 0,80, 160,80  ; Fill Rectangle In VRAM: Color, X,Y, Width,Height
FillRectVRAM 0xFF0000, 0,160, 160,80 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height

CopyRectVRAM 0,0, 160,80, 160,80   ; Copy Rectangle (VRAM To VRAM): X1,Y1, X2,Y2, Width,Height
CopyRectVRAM 0,80, 160,160, 160,80 ; Copy Rectangle (VRAM To VRAM): X1,Y1, X2,Y2, Width,Height
CopyRectVRAM 0,160, 160,0, 160,80  ; Copy Rectangle (VRAM To VRAM): X1,Y1, X2,Y2, Width,Height

CopyRectCPU 0,0, 8,8 ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height
li t0,31 ; T0 = Data Copy Word Count
la a1,Texture8x8 ; A1 = Texture RAM Offset
CopyTexture8x8:
  lw t1,0(a1) ; T1 = DATA Word
  addiu a1,4  ; A1 += 4 (Delay Slot)
  sw t1,GP0(a0) ; Write GP0 Packet Word
  bnez t0,CopyTexture8x8 ; IF (T0 != 0) Copy Texture8x8
  subiu t0,1 ; T0-- (Delay Slot)

CopyRectCPU 160,0, 16,16 ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height
li t0,127 ; T0 = Data Copy Word Count
la a1,Texture16x16 ; A1 = Texture RAM Offset
CopyTexture16x16:
  lw t1,0(a1) ; T1 = DATA Word
  addiu a1,4  ; A1 += 4 (Delay Slot)
  sw t1,GP0(a0) ; Write GP0 Packet Word
  bnez t0,CopyTexture16x16 ; IF (T0 != 0) Copy Texture16x16
  subiu t0,1 ; T0-- (Delay Slot)

CopyRectCPU 0,80, 32,32 ; Copy Rectangle (CPU To VRAM): X,Y, Width,Height
li t0,511 ; T0 = Data Copy Word Count
la a1,Texture32x32 ; A1 = Texture RAM Offset
CopyTexture32x32:
  lw t1,0(a1) ; T1 = DATA Word
  addiu a1,4  ; A1 += 4 (Delay Slot)
  sw t1,GP0(a0) ; Write GP0 Packet Word
  bnez t0,CopyTexture32x32 ; IF (T0 != 0) Copy Texture32x32
  subiu t0,1 ; T0-- (Delay Slot)

Loop:
  b Loop
  nop ; Delay Slot

Texture8x8:
  dh 0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000 // 8x8x16B = 128 Bytes
  dh 0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

Texture16x16:
  dh 0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000 // 16x16x16B = 512 Bytes
  dh 0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

Texture32x32:
  dh 0x001F,0x001F,0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000 // 32x32x16B = 2048 Bytes
  dh 0x001F,0x001F,0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x001F,0x001F,0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x001F,0x001F,0x001F,0x001F,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x7FFF,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
  dh 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000

.close