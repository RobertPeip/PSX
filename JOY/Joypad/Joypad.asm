; PSX 'Bare Metal' Test
.psx
.create "Joypad.bin", 0x80010000

.include "../../LIB/PSX.INC" ; Include PSX Definitions
.include "../../LIB/PSX_GPU.INC" ; Include PSX GPU Definitions & Macros
.include "../../LIB/Print.INC"

.org 0x80010000 ; Entry Point Of Code

;-----------------------------------------------------------------------------
; test macros
;-----------------------------------------------------------------------------

.macro pushValue, reg

   addiu sp,4
   sw reg, 0(sp)

.endmacro

.macro popValue, reg

   lw reg, 0(sp)
   subiu sp,4

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

;-----------------------------------------------------------------------------
; test prepare
;-----------------------------------------------------------------------------

li t0,0x0001
sw t0,I_MASK(a0)

;-----------------------------------------------------------------------------
; test execution
;-----------------------------------------------------------------------------

.align 4096 ; make sure it fits in cache together with executing loop

li sp, 0x00100000

.align 256
startloop:
   
   ; execute first -> fill cache
   jal waitvsync
   nop
   jal read_pad
   nop
   
   ; execute second time, everything is cached now
   jal waitvsync
   nop
   jal read_pad
   nop
   
   ; print  results
   jal waitvsync
   nop
   
   FillRectVRAM 0x000000,0,0,320,240 ; Fill Rectangle In VRAM: Color, X,Y, Width,Height
   
   li s6, 20
   PrintText 20,s6,TEXT_TITLE
   
   jal print_type
   nop

   jal print_minmax
   nop
   
   jal print_receive
   nop
   
   jal clear_minmax
   nop

   b startloop
   nop

;-----------------------------------------------------------------------------
; tests
;-----------------------------------------------------------------------------

.align 256
waitvsync:  

   li t1,0x0001
   lw t0,I_STAT(a0)
   nop
   and t0,t1
   bne t0,t1,waitvsync 
   nop
   li t1,0
   sw t1,I_STAT(a0)
   
jr $31
nop


.align 256
read_pad:  
   pushValue $31
   
   ; set bytecount back to zero
   la a1,DATABYTES
   li t0,0
   sb t0,0(a1)

   ; reset
   li t0,0x0040
   sh t0,JOY_CTRL(a0)
   ; clear
   li t0,0x0000
   sh t0,JOY_CTRL(a0)
   ; baudrate reload factor 1, 8 bit char length 
   li t0,0x000D
   sh t0,JOY_MODE(a0)
   ; baudrate
   li t0,0x0088
   sh t0,JOY_BAUD(a0)
   ; ack irq enable + TX enable + /JOYn Output -> first slot
   li t0,0x1003
   sh t0,JOY_CTRL(a0)
   ; clear old data?
   lh t0,JOY_DATA(a0)
   
   li s3,10000
   waitEnd:
      bnez s3,waitEnd
      subiu s3,1
   
   ; first byte: controller access
   li t0,0x0001
   sh t0,JOY_DATA(a0)
   jal readNextByte
   nop
   beqz s2,noByteAck
   nop
   
   ; second byte: read command
   li t0,0x0042
   sh t0,JOY_DATA(a0)
   jal readNextByte
   nop
   beqz s2,noByteAck
   nop
   
   readByteToNoAck:
      ; data bytes : read until no ack
      li t0,0x0000
      sh t0,JOY_DATA(a0)
      jal readNextByte
      nop
      bnez s2,readByteToNoAck
      nop 
   
   noByteAck:
   
   ; clear
   li t0,0x0000
   sh t0,JOY_CTRL(a0)
   
   popvalue $31
jr $31
nop

.align 256
readNextByte:

   WRIOH T0_CNTT,0x8000 ; target
   WRIOH T0_CNTM,0x0008 ; reset
   RDIOH T0_CNT,s1
   
   ; wait until tx ready and RX Fifo not empty
   li t1,0x0007
   waitByte:
      lh t0, JOY_STAT(a0)
      nop
      and t0,t1
      bne t0,t1,waitByte 
      nop
      
   RDIOH T0_CNT,s4

   ; wait ack
   li s2,0
   li t1,0x0080
   li s3,1000
   waitAck:
      lh t0, JOY_STAT(a0)
      nop
      and t0,t1
      bne t0,t1,noAck
      nop
      li s2,1
      li s3,0
      
      noAck:
      bnez s3,waitAck
      subiu s3,1
      
   RDIOH T0_CNT,s5
   
   ; wait acklow
   li t1,0x0080
   waitAckLo:
      lh t0, JOY_STAT(a0)
      nop
      and t0,t1
      beq t0,t1,waitAckLo
      nop
      
   RDIOH T0_CNT,s6
   
   ; load old byte count
   la a1,DATABYTES
   lb t0,0(a1)
   nop

   ; read data and store in array
   lh t1,JOY_DATA(a0)
   la a2,DATARECEIVE
   addu a2,t0
   sb t1,0(a2)
   
   ; store read time in array
   la a2,TIMERECEIVE
   addu a2,t0
   addu a2,t0
   sh s4,0(a2)
   
   ; store read time in array
   la a2,TIMEACKHI
   addu a2,t0
   addu a2,t0
   sh s5,0(a2)
   
   ; store read time in array
   la a2,TIMEACKLO
   addu a2,t0
   addu a2,t0
   sh s6,0(a2)
   
   ; add 1 to byte count
   addiu t0,1
   sb t0,0(a1)
   
   ; adjust min/max
   la a1,TIMEDATAMIN
   lh t1,0(a1)
   nop
   sltu t0, s4, t1
   beqz t0,noadjust_datamin
   nop
   sh s4,0(a1)
   noadjust_datamin:
   
   la a1,TIMEDATAMAX
   lh t1,0(a1)
   nop
   sltu t0, t1, s4
   beqz t0,noadjust_datamax
   nop
   sh s4,0(a1)
   noadjust_datamax:
   
   ;skip if no ack
   beqz s2,noadjust_acklomax
   
   la a1,TIMEACKHIMIN
   lh t1,0(a1)
   nop
   sltu t0, s5, t1
   beqz t0,noadjust_ackhimin
   nop
   sh s5,0(a1)
   noadjust_ackhimin:
   
   la a1,TIMEACKHIMAX
   lh t1,0(a1)
   nop
   sltu t0, t1, s5
   beqz t0,noadjust_ackhimax
   nop
   sh s5,0(a1)
   noadjust_ackhimax:
   
   la a1,TIMEACKLOMIN
   lh t1,0(a1)
   nop
   sltu t0, s6, t1
   beqz t0,noadjust_acklomin
   nop
   sh s6,0(a1)
   noadjust_acklomin:
   
   la a1,TIMEACKLOMAX
   lh t1,0(a1)
   nop
   sltu t0, t1, s6
   beqz t0,noadjust_acklomax
   nop
   sh s6,0(a1)
   noadjust_acklomax:

jr $31
nop



; JOY_DATA
; JOY_STAT
; JOY_MODE
; JOY_CTRL
; JOY_BAUD

.align 256
print_receive:

   li s6, 110
   PrintText 20,s6,TEXT_HEADER
   
   la a1,DATABYTES
   lb s1,0(a1)
   li s6,120
   li s3,0
   
   printNextByte:
      PrintDezValue 30,s6,s3
      
      la a1,DATARECEIVE
      addu a1,s3
      lb s2,0(a1)
      nop
      PrintHexValue8 70,s6,s2
      
      la a1,TIMERECEIVE
      addu a1,s3
      addu a1,s3
      lh s2,0(a1)
      nop
      PrintDezValue 112,s6,s2
      
      la a1,TIMEACKHI
      addu a1,s3
      addu a1,s3
      lh s2,0(a1)
      nop
      PrintDezValue 180,s6,s2
      
      la a1,TIMEACKLO
      addu a1,s3
      addu a1,s3
      lh s2,0(a1)
      nop
      PrintDezValue 250,s6,s2
      
      addiu s6,10
      subiu s1,1
      bnez s1,printNextByte
      addiu s3,1
   
jr $31
nop

.align 256
print_minmax:

   li s6,60 
   PrintText 20,s6,TEXT_MINMAXHEADER
   
   li s6,70
   PrintText 20,s6,TEXT_TIMEDATA
   la a1,TIMEDATAMIN
   lh s2,0(a1)
   nop
   PrintDezValue 100,s6,s2
   la a1,TIMEDATAMAX
   lh s2,0(a1)
   nop
   PrintDezValue 160,s6,s2
   
   li s6,80
   PrintText 20,s6,TEXT_TIMEACKHI
   la a1,TIMEACKHIMIN
   lh s2,0(a1)
   nop
   PrintDezValue 100,s6,s2
   la a1,TIMEACKHIMAX
   lh s2,0(a1)
   nop
   PrintDezValue 160,s6,s2
   
   li s6,90
   PrintText 20,s6,TEXT_TIMEACKLO
   la a1,TIMEACKLOMIN
   lh s2,0(a1)
   nop
   PrintDezValue 100,s6,s2
   la a1,TIMEACKLOMAX
   lh s2,0(a1)
   nop
   PrintDezValue 160,s6,s2

jr $31
nop

.align 256
print_type:

   li s6,40 
   PrintText 20,s6,TEXT_TYPE

   la a1,DATABYTES
   lb s1,0(a1)
   nop
   
   ; check if no pad
   li t0,1
   beq s1,t0,type_none
   
   ; check for type
   la a1,DATARECEIVE
   addiu a1,1
   lb s2,0(a1)
   nop
   
   PrintHexValue8 70,s6,s2
   
   li t0,0x41
   beq s2,t0,type_digital
   nop
   
   li t0,0x12
   beq s2,t0,type_mouse
   nop
   
   li t0,0x23
   beq s2,t0,type_negcon
   nop
   
   li t0,0x31
   beq s2,t0,type_konami_lightgun
   nop
   
   li t0,0x53
   beq s2,t0,type_analog_stick
   nop
   
   li t0,0x63
   beq s2,t0,type_namco_lightgun
   nop
   
   li t0,0x73
   beq s2,t0,type_analog_pad
   nop
   
   li t0,0x80
   beq s2,t0,type_multitap
   nop
   
   li t0,0xE3
   beq s2,t0,type_jogcon
   nop
   
   li t0,0xF3
   beq s2,t0,type_ds_configmode
   nop
   
   ; nothing fits -> unknown
   li s6,40 
   PrintText 110,s6,TEXT_UNKNOWN
   b type_end
   nop
   
   type_none:
   PrintText 110,s6,TEXT_NONE
   b type_end
   nop
   
   type_digital:
   PrintText 110,s6,TEXT_DIGITAL
   b type_end
   nop
   
   type_mouse:
   PrintText 110,s6,TEXT_MOUSE
   b type_end
   nop   
   
   type_negcon:
   PrintText 110,s6,TEXT_NEGCON
   b type_end
   nop
      
   type_konami_lightgun:
   PrintText 110,s6,TEXT_KONAMILIGHTGUN
   b type_end
   nop   
   
   type_analog_stick:
   PrintText 110,s6,TEXT_ANALOGSTICK
   b type_end
   nop
        
   type_namco_lightgun:
   PrintText 110,s6,TEXT_NAMCOLIGHTGUN
   b type_end
   nop   
   
   type_analog_pad:
   PrintText 110,s6,TEXT_ANALOGPAD
   b type_end
   nop   
   
   type_multitap:
   PrintText 110,s6,TEXT_MULTITAP
   b type_end
   nop   
   
   type_jogcon:
   PrintText 110,s6,TEXT_JOGCON
   b type_end
   nop   
   
   type_ds_configmode:
   PrintText 110,s6,TEXT_DSCONFIGMODE
   b type_end
   nop
   
   type_end:

jr $31
nop

.align 256
clear_minmax:

   la a1,DATABYTES
   lb s1,0(a1)
   nop
   
   ; check if no pad
   li t0,1
   beq s1,t0,clear_done
   
   ; check for type
   la a1,DATARECEIVE
   addiu a1,3
   lb s2,0(a1)
   nop
   
   ; check if start is pressed
   li t0,0x08
   and s2,t0
   bnez s2,clear_done
   nop
   
   ; clear minmax
   li t0,0xFFFF
   li t1,0x0000
   
   la a1,TIMEDATAMIN
   sh t0,0(a1)
   la a1,TIMEDATAMAX
   sh t1,0(a1)
   
   la a1,TIMEACKHIMIN
   sh t0,0(a1)
   la a1,TIMEACKHIMAX
   sh t1,0(a1)
   
   la a1,TIMEACKLOMIN
   sh t0,0(a1)
   la a1,TIMEACKLOMAX
   sh t1,0(a1)
   
   clear_done:

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

DATABYTES:   .db 0
DATARECEIVE: .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.align 4
TIMERECEIVE: .dh 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
TIMEACKHI:   .dh 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
TIMEACKLO:   .dh 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

TIMEDATAMIN:  .dh 0xFFFF
TIMEDATAMAX:  .dh 0x0000
TIMEACKHIMIN: .dh 0xFFFF
TIMEACKHIMAX: .dh 0x0000
TIMEACKLOMIN: .dh 0xFFFF
TIMEACKLOMAX: .dh 0x0000
  
TEXT_TITLE:          .db "JOYPAD TEST - RAW DATA AND TIMING",0
TEXT_HEADER:         .db "BYTE DATA  T-DATA  T-ACKHI  T-ACKLO",0
TEXT_MINMAXHEADER:   .db "TIME      MIN     MAX  (START=CLEAR)",0
TEXT_TIMEDATA:       .db "DATA",0
TEXT_TIMEACKHI:      .db "ACK HIGH",0
TEXT_TIMEACKLO:      .db "ACK LOW",0

TEXT_TYPE:           .db "TYPE:",0
TEXT_NONE:           .db "NONE",0
TEXT_UNKNOWN:        .db "UNKNOWN",0
TEXT_DIGITAL:        .db "DIGITAL",0
TEXT_MOUSE:          .db "MOUSE",0
TEXT_NEGCON:         .db "NEGCON",0
TEXT_KONAMILIGHTGUN: .db "KONAMI LIGHTGUN:",0
TEXT_ANALOGSTICK:    .db "ANALOG STICK",0
TEXT_NAMCOLIGHTGUN:  .db "NAMCO LIGHTGUN",0
TEXT_ANALOGPAD:      .db "ANALOG PAD",0
TEXT_MULTITAP:       .db "MULTITAP",0
TEXT_JOGCON:         .db "JOGCON",0
TEXT_DSCONFIGMODE:   .db "DSCONFIGMODE",0

.close