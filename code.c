#include "code.h"

//Definición de la tabla B64
const char B64[64]= {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 
'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'};

encode(FILE* fp, FILE* wfp) {

	//Definición de las máscaras a utilizar
	unsigned char a1mask = 0xFC;
	unsigned char a2mask = 0x03; 		
	unsigned char b1mask = 0xF0;
	unsigned char b2mask = 0x0F;
	unsigned char c1mask = 0xC0;
	unsigned char c2mask = 0X3F;

	//Definición de los resultados y variables temporales
	int contador = 0;
	int a1, a2, b1, b2, c1, c2;
	
	int caracter = fgetc(fp);
	
	while(caracter != EOF) {
			
		unsigned char buffer = (unsigned char) caracter;
		
		if(contador == 0) {
			a1 = buffer & a1mask; 
			a1 = a1 >> 2;
			a2 = buffer & a2mask;
			a2 = (unsigned char) a2 << 4;

			contador++;
			fprintf(wfp, "%c", B64[a1]);
			caracter = fgetc(fp);
			continue;
		}

		if(contador == 1) {
			b1 = buffer & b1mask;
			b1 = b1 >> 4;
			b1 = b1 | a2; 
			b2 = buffer & b2mask;
			b2 = (unsigned char)b2 << 2;	

			contador++;
			fprintf(wfp, "%c", B64[b1]);
			caracter = fgetc(fp);
			continue;
		}

		if(contador == 2) {
			c1 = buffer & c1mask;
			c1 = c1 >> 6;
			c1 = c1 | b2; 
			c2 = buffer & c2mask;

			contador = 0;
			fprintf(wfp, "%c", B64[c1]);
			fprintf(wfp, "%c", B64[c2]);
			caracter = fgetc(fp);
			continue;
		}	
	}
	
	switch (contador) {
		case 2:
			fprintf(wfp, "%c", B64[b2]);
			fprintf(wfp, "=");
			break;
		case 1:
			fprintf(wfp, "%c", B64[a2]);
			fprintf(wfp, "==");
			break;
	}
}


int get_i64(unsigned char c) { 
	for(int i=0; i<64; i++){
		if(B64[i] == c) {
		return i;
		}
	}
	return -1;
}

void decode(FILE* fp, FILE* wfp) {

	//Definición de las máscaras a utilizar
	unsigned char mask1 = 0x30; //00110000
	unsigned char mask2 = 0x3C; //00111100 		
	unsigned char mask3 = 0x3F; //00111111
	
	//Definición de los resultados y variables temporales
	int contador = 0;
	unsigned char a, b, c, d; 
	
	int caracter = fgetc(fp);
	unsigned char ascii_index = (unsigned char) caracter;
	a = (unsigned char)get_i64(ascii_index);

	while(caracter != EOF ) {
		
		if(contador == 0) {
			caracter = fgetc(fp);
			if(caracter == -1) break;
			
			unsigned char ascii_index = (unsigned char) caracter;
			b = (unsigned char)get_i64(ascii_index); 

			a = a << 2; 
			a = a | ((b & mask1) >> 4);

			fprintf(wfp, "%c", a);
			contador++;
			continue;
		}

		if(contador == 1) {
			caracter = fgetc(fp);
			if(caracter == '=') break;

			unsigned char ascii_index = (unsigned char) caracter;
			c = (unsigned char)get_i64(ascii_index); 

			b = b << 4;
			b = b | ((c & mask2) >> 2);

			fprintf(wfp, "%c", b);
			contador++;
			continue;
		}

		if(contador == 2) {
			caracter = fgetc(fp);
			if (caracter == '=') break;

			unsigned char ascii_index = (unsigned char) caracter;
			d = (unsigned char)get_i64(ascii_index); 	

			c = c << 6;
			c = c | (d & mask3);

			fprintf(wfp, "%c", c);
			a = (unsigned char) get_i64(fgetc(fp)) ;
			contador = 0;
			continue;
		}			
	}
}