/*
		Modelo de pre-optimización de la refinería de Cadereyta
		Rafael García Jolly
		20220627
		
		Datos: Cubo de la refinería calculado por Jonathan Grimaldo
		en archivos *.csv
		
*/
# Definición de identificadores y parámetros de tablas
	set REFINERIA;					#Refinería
	set CRUDO;						# Tipos de crudo
	set MODOPER;					# Modo de operación (lambdas)
	set PRODUCTO;					# Productos terminados
	set PLANTA;						# Plantas de proceso
	set RLCP, dimen 4;				#Refinería_Modoper_Crudo_Producto
	set RLCF dimen 4;				#Refinería_Modoper_Crudo_Planta
	set RC dimen 2;					#Refinería_Crudo
	set RP dimen 2;					#Refinería_Producto
	set RF dimen 2;					#Refinería_Planta


	param YIELDS{RLCP};
	param USOPLAN{RLCF};
	param PRECIOCRU{RC};
	param PRECIOPRO{RP};
	param CAPAMAX{RF};
	param MINPES{REFINERIA};
	param MAXPES{REFINERIA};

# Lectura de datos desde tablas csv
	table tyields IN "CSV" "Yields.csv" :
		RLCP <- [refineria,modoper,crudo,producto], YIELDS ~ valor;
	table tusoplan IN "CSV" "UsoPlan.csv" :
		RLCF <- [refineria,modoper,crudo,planta], USOPLAN ~ valor;
	table tpreciocru IN "CSV" "PrecioCru.csv":
		RC <- [refineria,crudo], PRECIOCRU ~ valor;
	table tprecioprod IN "CSV" "PrecioProd.csv" :
		RP <- [refineria,producto], PRECIOPRO ~ valor;
	table tcapamax IN "CSV" "CapaMax.csv" :
		RF <- [refineria,planta], CAPAMAX ~ valor;
	table tpesado IN "CSV" "MaxPes.csv" :
		REFINERIA <- [refineria], MINPES ~ minimo, MAXPES ~ maximo;

# Comprobación de lectura de tablas
/*
	display YIELDS;
	display USOPLAN;
	display PRECIOCRU;
	display PRECIOPRO;
	display CAPAMAX;
	display MINPES, MAXPES;
	display REFINERIA;
	display CRUDO, MODOPER, PRODUCTO, PLANTA;
*/

# Declaración de variables
	var PROCESO {REFINERIA,
					CRUDO}, >=0;			# Crudo por tipo procesado en la refinería
	var DESTIPRIM {REFINERIA,
					MODOPER,
					CRUDO}, >=0;			# Proceso de crudo por modo de operación
	var PRODUCCION {REFINERIA,
					PRODUCTO}, >=0;			# Producción de petrolíferos en refinería
	var USOCAP {REFINERIA,
					PLANTA}, >=0;			# Capacidad utilizada de plantas en refinería
	var LAMBDA {REFINERIA,
					MODOPER}, integer;		# Modo de operación
	var INGRESO {REFINERIA}; 				# Ventas a puerta de refinería
	var EGRESO {REFINERIA}; 				# Costo de producción en refinería
	var INGRESOTOT;							# Ingresos totales
	var EGRESOTOT;							# Egresos totales

# Inicia la optimización
/*__________________________________________________________
*/
# Función objetivo
	maximize Z: INGRESOTOT - EGRESOTOT;
	s.t. TOTING: INGRESOTOT = sum {r in REFINERIA} INGRESO[r];
	s.t. TOTEGR: EGRESOTOT = sum {r in REFINERIA} EGRESO[r];
	s.t. VENTAS {r in REFINERIA}: INGRESO[r] = sum {p in PRODUCTO} 
				PRODUCCION[r,p] * PRECIOPRO[r,p];
	s.t. COMPRAS {r in REFINERIA}: EGRESO[r] = sum {c in CRUDO}
				PROCESO[r,c] * PRECIOCRU[r,c];

# 	Proceso de crudo
	s.t. PROCRU {r in REFINERIA, c in CRUDO} :
				PROCESO[r,c] = 
				sum{l in MODOPER} DESTIPRIM[r,l,c];
# Mínimo crudo pesado
	s.t. MNPES {r in REFINERIA} :
				PROCESO[r,'MAY'] >= MINPES[r]*sum{c in CRUDO} PROCESO[r,c];
# Máximo crudo pesado
	s.t. MXPES {r in REFINERIA} :
				PROCESO[r,'MAY'] <= MAXPES[r]*sum{c in CRUDO} PROCESO[r,c];
# Producción
	s.t. RENDIM {r in REFINERIA, p in PRODUCTO} :
				PRODUCCION[r,p] = 
				sum{l in MODOPER, c in CRUDO} DESTIPRIM[r,l,c]*YIELDS[r,l,c,p];
# Capacidad utilizada
	s.t. KAPAC {r in REFINERIA, f in PLANTA} :
				USOCAP[r,f] = 
				sum {l in MODOPER, c in CRUDO} DESTIPRIM[r,l,c]*USOPLAN[r,l,c,f];
	s.t. KAPMAX {r in REFINERIA, f in PLANTA} :
				USOCAP[r,f] <= CAPAMAX[r,f];
# Control de modo de operación
	s.t. MOPER {r in REFINERIA, l in MODOPER} :
				sum {c in CRUDO} DESTIPRIM[r,l,c] <= LAMBDA[r,l]*CAPAMAX[r,'ATM'];
	s.t. MOUNICO{r in REFINERIA}: sum{l in MODOPER} LAMBDA[r,l]=1;


solve;
display PROCESO;
display PRODUCCION;
display USOCAP;
display LAMBDA;





# Datos adicionales de nomenclatura (éstos no cambian)
	data;
	set CRUDO :=	IST	MAY;
				#  	Istmo	Maya
	set MODOPER := L1 L2 L3 L4;
				#  Lambdas
	set PRODUCTO :=	LPG	GNA	DSL	COM	CKE;
				#  Ligeros, Gasolinas, Diésel, Combustóleo, Coque
	set PLANTA :=	ATM	VAC	REF	FCC	COK;
				#  Primaria, Vacío, Reformadora, FCC, Coquizadora
