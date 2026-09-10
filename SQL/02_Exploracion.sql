	-- Deteccion de duplicados por la combinacion de las columnas [id] y [tender items 0 id]
	with dupli as
	(select 
		ROW_NUMBER() over (partition by [id], [tender items 0 id] order by [id]) as duplicados
	from licitacion
	where [tag] = 'tender;award;contract'
	)

	select count(*) as Cantidad_duplicados from dupli where duplicados > 1; 
		-- RESPUESTA: hay 0 duplicados.

	
-- (eliminar redundancia) Analizo las columnas y elimino aquellas que son redundantes o improductivas para nuestro objetivo.
select distinct(initiationType) from licitacion; -- solo existe "tender"
select distinct(tag) from licitacion; -- existe "tender" o "tender;award;contract" (nos sirve "tender;award;contract")
select distinct([tender items 0 unit scheme]) from licitacion -- solo existe "x_unidades_medida_bac"
select distinct([tender items 0 classification scheme]) from licitacion; -- solo existe "x_catalogo_bienes_servicios_bac"


-- (busqueda de duplicados) Buscamos duplicados en la tabla LICITACION 

	-- Deteccion de duplicados por la columna [id]
	with dupli as
	(select 
		ROW_NUMBER() over (partition by [id] order by [id]) as duplicados
	from licitacion
	where [tag] = 'tender;award;contract'
	)

	select 
		count(*) as Cantidad_duplicados
	from dupli
	where duplicados > 1; 
		-- RESPUESTA: hay 1294 registros que son duplicados


-- Cuento la cantidad de registros que quiero modificar al valor "Unidad"
	select
		count(*) as cantidad_a_cambiar
	from adjudicacion_n
	where item_tipodeunidad in ('UNIDAD', 'U', 'UNIDAD x 1u', 'UNIDADES', 'UNIDAD x 1 x 1 UNIDADES'); 


-- ¿Tienen correspondencia los montos con el tipo de moneda? Para responder esto, vamos a evaluar la diferencia porcentual entre el monto presupuestado y el monto gastado 
	with procesos_moneda_extrajera as(
		select id_proc_compra from LIC where moneda in ('USD','EUR')
		UNION
		select id_proc_compra from ADJ where moneda in ('USD','EUR')
	)
	select
		p.*,
		cast((p.monto_ADJ - monto_LIC) / monto_LIC * 100 as decimal(18,3)) as diferencia_porcentual
	from proc_de_compra p
	where exists(
		select
			1
		from procesos_moneda_extrajera pme
		where pme.id_proc_compra = p.id_proc_compra
		)
	order by diferencia_porcentual asc;
	/* RESPUESTA: encontramos que la mayoria tiene una diferencia porcentual mayor a -90%. Si bien no es suficiente para determinar que los datos son erroneos (ya que muchos valores en pesos argentinos tambien mantienen
		una diferencia porcentual extrema) vamos a investigar manualmente algunos procesos de compra, comparandolos con los valores de los pliegos de los procesos de compra

	Luego de evaluar 14 procesos de compra, creemos que lo mas optimo es eliminar los procesos de compra que tengan valores de moneda extranjera para evitar sesgos por datos pocos fidedignos.
	Pero antes vamos a consultar la cantidad de procesos de compra que vamos a eliminar 
	*/

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

	/*
	- 349 procesos de compra con al menos una fila con valor de MONEDA EXTRANJERA
	- 47296 procesos con moneda nacional
	- 47333 procesos de compra 
	Vamos a eliminar 0,73% de la cantidad total de procesos de compra
	*/

				 
-- Busco paridad entre las columnas "descripcion" de las tablas LIC y ADJ
	select distinct
		lic.descripcion,
		adj.descripcion
	from LIC
	inner join ADJ
		on lic.id = adj.id
	where lic.descripcion != adj.descripcion; 
	-- RESPUESTA: observo que en la tabla ADJ, hay detalles adicionales


-- Quiero observar si hay diferencias entre los valores referidos a los tipos de items de las tablas LIC y ADJ 
	select distinct
		lic.item_tipodeunidad,
		adj.item_tipodeunidad
	from LIC
	inner join ADJ
		on lic.id = adj.id
	where lic.item_tipodeunidad != adj.item_tipodeunidad; 


-- creamos una vista para visualizar que grado porcentual de incidencia tienen las categorias en las brechas presupuestarias
create view incidencia_en_brecha_por_categoria as 

	with brecha_p as(
	select
		id_proc_compra
	from proc_de_compra
	where cast((monto_LIC - monto_ADJ) / monto_LIC * 100 as decimal(18,3)) <= -100
	), -- Procesos de compra con una brecha presupuestaria menor a -100%
	totales_por_cat as(
	select
		lic.categoria_det,
		count(distinct(lic.id_proc_compra)) as cantidad_total
	from LIC
	group by lic.categoria_det
	), -- Agrupo los procesos de compra en las categorias
	afectados_por_categoria as(
	select
		lic.categoria_det,
		count(distinct(b.id_proc_compra)) as cantidad_afectada
	from brecha_p b
	left join LIC
		on b.id_proc_compra = lic.id_proc_compra
	group by categoria_det
	) -- agrupo los procesos de compra con brecha presupuestaria alta según la categoría
		select
		t.categoria_det,
		t.cantidad_total,
		coalesce(a.cantidad_afectada, 0) as cantidad_con_brecha,
		cast(coalesce(a.cantidad_afectada, 0) * 100  / t.cantidad_total as decimal (18,2)) as porcentaje_incidencia
	from totales_por_cat t
	left join afectados_por_categoria a
		on t.categoria_det = a.categoria_det
	;
				
	select 
		top 10 * 
	from incidencia_en_brecha_por_categoria
	order by porcentaje_incidencia desc;

	-- observamos que: "Reservado para GCBA" es el área con un valor de brecha porcentual mas alto, con  %12.00 de sus licitaciones con una brecha presupuestaria desproporcionada


-- creamos una vista para visualizar los grados porcentuales de incidencias de los metodos de adquisicion en las brechas presupuestarias.
create view incidencia_en_brecha_metodo_adquisicion as

	with brecha_p as(
		select
			id_proc_compra
		from proc_de_compra
		where cast((monto_LIC - monto_ADJ) / monto_LIC * 100 as decimal(18,3)) <= -100
	),
	totales_por_cat as(
		select
			lic.metodo_adquisicion_det,
			count(distinct(lic.id_proc_compra)) as cantidad_total
		from LIC
		group by lic.metodo_adquisicion_det
	),
	afectados_por_categoria as(
		select
			lic.metodo_adquisicion_det,
			count(distinct(b.id_proc_compra)) as cantidad_afectada
		from brecha_p b
		left join LIC
			on b.id_proc_compra = lic.id_proc_compra
		group by metodo_adquisicion_det
	)
	select
		t.metodo_adquisicion_det,
		t.cantidad_total,
		coalesce(a.cantidad_afectada, 0) as cantidad_con_brecha,
		cast(coalesce(a.cantidad_afectada, 0) * 100  / t.cantidad_total as decimal (18,2)) as porcentaje_incidencia
	from totales_por_cat t
	left join afectados_por_categoria a
		on t.metodo_adquisicion_det = a.metodo_adquisicion_det;
				
	select 
		top 10 * 
	from incidencia_en_brecha_metodo_adquisicion
	order by porcentaje_incidencia desc;

	/* observamos que:
		"CONTRATACION MENOR" es el metodo de adquisicion con un valor porcentual mas alto, con  %9.00 de sus licitaciones con una brecha presupuestaria desproporcionada.
		utilizamos este recurso de Vista para tener un panorama de este tipo de incidencia, se tratara mas especificamente en el dashboard mas adelante
	*/

