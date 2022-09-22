#####################################################
#   Refactorización del modelo de pre-optimización  #
#   de la refinería de Cadereyta                    #
#   Oscar A. Esquivel-Flores                        #
#   Agosto, 2022                                    # 
#                                                   #
#   Modelo de pre-optimización de la refinería      #
#   de Cadereyta                                    #
#   Rafael García Jolly                             #
#   Junio 27, 2022                                  #
#		                                    #
#   Datos obtenidos del cubo de la refinería        #
#   Jonathan Grimaldo                               #
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

# De nomenclatura (fijos)
data_crudo = Dict("IST" => "Itsmo","MAY" => "Maya" )
data_modoper = Dict("L1" => "Lambda1", "L2" => "Lambda2", "L3" => "Lambda3", "L4" => "Lambda4" )
data_producto = Dict("LPG" => "Ligeros", "GNA" => "Gasolinas", "DSL" => "Diésel", "COM" => "Combustóleo" , "CKE" => "Coque")
data_planta = Dict("ATM" => "Primaria" , "VAC" => "Vacío", "REF" => "Reformadora", "FCC" => "Fcc", "COK" => "Coquizadora") 


# Lectura de archivos
data_yields = readdlm("./data/Yields.csv", ',', skipstart=1)        # extrae datos de rendimientos: refineria, modoper,crudo, producto,valor
data_uso_plan = readdlm("./data/UsoPlan.csv", ',', skipstart=1)     # extrae datos: refineria, modoper, crudo, planta, valor
data_prec_crudo = readdlm("./data/PrecioCru.csv", ',', skipstart=1) # extrae datos: refineria, crudo, valor 
data_prec_prod = readdlm("./data/precioprod.csv", ',', skipstart=1) # extrae datos de precios de productos: refineria, producto, valor
data_cap_max = readdlm("./data/CapaMax.csv", ',', skipstart=1)      # extrae datos de plantas:  refineria, planta, valor
data_minmax_pes = readdlm("./data/MaxPes.csv", ',', skipstart=1)    # extrae datos: refineria, minpes, maxpes

###### Identificadores y parámetros #####
#########################################

# Conjuntos

REFINERIA = data_minmax_pes[: , 1]  # Refinería
CRUDO = keys(data_crudo)            # Tipos de crudo
MODOPER = keys(data_modoper)        # Modo de operación (lambdas)
PRODUCTO = keys(data_producto)      # Productos terminados 
PLANTA = keys(data_planta)          # Plantas de proceso
RC = data_prec_crudo[: , 1:2]       # Refinería Crudo 2D
RP = data_prec_prod[: , 1:2]        # Refinería Producto 2D
RF = data_cap_max[: , 1:2]          # Refinería Planta 2D
RLCP = data_yields[: , 1:4]         # Refinería Modoper Crudo Producto 4D
RLCF = data_uso_plan[: , 1:4]       # Refinería Modoper Crudo Planta 4D 

# Parámetros

YIELDS = Dict( (data_yields[:,1][i], data_yields[:,2][i], data_yields[:,3][i], data_yields[:,4][i]) => data_yields[:,5][i] for i in 1:size(RLCP)[1])  # Rendimientos
USOPLAN = Dict( (data_uso_plan[:,1][i], data_uso_plan[:,2][i], data_uso_plan[:,3][i], data_uso_plan[:,4][i]) => data_uso_plan[:,5][i] for i in 1:size(RLCF)[1]) # Uso plantas
PRECIOCRU =  Dict( (data_prec_crudo[:,1][i], data_prec_crudo[:,2][i]) => data_prec_crudo[:,3][i] for i in 1:size(RC)[1] )  # Precio crudo
PRECIOPRO = Dict( (data_prec_prod[:,1][i], data_prec_prod[:,2][i]) => data_prec_prod[:,3][i] for i in 1:size(RP)[1] )   # Precio producto
CAPAMAX = Dict( (data_cap_max[:,1][i], data_cap_max[:,2][i]) => data_cap_max[:,3][i] for i in 1:size(RF)[1] )   # Capacidad máxima
MINPES = Dict(data_minmax_pes[:,1] .=> data_minmax_pes[:,2])
MAXPES = Dict(data_minmax_pes[:,1] .=> data_minmax_pes[:,3])


##### Preparación del modelo de optimización ####
#################################################

m = Model(GLPK.Optimizer)

# Variables 
@variable(m, PROCESO[REFINERIA, CRUDO] >= 0)            # Crudo por tipo procesado en la refinería
@variable(m, DESTIPRIM[REFINERIA, MODOPER, CRUDO] >=0)  # Proceso de crudo por modo de operación
@variable(m, PRODUCCION[REFINERIA, PRODUCTO] >=0)   	# Producción de petrolíferos en refinería
@variable(m, USOCAP[REFINERIA, PLANTA] >=0 )    		# Capacidad utilizada de plantas en refinería
@variable(m, LAMBDA[REFINERIA, MODOPER], Int)   		# Modo de operación
@variable(m, INGRESO[REFINERIA])             			# Ventas a puerta de refinería
@variable(m, EGRESO[REFINERIA])                         # Costo de producción en refinería
@variable(m, INGRESOTOT)                                # Ingresos totales
@variable(m, EGRESOTOT)                                 # Egresos totales


# Función objetivo 
@objective(m, Max, INGRESOTOT - EGRESOTOT )

# Resctricciones
@constraint(m, TOTING, INGRESOTOT == sum(INGRESO[r] for r in REFINERIA))
@constraint(m, TOTEGR, EGRESOTOT == sum(EGRESO[r] for r in REFINERIA))
@constraint(m, VENTAS[r in REFINERIA], INGRESO[r] == sum(PRODUCCION[r,p] * PRECIOPRO[r,p] for p in PRODUCTO))
@constraint(m, COMPRAS[r in REFINERIA], EGRESO[r] == sum(PROCESO[r,c] * PRECIOCRU[r,c] for c in CRUDO))

# Proceso de crudo
@constraint(m, PROCRU[r in REFINERIA, c in CRUDO], PROCESO[r,c] == sum(DESTIPRIM[r,l,c] for l in MODOPER))
# Mínimo crudo pesado
@constraint(m, MNPES[r in REFINERIA], PROCESO[r, "MAY"] >= MINPES[r] * sum(PROCESO[r, c] for c in CRUDO))
# Máximo crudo pesado
@constraint(m, MXPES[r in REFINERIA], PROCESO[r, "MAY"] <= MAXPES[r] * sum(PROCESO[r, c] for c in CRUDO))
# Producción
@constraint(m, RENDIM[r in REFINERIA, p in PRODUCTO], PRODUCCION[r,p] == sum(DESTIPRIM[r, l, c] * YIELDS[r, l, c, p] for l in MODOPER, c in CRUDO))
# Capacidad utilizada
@constraint(m, KAPAC[r in REFINERIA, f in PLANTA], USOCAP[r,f] == sum(DESTIPRIM[r, l, c] * USOPLAN[r, l, c, f] for l in MODOPER, c in CRUDO))
@constraint(m, KAPMAX[r in REFINERIA, f in PLANTA], USOCAP[r,f] <= CAPAMAX[r,f])
# Control de modo de operación
@constraint(m, MOPER[r in REFINERIA, l in MODOPER], sum(DESTIPRIM[r,l,c] for c in CRUDO) <= LAMBDA[r,l] * CAPAMAX[r, "ATM"])
@constraint(m, MOUNICO[r in REFINERIA], sum(LAMBDA[r,l] for l in MODOPER) == 1)

# Escritura Modelo de Optimización
print(m)

##### Solución del modelo de optimización ####
##############################################

# Solución Modelo Optimización
JuMP.optimize!(m)

# Escritura Solución Óptima
println("Soluciones Óptimas:")
println("Objective value: ", JuMP.objective_value(m))
println("PROCESO: ", JuMP.value.(PROCESO))
println("DESTIPRIM: ", JuMP.value.(DESTIPRIM))
println("PRODUCCION: ", JuMP.value.(PRODUCCION))
println("USOCAP: ", JuMP.value.(USOCAP))
println("LAMBDA: ", JuMP.value.(LAMBDA))
println("EGRESO: ", JuMP.value.(INGRESO))
println("INGRESO: ", JuMP.value.(EGRESO))
println("INGRESO TOTAL: ", JuMP.value.(INGRESOTOT))
println("INGRESO TOTAL: ", JuMP.value.(EGRESOTOT))
