#####################################################
#   Refactorización del modelo para pruebas de      #
#   desempeño de motores de optimización            #
#   Oscar A. Esquivel-Flores                        #
#   Sept, 2022                                      # 
#                                                   #
#   Incluye                                         #
#   2 refinerías con coquizadora                    #
#       3 crudos                                    #
#       4 productos                                 #
#   3 mercados + comercio exterior                  #
#   Rafael García Jolly                             #
#   Julio 27, 2022                                  #
#	v1.0                                            #
#####################################################		

#####################
#   Julia v1.7.2    #
#   Cbc v1.0.1      #
#   Clp v1.0.1      #
#   GLPK v1.0.1     #
#   JuMP v1.1.1     #
#   DelimitedFiles  #
#####################

using JuMP
using GLPK
using DelimitedFiles 

########## Datos ########
#########################

# Nomenclatura (fijos)
data_crudos = Dict("LIG" => "Ligero", "MED" => "Medio",	"PES" =>"Pesado")	# Crudos
data_productos = Dict("LPG" => "Ligeros", "GNA" => "Gasolina", "DSL" => "Diésel", "FO6" => "Combustóleo") # Productos
data_prodpueref = Dict("LPG" => "Ligeros", "FO6" => "Combustóleo") # Productos a puerta de refinería 
data_petrodist = Dict("GNA" => "Gasolina", "DSL" => "Diésel") # Petrolíferos a distribución
data_mercados = Dict("MEX" => "ZMVM", "BAJ" => "Bajío",	"OCC" => "Occidente", "EXT" => "Exportaciones") # Mercados 
data_refineria = Dict("TUL" => "Tula", "SAL" => "Salamanca") # Refinerías

# Compras de crudo
data_crucos = Dict("LIG" => 15, "MED" => 14, "PES" => 13)
data_crumin = Dict("LIG" =>	32, "MED" => 20, "PES" => 25)
data_crumax = Dict("LIG" => 70, "MED" => 40, "PES" => 58)

# Importaciones
data_impcos = Dict("GNA" =>	24, "DSL" => 20)
data_implog = Dict("MEX" =>	1.1, "BAJ" => 1.6, "OCC" =>	2, "EXT" =>	999)

# Refinerias
data_descap = Dict("TUL" => 100, "SAL" => 60)
data_cokcap = Dict("TUL" => 25, "SAL" => 15)
data_descos = Dict("TUL" =>	0.5, "SAL" => 0.75)

data_maxpes = Dict("TUL" =>	0.45, "SAL" => 0.2)
data_yield = [ "TUL" "LIG" "LPG" 0.10;
               "TUL" "LIG" "GNA" 0.40;
               "TUL" "LIG" "DSL" 0.35;
               "TUL" "LIG" "FO6" 0.15;
               "TUL" "MED" "LPG" 0.08;
               "TUL" "MED" "GNA" 0.35;
               "TUL" "MED" "DSL" 0.32;
               "TUL" "MED" "FO6" 0.25;
               "TUL" "PES" "LPG" 0.05;
               "TUL" "PES" "GNA" 0.30;
               "TUL" "PES" "DSL" 0.25;
               "TUL" "PES" "FO6" 0.40;
               "SAL" "LIG" "LPG" 0.12;
               "SAL" "LIG" "GNA" 0.39;
               "SAL" "LIG" "DSL" 0.32;
               "SAL" "LIG" "FO6" 0.17;
               "SAL" "MED" "LPG" 0.11;
               "SAL" "MED" "GNA" 0.36;
               "SAL" "MED" "DSL" 0.31;
               "SAL" "MED" "FO6" 0.22;
               "SAL" "PES" "LPG" 0.06;
               "SAL" "PES" "GNA" 0.28;
               "SAL" "PES" "DSL" 0.22;
               "SAL" "PES" "FO6" 0.44]

data_yielk = ["TUL" "LPG" 0.06;
              "TUL" "GNA" 0.35;
              "TUL" "DSL" 0.32;
              "TUL" "FO6" -1;
              "SAL" "LPG" 0.03;
              "SAL" "GNA" 0.38;
              "SAL" "DSL" 0.35;
              "SAL" "FO6" -1]

data_vtarpre = ["TUL" "LPG" 15.00;
                "TUL" "FO6" 40.00; 
                "SAL" "LPG" 14.50;
                "SAL" "FO6"  9.90 ]

# Ventas


data_vtaspre = ["MEX" "GNA"  25.00;
                "MEX" "DSL"  21.00;
                "BAJ" "GNA"  25.50;
                "BAJ" "DSL"  21.70;
                "OCC" "GNA"  26.10;
                "OCC" "DSL"  22.00;
                "EXT" "GNA"  24.00;
                "EXT" "DSL"  20.00]

data_vtasmin = ["MEX" "GNA"  25.00;
                "MEX" "DSL"  15.00;
                "BAJ" "GNA"  22.50;
                "BAJ" "DSL"  17.50;
                "OCC" "GNA"  20.00;
                "OCC" "DSL"  15.00;
                "EXT" "GNA"  0.00;
                "EXT" "DSL"  0.00]

data_vtasmax = ["MEX" "GNA"  50.00;
                "MEX" "DSL"  30.00;
                "BAJ" "GNA"  45.00;
                "BAJ" "DSL"  35.00;
                "OCC" "GNA"  40.00;
                "OCC" "DSL"  30.00;
                "EXT" "GNA"  999.00;
                "EXT" "DSL"  999.00]

# Transporte
data_trntar = ["REF" "MEX" "BAJ" "OCC" "EXT";
               "TUL"  0.50  1.20  1.80  2.00;
               "SAL"  1.10	0.30  0.75	2.50]

data_trntar = [ "TUL" "MEX" 0.50
                "TUL" "BAJ" 1.20
                "TUL" "OCC" 1.80
                "TUL" "EXT" 2.00
                "SAL" "MEX" 1.10
                "SAL" "BAJ" 0.30
                "SAL" "OCC" 0.75
                "SAL" "EXT" 2.50]

data_trnmax = [ "TUL" "MEX" 70.0
                "TUL" "BAJ" 50.0
                "TUL" "OCC" 50.0
                "TUL" "EXT" 999.0
                "SAL" "MEX" 30.0
                "SAL" "BAJ" 50.0
                "SAL" "OCC" 50.0
                "SAL" "EXT" 999.0]

###### Identificadores y parámetros #####
#########################################

# Conjuntos
CRD = keys(data_crudos)  # Crudos 
PRODS = keys(data_productos) # Productos
PRO = keys(data_prodpueref)  # Productos a puerta de refinería
PTR = keys(data_petrodist)   # Petrolíferos a distribución
MER = keys(data_mercados)    # Mercados
REF = keys(data_refineria)	 # Refinerías

# Parámetros

# Compras de crudo
CRUCOS = data_crucos  # Costo
CRUMIN = data_crumin  # Mínimo
CRUMAX = data_crumax  # Máximo

# Importaciones
IMPCOS = data_impcos   # Costo
IMPLOG = data_implog   # Costo de logística


# Refinerías
DESCAP = data_descap	# Capacidad de destilación
COKCAP = data_cokcap	# Capacidad de coquizadora
DESCOS = data_descos	# Costo de operación
MAXPES = data_maxpes		# Máximo contenido de crudo pesado
YIELD = Dict((data_yield[:,1][i], data_yield[:,2][i], data_yield[:,3][i]) => data_yield[:,4][i] for i in 1:size(data_yield)[1]) # Rendimientos en destilación
YIELK = Dict((data_yielk[:,1][i], data_yielk[:,2][i]) => data_yielk[:,3][i] for i in 1:size(data_yielk)[1]) # Rendimientos en coquizadora  
VTARPRE = Dict((data_vtarpre[:,1][i], data_vtarpre[:,2][i]) => data_vtarpre[:,3][i] for i in 1:size(data_vtarpre)[1]) # Precio de ventas a puerta de refinería

# Ventas
VTASPRE = Dict((data_vtaspre[:,1][i], data_vtaspre[:,2][i]) => data_vtaspre[:,3][i] for i in 1:size(data_vtaspre)[1]) # Precio de ventas en terminales
VTASMIN = Dict((data_vtasmin[:,1][i], data_vtasmin[:,2][i]) => data_vtasmin[:,3][i] for i in 1:size(data_vtasmin)[1]) # Mínimo de ventas en terminales
VTASMAX = Dict((data_vtasmax[:,1][i], data_vtasmax[:,2][i]) => data_vtasmax[:,3][i] for i in 1:size(data_vtasmax)[1]) # Máximo de ventas en terminales                              

# Transporte
TRNTAR = Dict( (data_trntar[:,1][i], data_trntar[:,2][i]) => data_trntar[:,3][i] for i in 1:size(data_trntar)[1]) # trarifas de transporte
TRNMAX = Dict( (data_trnmax[:,1][i], data_trnmax[:,2][i]) => data_trnmax[:,3][i] for i in 1:size(data_trnmax)[1]) # Capacidad máxima de transporte

##### Preparación del modelo de optimización ####
#################################################

m = Model(GLPK.Optimizer)

### Variables ###

# Compras de crudo
@variable(m, CRUVOL[CRD]) # Volumen
@constraint(m, [c in CRD], CRUMIN[c] <= CRUVOL[c]  <= CRUMAX[c]) # Restricciones al volumen

# Importaciones
@variable(m, IMPVOL[PTR] >= 0) # Volumen
@variable(m, IMPMER[MER] >= 0) # Volumen de logística

# Refinerías
@variable(m, DESVOL[REF]) # Proceso de crudo
@constraint(m, [r in REF], 0 <= DESVOL[r] <= DESCAP[r]) # Restricciones al proceso de crudo

DESVOL
DESCAP

@variable(m, COKVOL[REF])	# Utilización de coquizadora
@constraint(m, [r in REF], 0 <= COKVOL[r] <= COKCAP[r]) # Restricciones a utilización de Coquizadora

@variable(m, PROCESO[REF, CRD] >=0) # Proceso por tipo de crudo
@variable(m, PRODUCC[REF, PRODS] >=0) # Volumen de producción
@variable(m, VTAREF[REF, PRO] >=0) # Volumen de ventas a puerta de refinería

# Ventas
@variable(m, VTASVOL[MER, PTR]) # Volumen de ventas en terminales
@constraint(m, [mr in MER, p in PTR], VTASMIN[mr,p] <= VTASVOL[mr, p] <= VTASMAX[mr,p] ) # Restriccion de volumen de ventas en terminales
@variable(m, VTASIMP[mr in MER, p in PTR] >=0) # Volumen de importación hacia terminales

# Transporte
@variable(m, TRNVOL[REF, MER] >= 0) # Volumen total de transporte
@constraint(m, [r in REF, mr in MER], 0 <= TRNVOL[r, mr] <= TRNMAX[r, mr]) # Restricción volumen total de transporte
@variable(m, TRANSFER[r in REF, mr in MER, p in PTR] >= 0 ) # Volumen de transporte por producto

# Variables parciales
@variable(m, COSDIS >= 0)	# Costos de distribución
@variable(m, COSCOM >= 0)   # Compra de materias primas
@variable(m, COSREF >= 0)   # Costos de refinación
@variable(m, INGVTA >= 0)	# Ingreso por ventas


### Función objetivo ### 
@objective(m, Max, INGVTA - COSDIS - COSCOM - COSREF)

### Resctricciones ###
@constraint(m, TOTING, INGVTA == sum(VTASVOL[mr,p] * VTASPRE[mr,p] for mr in MER, p in PTR) + sum(VTAREF[r,p] * VTARPRE[r,p] for r in REF, p in PRO)) 
@constraint(m, TOTCOM, COSCOM == sum(CRUVOL[c] * CRUCOS[c] for c in CRD) + sum(IMPVOL[p] * IMPCOS[p] for p in PTR))
@constraint(m, TOTCRF, COSREF == sum(DESVOL[r] * DESCOS[r] for r in REF))
@constraint(m, TOTLOG, COSDIS == sum(TRNVOL[r,mr] * TRNTAR[r,mr] for r in REF, mr in MER) + sum(IMPMER[mr] * IMPLOG[mr] for mr in MER))
# Importaciones
@constraint(m, IMPOR[p in PTR], IMPVOL[p] == sum(VTASIMP[mr, p] for mr in MER))
# Proceso en refinerías
@constraint(m, VOLCRU[c in CRD], CRUVOL[c] == sum(PROCESO[r, c] for r in REF)) # Suma de compras por tipo de crudo
@constraint(m, PROCREF[r in REF], DESVOL[r] == sum(PROCESO[r, c] for c in CRD)) # Proceso por refinería
@constraint(m, PRODREF[r in REF, p in PRODS], PRODUCC[r,p] == sum(PROCESO[r,c] * YIELD[r,c,p] for c in CRD) + sum(COKVOL[r] * YIELK[r,p])) # Producción de petrolíferos
@constraint(m, PESADO[r in REF], PROCESO[r, "PES"] <= MAXPES[r] * DESVOL[r]) # Control de máximo crudo pesado
# Entrega a distribución y ventas a puerta de refinería
@constraint(m, BALAN1[r in REF, p in PTR], PRODUCC[r,p] == sum(TRANSFER[r,mr,p] for mr in MER)) # Entrega a la red de transporte
@constraint(m, BALAN2[r in REF, p in PRO], PRODUCC[r,p] == VTAREF[r,p]) # Ventas a puerta de refinería
# Recepción de petrolíferos en terminales
@constraint(m, VENTAS[mr in MER, p in PTR], VTASVOL[mr,p] == sum(TRANSFER[r,mr,p] for r in REF) + VTASIMP[mr,p]) # Ventas en terminales
@constraint(m, IMPORTOT[mr in MER], IMPMER[mr] == sum(VTASIMP[mr,p] for p in PTR)) # Importaciones por mercado
# Totalizador de transporte
@constraint(m, TOTTRN[r in REF, mr in MER], TRNVOL[r,mr] == sum(TRANSFER[r,mr,p] for p in PTR))

# Escritura Modelo de Optimización
print(m)

##### Solución del modelo de optimización ####
##############################################

# Solución Modelo Optimización
JuMP.optimize!(m)

# Escritura Solución Óptima
println("Soluciones Óptimas:")
println("Objective value: ", JuMP.objective_value(m));

println("CRUVOL: ", JuMP.value.(CRUVOL));
println("IMPVOL: ", JuMP.value.(IMPVOL));
println("IMPMER: ", JuMP.value.(IMPMER));
println("DESVOL: ", JuMP.value.(DESVOL));
println("COKVOL: ", JuMP.value.(COKVOL));
println("PROCESO: ", JuMP.value.(PROCESO));
println("PRODUCC: ", JuMP.value.(PRODUCC));
println("VTAREF: ", JuMP.value.(VTAREF));
println("VTASVOL: ", JuMP.value.(VTASVOL));
println("VTASIMP: ", JuMP.value.(VTASIMP));
println("TRNVOL: ", JuMP.value.(TRNVOL));
