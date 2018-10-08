#include <mips/regdet.h>
#include<sys/syscall.h>

.text
.abicalls
.align 2
.globl encode
.ent encode
.globl decode
.ent decode

encode:

.frame
	.set norder
	.cpload(t9)
	.set reorder
	subu sp,sp, FRAME_SZ
	sw ra,(FRAME_SZ-8)(sp) #cambie aca por la constante porque me parece que va a tener que ser mas de 40
	sw gp,(FRAME_SZ-12)(sp)
	sw $fp,(FRAME_SZ-16)(sp)
	.move $fp,sp

	#Guardar parámetros en la pila
	sw a0, FRAME_SZ(sp) #Salvo el file descriptor de entrada en el arg building area del caller a0 -> fp
	sw a1, (FRAME_SZ+4)(sp) #Salvo el file descriptor de salida en el arg building area del caller a1 -> wfp

	#Preparar los registros temporales

	li t0,0 #cargo un 0 en t0 para usarlo de contador
	sw t0,16(sp) #guardo t0 en el area de la pila de las variables locales

	li t1,1 #cargo un 1 en t1 para ir a caso1
	sw t1,20(sp)

	li t2,2 #cargo un 2 en t2 para ir a caso2
	sw t2,24(sp)

	#DUDOSO. Necesito cargar dos variables temporales para poder entrar a cada caso. 
	#Los cargo inicialmente con 0 para ponerlos en la pila?

	li t3,0 
	sw t3,28(sp) 

	li t4,0 
	sw t4,32(sp)

	ba lectura

lectura:
	#Leo un caracter
	la t9, read_c #en t9 está la subrutina read_c?
	jal t9 #salta a subrutina read_c
	#Parametros necesarios para leer: en a0 fd y es así

	sw v0,36(sp) #guardo el resultado de la lectura en la pila
	lw t5,36(sp) #en t5 está el carácter leído

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba ciclo 

ciclo:	
	beq t5, $zero, finalizar_escritura #llego a un EOF 

	#Llamo a los correspondientes casos
	beq t0, $zero, caso0
	beq t0, t1, caso1
	beq t0, t2, caso2

caso0:
	and t3, t5, a1maske #a1 = buffer & a1mask; 
	srl t3, t3, 2 #a1 = a1 >> 2;
	sw t3,28(sp) #actualizo valor de la pila

	and t4, t5, a2maske #a2 = buffer & a2mask;
	sll t4, t4, 4 #	a2 = a2 << 4;
	sw t4,32(sp) #actualizo valor de la pila

	addi t0, t0, 1 #contador++. PUEDE FALLAR
	sw t0,16(sp) #actualizo valor de la pila

	ba escritura 
	#Se pasan parametros a1 y la tabla con indice t3 #write_caracter(wfp,B64[a1]);

caso1:
	and t3, t5, b1maske #b1 = buffer & b1mask;
	srl t3, t3, 4 #b1 = b1 >> 4;
	or t3, t3, t4 #b1 = b1 | a2; 
	sw t3,28(sp) #actualizo valor de la pila

	and t4, t5, b2maske #b2 = buffer & b2mask;
	sll t4, t4, 2 #b2 = b2 << 2;	
	sw t4,32(sp) #actualizo valor de la pila

	addi t0, t0, 1 #contador++. PUEDE FALLAR
	sw t0,16(sp) #actualizo valor de la pila

	ba escritura
	#Se pasan parametros a1 y la tabla con indice t3 #write_caracter(wfp,B64[b1]);

caso2:
	and t3, t5, c1maske #c1 = buffer & c1mask;
	srl t3, t3, 6 #c1 = c1 >> 6;
	or t3, t3, t4 #c1 = c1 | b2;
	sw t3,28(sp) #actualizo valor de la pila

	and t4, t5, c2maske #c2 = buffer & c2mask;
	sw t4,32(sp) #actualizo valor de la pila

	li t0, 0 #contador = 0;
	sw t0,16(sp) #actualizo valor de la pila

	ba escritura
	#Se pasan parametros a1 y la tabla con indice t3 #write_caracter(wfp,B64[c1]);
	#Falta pasar parametros a1 y la tabla con indice t4 #write_caracter(wfp,B64[c2]) -> al salir del ciclo

escritura: 
	#Parametros necesarios para escribir: en a0 wfd y no es así y en a1 t3

	lw a0,(FRAME_SZ+4)(sp) #pongo en a0 wfd que esta en a1
	lw a1, 28(sp) #pongo en a1 el caracter a escribir que es t3

	la t9, write_c #en t9 está la subrutina write_c?
	jal t9 #salta a subrutina write_c

	sw v0,40(sp) #guardo el resultado de la escritura en la pila
	lw t6,40(sp) #en t6 está el resultado de la escritura ?

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba lectura

finalizar_escritura: 
	#Agrego caso faltante: pasar parametros a1 y la tabla con indice t4 #write_caracter(wfp,B64[c2])
	#Parametros necesarios para escribir: en a0 wfd y no es así y en a1 t4

	lw a0,(FRAME_SZ+4)(sp) #pongo en a0 wfd que esta en a1
	lw a1, 32(sp) #pongo en a1 el caracter a escribir que es t4

	la t9, write_c #en t9 está la subrutina write_c?
	jal t9 #salta a subrutina write_c

	sw v0,40(sp) #guardo el resultado de la escritura en la pila
	lw t6,40(sp) #en t6 está el resultado de la escritura ?

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	beq t0, t1, casodobleigual #se que es malo el nombre 
	beq t0, t2, casoigual 
	ba end

casodobleigual:
	#escribir lo que esté en t3
	#escribir doble igual
	ba end

casoigual:
	#escribir lo que esté en t3
	#escribir un igual
	ba end

end:
	lw ra,(FRAME_SZ-8)(sp) 
	lw gp,(FRAME_SZ-12)(sp)
	lw $fp,(FRAME_SZ-16)(sp)

	addu sp,sp,FRAME_SZ #Libero el stackFrame

	jr ra
	.end write_c
	.rdata #que va aca???????????
	.align 2


#define a1maske 0xFC
#define a2maske 0x03 		
#define b1maske 0xF0
#define b2maske 0x0F
#define c1maske 0xC0
#define c2maske 0X3F
#define FRAME_SZ 

###############Decode##########################

decode:

.frame
	.set norder
	.upload(t9)
	.set reorder
	subu sp,sp, FRAME_SZ
	sw ra,(FRAME_SZ-8)(sp) #cambie aca por la constante porque me parece que va a tener que ser mas de 40
	sw gp,(FRAME_SZ-12)(sp)
	sw $fp,(FRAME_SZ-16)(sp)
	.move $fp,sp

	#Guardar parámetros en la pila
	sw a0, FRAME_SZ(sp) #Salvo el file descriptor de entrada en el arg building area del caller a0 -> fp
	sw a1, (FRAME_SZ+4)(sp) #Salvo el file descriptor de salida en el arg building area del caller a1 -> wfp

	#Preparar los registros temporales

	li t0,0 #cargo un 0 en t0 para usarlo de contador
	sw t0,16(sp) #guardo t0 en el area de la pila de las variables locales

	li t1,1 #cargo un 1 en t1 para ir a caso1
	sw t1,20(sp)

	li t2,2 #cargo un 2 en t2 para ir a caso2
	sw t2,24(sp)

	#DUDOSO. Necesito cargar dos variables temporales para poder entrar a cada caso. 
	#Los cargo inicialmente con 0 para ponerlos en la pila?

	li t3,5 #guardo numero distinto de 0
	sw t3,28(sp) 

	li t4,5 #guardo numero distinto de 0
	sw t4,32(sp)

	li t5, 0 #completamente temporal
	sw t5,36(sp)

	ba lectura_inicial

lectura_inicial: 
	#Parametro necesario para leer: en a0 el fd y es asi

	la t9, read_c #en t9 está la subrutina read_c?
	jal t9 #salta a subrutina read_c

	sw v0,28(sp) #guardo el resultado de la lectura en la pila
	lw t3,28(sp) #en t3 está el carácter leído
	#PASAR A B64 LO QUE ESTÁ EN T3

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)
	lw t5,36(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba ciclo 

ciclo:
	beq t3, $zero, end  
	beq t4, $zero, end #en los dos registros se lee

	#Llamo a los correspondientes casos
	beq t0, $zero, caso0
	beq t0, t1, caso1
	beq t0, t2, caso2

caso0:
	#Leer un caracter, pasar a b64 y guardarlo en t4
	#Parametro necesario para leer: en a0 el fd y es asi

	la t9, read_c #en t9 está la subrutina read_c?
	jal t9 #salta a subrutina read_c

	sw v0,32(sp) #guardo el resultado de la lectura en la pila
	lw t4,32(sp) #en t4 está el carácter leído
	#PASAR A B64 LO QUE ESTÁ EN T4

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)
	lw t5,36(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	sll t3, t3, 2 #a = a << 2
	and t5, t4, mask1d #b & mask1
	srl t5, t5, 4 #(b & mask1) >> 4
	or t3, t3, t5 #a = a | ((b & mask1) >> 4);

	addi t0, t0, 1 #contador++
	sw t0,16(sp) #actualizo el valor de la pila

	#Escribir caracter con valor t3(a) en ascii
	ba escrituracaso0

caso1:
	#Leer un caracter, si es = ir a end
	#Parametro necesario para leer: en a0 el fd y es asi

	la t9, read_c #en t9 está la subrutina read_c?
	jal t9 #salta a subrutina read_c

	sw v0,28(sp) #guardo el resultado de la lectura en la pila
	lw t3,28(sp) #en t3 está el carácter leído
	#PASAR A B64 LO QUE ESTÁ EN T3
	#Si es = ir a end

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)
	lw t5,36(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	sll t4, t4, 4 #b << 4
	and t5, t3, mask2d #c & mask2
	srl t5, t5, 2 #(c & mask2) >> 2
	or t4, t4, t5 #b = b | ((c & mask2) >> 2);


	addi t0, t0, 1 #contador++
	sw t0,16(sp) #actualizo el valor de la pila

	#Escribir caracter con valor t4(b) en ascii
	ba escrituracaso1

caso2:
	#Leer un caracter, si es = ir a end
	#Parametro necesario para leer: en a0 el fd y es asi

	la t9, read_c #en t9 está la subrutina read_c?
	jal t9 #salta a subrutina read_c

	sw v0,32(sp) #guardo el resultado de la lectura en la pila
	lw t4,32(sp) #en t4 está el carácter leído
	#PASAR A B64 LO QUE ESTÁ EN T4
	#Si es = ir a end

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)
	lw t5,36(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 
	
	sll t3, t3, 6 #c << 6	
	and t5, t4, mask3d	#d & mask3
	or t3, t3, t5 #c = c | (d & mask3);

	#Escribir caracter con valor t3(c) en ascii
	ba escrituracaso2

escrituracaso0:
	#Parametros necesarios para escribir: en a0 wfd y no es así y en a1 t3

	lw a0,(FRAME_SZ+4)(sp) #pongo en a0 wfd que esta en a1
	lw a1, 28(sp) #pongo en a1 el caracter a escribir que es t3

	la t9, write_c #en t9 está la subrutina write_c?
	jal t9 #salta a subrutina write_c

	sw v0,40(sp) #guardo el resultado de la escritura en la pila
	lw t6,40(sp) #en t6 está el resultado de la escritura ?

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba ciclo #continue

escrituracaso1:
	#Parametros necesarios para escribir: en a0 wfd y no es así y en a1 t4

	lw a0,(FRAME_SZ+4)(sp) #pongo en a0 wfd que esta en a1
	lw a1, 32(sp) #pongo en a1 el caracter a escribir que es t4

	la t9, write_c #en t9 está la subrutina write_c?
	jal t9 #salta a subrutina write_c

	sw v0,40(sp) #guardo el resultado de la escritura en la pila
	lw t6,40(sp) #en t6 está el resultado de la escritura ?

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba ciclo #continue

escrituracaso2:
	#Parametros necesarios para escribir: en a0 wfd y no es así y en a1 t3

	lw a0,(FRAME_SZ+4)(sp) #pongo en a0 wfd que esta en a1
	lw a1, 28(sp) #pongo en a1 el caracter a escribir que es t3

	la t9, write_c #en t9 está la subrutina write_c?
	jal t9 #salta a subrutina write_c

	sw v0,40(sp) #guardo el resultado de la escritura en la pila
	lw t6,40(sp) #en t6 está el resultado de la escritura ?

	#Salvo registros que pueden haberse perdido con llamado a subrutina
	lw t0,16(sp)
	lw t1,20(sp)
	lw t2,24(sp)
	lw t3,28(sp)
	lw t4,32(sp)	
	lw a0,FRAME_SZ(sp)
	lw a1,(FRAME_SZ+4)(sp) 

	ba lectura_inicial

end:
	lw ra,(FRAME_SZ-8)(sp) 
	lw gp,(FRAME_SZ-12)(sp)
	lw $fp,(FRAME_SZ-16)(sp)

	addu sp,sp,FRAME_SZ #Libero el stackFrame

	jr ra
	.end write_c
	.rdata #que va aca???????????
	.align 2

#define mask1d 0x30
#define mask2d 0x3C
#define mask3d 0x3F
#define FRAME_SZ 

tablab64: 
	i1: .ascii 'A'
	i2: .ascii 'B'
	i3: .ascii 'C'
	i4: .ascii 'D'
	i5: .ascii 'E'
	i6: .ascii 'F'
	i7: .ascii 'G'
	i8: .ascii 'H'
	i9: .ascii 'I'
	i10: .ascii 'J'
	i11: .ascii 'K'
	i12: .ascii 'K'
	i13: .ascii 'L'
	i14: .ascii 'M'
	i15: .ascii 'N'
	i16: .ascii 'O'
	i17: .ascii 'P'
	i18: .ascii 'Q'
	i19: .ascii 'R'
	i20: .ascii 'S'
	i21: .ascii 'T'
	i22: .ascii 'U'
	i23: .ascii 'V' 
	i24: .ascii 'W'
	i25: .ascii 'X'
	i26: .ascii 'Y'
	i27: .ascii 'Z'
	i28: .ascii 'a'
	i29: .ascii 'b'
	i30: .ascii 'c'
	i31: .ascii 'd'
	i32: .ascii 'e'
	i33: .ascii 'f'
	i34: .ascii 'g'
	i35: .ascii 'h'
	i36: .ascii 'i'
	i37: .ascii 'j'
	i38: .ascii 'k'
	i39: .ascii 'l'
	i40: .ascii 'm'
	i41: .ascii 'o'
	i42: .ascii 'p'
	i43: .ascii 'q'
	i44: .ascii 'r'
	i45: .ascii 's'
	i46: .ascii 't'
	i47: .ascii 'u'
	i48: .ascii 'v'
	i49: .ascii 'w'
	i50: .ascii 'x'
	i51: .ascii 'y'
	i52: .ascii 'z'
	i53: .ascii '0'
	i54: .ascii '1'
	i55: .ascii '2'
	i56: .ascii '3'
	i57: .ascii '4'
	i58: .ascii '5'
	i59: .ascii '6'
	i60: .ascii '7'
	i61: .ascii '8'
	i62: .ascii '9'
	i63: .ascii '+' 
	i64: .ascii '/'