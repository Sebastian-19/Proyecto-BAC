-- creamos una vista para visualizar los grados porcentuales de incidencias de las categorias en las brechas presupuestarias.

create view incidencia_en_brecha_categoria as 

	with brecha_p as(
	select
		id_proc_compra
	from proc_de_compra
	where cast((monto_LIC - monto_ADJ) / monto_LIC * 100 as decimal(18,3)) <= -100
	),
	totales_por_cat as(
	select
		lic.categoria_det,
		count(distinct(lic.id_proc_compra)) as cantidad_total
	from LIC
	group by lic.categoria_det
	),
	afectados_por_categoria as(
	select
		lic.categoria_det,
		count(distinct(b.id_proc_compra)) as cantidad_afectada
	from brecha_p b
	left join LIC
		on b.id_proc_compra = lic.id_proc_compra
	group by categoria_det
	)
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
	from incidencia_en_brecha_categoria
	order by porcentaje_incidencia desc;

	/* observamos que:
		"Reservado para GCBA" es el área con un valor porcentual mas alto, con  %12.00 de sus licitaciones con una brecha presupuestaria desproporcionada.
		utilizamos este recurso de Vista para tener un panorama de este tipo de incidencia, se tratara mas especificamente en el dashboard mas adelante
	*/


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


-- Elimino los caracteres numericos y los guiones a los valores de mi columna [descripcion_limpia]
	while exists(
			select 1
			from LIC
			where PATINDEX('%[0-9-]%', descripcion_limpia) > 0
	)
	begin
		update LIC
		set descripcion_limpia = TRIM(
			STUFF(
				descripcion_limpia,
				PATINDEX('%[0-9-]%', descripcion_limpia),
				1,
				''
			)
		)
		where PATINDEX('%[0-9-]%', descripcion_limpia) > 0;
	END;

