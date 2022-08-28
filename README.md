
# Refactorización Optimización Refinería de Cadereyta (RORC)

En este repositorio se encuentra la refactorización del modelo de pre-optimización de la refineria de Cadereyta, __refac_preoptirefs.jl__ 

El modelo de pre-optimización original, __03_PreOPtiRefs.mod__,  fue diseñado e implentado en GUSEK por __Dr. Rafael García Jolly__ (Junio 27, 2022), el modelo utiliza datos del cubo de la refinería elaborado por __Jonathan Grimaldo__.

La refactorización del código original fue hecha en Julia v1.7.2 , utiliza el pquete de modelado de optimización matemática JuMP v1.1.1 y el solver GLPK v1.0.1

El respositorio contiene:
- refac_preoptirefs.jl
- 03_PreOPtiRefs.mod
- refac_PreOptiRefs_v1.0.out
- /data/CapaMax.csv
- /data/MaxPes.csv
- /data/PrecioCru.csv
- /data/precioprod.csv
- /data/UsoPlan.csv
- /data/Yields.csv

Para ejecutar el código desde la terminal se utiliza:
<pre><code>$ julia refac_preoptirefs.jl 
</code></pre>

En el archivo __refac_PreOptiRefs_v1.0.out__ puede consultarse la configuración y solución del modelo para los datos proporcionados en __/data__.
