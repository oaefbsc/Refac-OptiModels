
# Refactorización del modelo para pruebas de desempeño de motores de optimización 

En este repositorio se encuentra la refactorización del modelo pruebas de desempeño de motores de optimización, __refac_prototipo_01.jl__ 

El modelo original fue diseñado e implentado en GUSEK por __Dr. Rafael García Jolly__ en Julio 27, 2022. El modelo incluye 2 refinerías con coquizadora, 3 crudos, 4 productos,
3 mercados + comercio exterior

La refactorización del código original fue hecha en Julia v1.7.2 , utiliza el paquete de modelado de optimización matemática JuMP v1.1.1 y el solver GLPK v1.0.1

El respositorio contiene:
- refac_prototipo_01.jl
- refac_prototipo_01.out

Para ejecutar el código desde la terminal se utiliza:
<pre><code>$ julia refac_prototipo_01.jl 
</code></pre>

En el archivo __refac_prototipo_01.out__ puede consultarse la configuración y solución del modelo.
