-- (eliminar redundancia). ¿[ocid] es igual a [id] solo que suma el prefijo "ocds-bulbcf-"?

	-- creo la tabla id2 y le inserto los datos normalizados para poder comparar y corroborar mi pregunta.
	alter table licitacion
		add id2 nvarchar(100);

	update licitacion
		set id2 = REPLACE([ocid], 'ocds-bulbcf-', '')


	select id, id2 from licitacion where id != id2; 
	
-- NO DEBERIA HABER DUPLICADO en los registros bajo la combinacion de las columnas [id] y [tender items 0 id]
	with dupli as
	(select 
		ROW_NUMBER() over (partition by [id], [tender items 0 id] order by [id]) as duplicados
	from licitacion
	where [tag] = 'tender;award;contract'
	)

	select count(*) as Cantidad_duplicados from dupli where duplicados > 1; 
	-- RESPUESTA: confirmado, no hay duplicados


-- ¿hay mas de una descripcion en el mismo proceso de compra?

	select
		[id_item_clasificacion],
		count(distinct [item_descripcion]) as descripciones_distintas
	from licitacion
	group by [id_item_clasificacion]
	having count(distinct [item_descripcion]) > 1; 
	-- RESPUESTA: no, no hay mas de una descripcion por proceso de compra


-- Verifico que las relaciones entre las tablas sean correctas.

	-- Adjudicacion <--> item
	select
	(select
		count(adj.id_item_clasificacion) as cantidad
	from items
	left join adjudicacion adj
		on items.id_item_clasificacion = adj.id_item_clasificacion
	where adj.id_item_clasificacion is null
	) as items_sin_relacion,
	(select
		count(items.id_item_clasificacion) as cantidad
	from adjudicacion adj
	left join items
		on adj.id_item_clasificacion = items.id_item_clasificacion
	where items.id_item_clasificacion is null
	) as adjudicacion_sin_relacion;
	-- RESPUESTA: La relacion es correcta.


-- ¿En la tabla licitacion, los valores de [monto] varían en el mismo [id]? 
	with cte as(
	select distinct 
		id,
		monto
	from licitacion
	)
	select
	(select count(distinct(id)) from licitacion) as id_distintos,
	(select count(*) from cte) as id_monto_distinto,
	(select count(distinct(id)) from licitacion) - (select count(*) from cte) as repetidos;
	-- RESPUESTA: No, los montos no cambian en el mismo identificador [id]


-- ¿Hay valores 0 en las columnas [monto] o [item_valorXu]?
	select
		COUNT(*) as cantidad_0
	from licitacion
	where 
		monto = 0
		or
		item_valorXu = 0; 
	-- RESPUESTA: no hay valores igual a 0 en estos campos


-- ¿Corresponde el valor total gastado con el resultado de multiplicar la cantidad de items por el valor del item? 
	select
		count(distinct(id)) as No_correlacion
	from adjudicacion_n
	where round(item_cantidad * item_valorXu, 2) != monto;
	-- RESPUESTA: 22594 identificadores distintos sin correlacion. Esto es negativo y demuestra un claro error en los datos


/*
HIPOTESIS:	Cuando se cargan los registros de prorrogas o ampliaciones de contrato en la tabla adjudicacion, los valores de [monto] no se actualizan, mantienen el valor del contrato original. 
			En consecuencia decidimos comprobar en algunos procesos de compra si el resultado de multiplicar [item_cantidad] por [item_valorXu] correspondencia con los valores de los pliegos de los procesos de compra.
			Hay correspondencia. 

			Siguiendo la logica de la hipotesis, voy a consultar si en los mismos renglones de compra en donde no hay igualdad entre [monto] y [monto_total], SÍ hay otro renglon en que coincidan estos valores
*/
	with no_corr as(
	select distinct
		id
			from adjudicacion_n
			where monto <> monto_total
	)
	select
		count(distinct(adj.id)) as ids
	from adjudicacion_n adj
	join no_corr
		on adj.id = no_corr.id
	where monto = monto_total; 
	-- RESPUESTA: hay 22592 identificadores que tienen desigualdad e igualdad entre sus valores de [monto] y [monto_total].

	/* CONCLUSION:
		de 22594 renglones de compra con irregularidades en los valores de gasto, hay 22592 que tienen al menos un renglon en el que SI coinciden los valores de gasto.
		Con este analisis podemos determinar que la HIPOTESIS ES CORRECTA
	*/

		
-- Consulto la cantidad de procesos de compra que debo eliminar de mi tabla proc_de_compra
	select(
		select
			count(*)
		from proc_de_compra p
		where exists(
			select
				id_proc_compra
			from lic l
			where l.id_proc_compra = p.id_proc_compra
			)
		) as 'Registros que permanecen',
		(
		select
			count(*)
		from proc_de_compra p
		where not exists(
			select
				id_proc_compra
			from lic l
			where l.id_proc_compra = p.id_proc_compra
			)
		) as 'Registros que NO permanecen'

-- Buscamos que no haya inconsistencias en el tipo de moneda de un mismo proceso de compras. Lo aplicamos en ambas tablas
	select
		id_proc_compra,
		count(distinct moneda) as cant_distinta
	from LIC
	group by id_proc_compra
	having count(distinct moneda) > 1;

	select
		id_proc_compra,
		count(distinct moneda) as cant_distinta
	from ADJ
	group by id_proc_compra
	having count(distinct moneda) > 1;
	--RESPUESTA: observamos que en la tabla LIC no hay inconsistencias. En tabla ADJ hay dos procesos de compra que tienen dos valores distintos respectivamente


-- Resuelvo los ultimos detalles antes de terminar mi modelado

	-- ¿varian los valores de categoría y categoria_det dentro del mismo proceso de compra?
	with variantes_mismo_procdecompra as
	(
		select
			id_proc_compra,
			categoria,
			categoria_det,
			ROW_NUMBER() over (partition by id_proc_compra order by id_proc_compra) as cant
		from lic
		group by 
			id_proc_compra,
			categoria,
			categoria_det
	)
	select
		count(distinct id_proc_compra) as procesos_de_compra,
		'con variantes' as cantidad
	from variantes_mismo_procdecompra
	where cant > 1
	union
	select
		count(id_proc_compra),
		'total'
	from proc_de_compra; 
	-- RESPUESTA: hay al menos 1954 procesos de compra en donde varian los valores de [categoria] y/o [categoria_det]. Esto se puede deber al hecho de que en algunas licitaciones se solicitan items de diferente indole o categoría


	-- ¿varian los valores [metodo_adquisicion] y [metodo_adquisicion_det] dentro del mismo proceso de compra?
	with variantes_mismo_procdecompra as
	(
		select
			id_proc_compra, 
			metodo_adquisicion,
			metodo_adquisicion_det,
			ROW_NUMBER() over (partition by id_proc_compra order by id_proc_compra) as cant
		from lic
		group by 
			id_proc_compra, 
			metodo_adquisicion,
			metodo_adquisicion_det
	)
	select
		count(distinct id_proc_compra) as procesos_de_compra,
		'con variantes' as cantidad
	from variantes_mismo_procdecompra
	where cant > 1
	union
	select
		count(id_proc_compra),
		'total'
	from proc_de_compra; 
	-- RESPUESTA: no existen variantes en los valores de las columnas [metodo_adquisicion] y [metodo_adquisicion_det] dentro del mismo proceso de compra, se debe a que cada licitacion tiene una sola forma de adjudicarse


	-- ¿varian las entidades contratantes dentro del mismo proceso de compra?
	with variantes_mismo_procdecompra as
	(
		select
			id_proc_compra, 
			id_ent_contrat,
			ROW_NUMBER() over (partition by id_proc_compra order by id_proc_compra) as cant
		from lic
		group by 
			id_proc_compra,
			id_ent_contrat
	)
	select
		count(distinct id_proc_compra) as procesos_de_compra,
		'con variantes' as cantidad
	from variantes_mismo_procdecompra
	where cant > 1
	union
	select
		count(id_proc_compra),
		'total'
	from proc_de_compra; 
	-- RESPUESTA: no existen diferentes contratantes en un mismo proceso de compra

	/* 
	Con la informacion que recolectamos, comprendemos mejor el comportamiento de las licitaciones y como se comportan los segmentos de la misma.
	Gracias a estas consultas podemos optimizar aun mas nuestra base de datos, eliminando redundancia y teniendo los datos mas limpios y organizados.
	Las columnas de la tabla lic: [metodo_adquisicion], [metodo_adquisicion_detalle] y [id_ent_contrat] van a ser exportadas a la tabla proc_de_compra
	Las columnas de la tabla lic: [categoria] y [categoria_det] van a ser exportadas a la tabla renglon
	*/
