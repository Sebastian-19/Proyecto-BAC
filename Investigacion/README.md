
### Investigación sobre la correspondencia de los datos con moneda extranjera
En el proceso de la validación de la fidelidad de mis datos, observo que hay renglones en donde no hay correlacion entre los tipos de moneda de la licitación y la adjudicación.

Es por eso que realizo una investigación manual, comparando mis datos con los datos de las documentaciones oficiales de los procesos de compra pertinentes (investigación: "Correlación de montos, DB vs Pliegos.pdf" )

Finalizada la investigación, observamos varios errores de correlacion entre los datos de monedas en mis datos y en la informacion de los pliegos de los procesos de compra.
 Los errores provienen de varios factores, dificultando mucho la corrección de estos, siendo que no tenemos certezas de que datos están bien, y cuales están mal, **nos hacemos las siguientes preguntas:**
 - ¿La cantidad de procesos de compra con moneda extranjera es relevante en cuestión de la cantidad total de procesos de compra? 
```sql
 	select
		count(distinct(lic.id_proc_compra)) as cant_procdecompra,
		'moneda extranjera' as descripcion
	from LIC
	left join ADJ
		on lic.id = adj.id
	where lic.moneda in ('USD', 'EUR')
		or adj.moneda in ('USD', 'EUR')
	union
	select
		count(distinct(lic.id_proc_compra)),
		'moneda nacional'
	from LIC
	left join ADJ
		on lic.id = adj.id
	where lic.moneda not in ('USD', 'EUR')
		or adj.moneda not in ('USD', 'EUR')
	union
	select
		count(distinct(id_proc_compra)),
		'total procesos de compra'
	from proc_de_compra;
```
	 349 procesos de compra con al menos un renglon con valor de moneda extranjera
	 47296 procesos de compra unicamente de moneda nacional
	 47333 procesos de compra 
Los procesos de compra con al menos un valor de moneda extranjera representa solamente el **0,73% de la cantidad total de procesos de compra**


 - ¿Hay solución aparente para corregir esta falta de correlatividad de los datos?
 
	No, según la investigación, no se observa ningún patrón o falla sistematica en estos 		datos como para poder corregirlos.

 - ¿Tenemos la fecha exacta para hacer las conversiones de moneda?

	No, no contamos con las fechas de referencia para la conversión de las divisas.
 
 
**Conclusión:** Luego de comprobar que no podemos resolver los errores de estos datos, y teniendo en cuenta que representan un porcentaje por debajo del 1% respecto a la cantidad total de procesos de compra, **procedemos a eliminarlos del datawarehouse para evitar sesgos en los analisis por datos que no son fidedignos.** 
``` sql
delete LIC 
from LIC 
inner join proc_compra_eliminar p 
	on lic.id_proc_compra = p.id_proc_compra; -- 1325 filas eliminadas

delete ADJ 
from ADJ
inner join proc_compra_eliminar p
	on adj.id_proc_compra = p.id_proc_compra; -- 1325 filas eliminadas

delete p
from proc_de_compra p
inner join proc_compra_eliminar pce
	on p.id_proc_compra = pce.id_proc_compra; -- 349 filas eliminadas
```
				