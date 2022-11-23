.macro storeVariableConstantWord,value,base

   li t8,value
   la a2,base
   sw t8,0(a2)

.endmacro

.macro storeVariableWord,source,base

   la a2,base
   sw source,0(a2)

.endmacro

.macro loadVariableWord,target,base

   la a2,base
   lw target,0(a2)
   nop

.endmacro


.macro storeArrayWord,source,base,index

   la a2,base
   sll t8, index, 2
   addu a2,t8
   sw source,0(a2)

.endmacro

.macro loadArrayWord,target,base,index

   la a2,base
   sll t8, index, 2
   addu a2,t8
   lw target,0(a2)
   nop

.endmacro