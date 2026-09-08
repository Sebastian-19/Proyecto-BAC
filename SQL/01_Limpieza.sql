-- Elimino las columnas sin utilidad ([ocid] y [id2])
	alter table licitacion
	drop column ocid, id2;

	alter table licitacion
	drop column [initiationType], [language], [tender items 0 unit scheme], [tender items 0 classification scheme], [tender documents 0 id], [tender documents 0 documentType], 
		[tender documents 0 url], [tender documents 0 datePublished], [tender documents 0 language];


-- Modifico los valores de la columna id
	alter table adjudicacion
	add id2 nvarchar(100);

	update adjudicacion
		set id2 = REPLACE([ocid], 'ocds-bulbcf-', '');

	-- Cambio el nombre de la columna
	exec sp_rename 'adjudicacion.[id2]','id';


-- Elimino la columna ocid
alter table adjudicacion
drop column ocid;


/* 
	(Creacion de tablas)
	Creo las tablas nueva_lic y nueva_adj. Tablas derivadas de las tablas licitacion y adjudicacion respectivamente, pero obteniendo los registros que tengan conexion entre las dos tablas
	a través de la clave combinada (identificador del renglon + identificador del item)
*/
	with nuevo as
	(
	select
		lic.*
	from licitacion lic
	join adjudicacion adj
		on lic.id = adj.id
		and lic.[tender items 0 id] = adj.[awards 0 items 0 id]
	)

	select * into nueva_lic from nuevo;

	with nuevo as
	(
	select
		adj.*
	from adjudicacion adj
	join licitacion lic
		on adj.id = lic.id
		and adj.[awards 0 items 0 id] = lic.[tender items 0 id]
	)

	select * into nueva_adj from nuevo; 

-- Cambio de nombres las tablas
	exec sp_rename 'adjudicacion', 'ORIGINAL_adj';
	exec sp_rename 'licitacion', 'ORIGINAL_lic';
	exec sp_rename 'nueva_lic', 'licitacion';
	exec sp_rename 'nueva_adj', 'adjudicacion';

-- Elimino columnas
	alter table licitacion
	drop column [tender status], [tender tenderPeriod startDate], [tender tenderPeriod endDate], [tender tenderPeriod durationInDays], [tender enquiryPeriod startDate],
		[tender enquiryPeriod durationInDays], [tag],[tender techniques frameworkAgreement method], [tender techniques hasFrameworkAgreement], [tender competitive];

-- Elimino valores iguales a '0.0'
	delete from adjudicacion
		where exists(
			select 1
			from licitacion 
			where 
				licitacion.id = adjudicacion.id
				and
				licitacion.[tender value amount] = '0.0'
			)
	;

	delete from licitacion
		where licitacion.[tender value amount] = '0.0'
	;

-- Renombro las columnas de la tabla licitacion.
	exec sp_rename 'licitacion.date', 'fecha';
	exec sp_rename 'tender enquiryPeriod endDate', 'fecha_cierredelicitacion';
	exec sp_rename 'licitacion.tender id', 'id_proc_compra';
	exec sp_rename 'licitacion.tender title', 'titulo';
	exec sp_rename 'licitacion.tender description', 'descripcion';
	exec sp_rename 'licitacion.tender procuringEntity id', 'id_ent_contr';
	exec sp_rename 'licitacion.tender value currency', 'moneda';
	exec sp_rename 'licitacion.tender value amount', 'monto';
	exec sp_rename 'licitacion.tender procuringEntity name', 'nombre_entidad';
	exec sp_rename 'licitacion.tender procurementMethod', 'metodo_adquisicion';
	exec sp_rename 'licitacion.tender procurementMethodDetails', 'metodo_adquisicion_detalle';
	exec sp_rename 'licitacion.tender mainProcurementCategory', 'categoria';
	exec sp_rename 'licitacion.tender additionalProcurementCategories', 'categoria_detalle';
	exec sp_rename 'licitacion.tender items 0 id', 'id_item';
	exec sp_rename 'licitacion.tender items 0 description', 'item_descripcion';
	exec sp_rename 'licitacion.tender items 0 quantity', 'item_cantidad';
	exec sp_rename 'licitacion.tender items 0 unit name', 'item_tipodeunidad';
	exec sp_rename 'licitacion.tender items 0 classification id', 'id_item_clasificacion';
	exec sp_rename 'licitacion.tender items 0 unit value amount', 'item_valorXu';
	exec sp_rename 'licitacion.tender items 0 unit value currency', 'item_moneda';

-- Estandarizacion de datos, tabla licitacion
	-- columna [fecha]
	select 
		LEFT(fecha, CHARINDEX('T', fecha) - 1) as reemplazo
	from licitacion;

	update licitacion set fecha = LEFT(fecha, CHARINDEX('T', fecha) - 1);

	-- columna [metodo_adquisicion]
	select
		distinct(metodo_adquisicion) as variantes
	from licitacion;

	update licitacion set metodo_adquisicion = case 
													when metodo_adquisicion = 'direct' then 'directo'
													when metodo_adquisicion = 'open' then 'abierto'
													when metodo_adquisicion = 'limited' then 'limitado'
												end;
	-- columna [categoria]
	select
		distinct(categoria) as variantes
	from licitacion;

	update licitacion set categoria = case 
											when categoria = 'goods' then 'bienes'
											when categoria = 'services' then 'servicios'
											when categoria = 'works' then 'trabajos'
										end;

	-- columna [fecha_cierredelicitacion]
	update licitacion set fecha_cierredelicitacion = LEFT(fecha_cierredelicitacion, charindex('T',fecha_cierredelicitacion) - 1);


-- Elimino columnas de la tabla adjudicacion
	alter table adjudicacion
	drop column [awards 0 contractPeriod startDate], [awards 0 contractPeriod endDate], [awards 0 contractPeriod durationInDays], [awards 0 documents 0 id], [awards 0 documents 0 documentType], [awards 0 documents 0 url], [awards 0 documents 0 datePublished], [awards 0 documents 0 language], [awards 0 suppliers 0 name], [awards 0 suppliers 0 id], [awards 0 status], [awards 0 items 0 classification scheme], [awards 0 items 0 unit scheme];

-- Renombro las columnas de la tabla adjudicacion
	exec sp_rename 'adjudicacion.awards 0 id', 'id_proc_compra';
	exec sp_rename 'adjudicacion.awards 0 title', 'titulo';
	exec sp_rename 'adjudicacion.awards 0 description', 'descripcion';
	exec sp_rename 'adjudicacion.awards 0 date', 'fecha';
	exec sp_rename 'adjudicacion.awards 0 value amount', 'monto';
	exec sp_rename 'adjudicacion.awards 0 value currency', 'moneda';
	exec sp_rename 'adjudicacion.awards 0 items 0 id', 'id_item';
	exec sp_rename 'adjudicacion.awards 0 items 0 description', 'item_descripcion';
	exec sp_rename 'adjudicacion.awards 0 items 0 classification id', 'id_item_clasificacion';
	exec sp_rename 'adjudicacion.awards 0 items 0 quantity', 'item_cantidad';
	exec sp_rename 'adjudicacion.awards 0 items 0 unit name', 'item_tipodeunidad';
	exec sp_rename 'adjudicacion.awards 0 items 0 unit value amount', 'item_valorXu';
	exec sp_rename 'adjudicacion.awards 0 items 0 unit value currency', 'item_moneda';

-- Estandarizacion de datos, tabla adjudicacion
		
	-- columna [fecha]
	select 
		LEFT(fecha, CHARINDEX('T', fecha) - 1) as reemplazo
	from adjudicacion;

	update adjudicacion set fecha = LEFT(fecha, CHARINDEX('T', fecha) - 1);

-- Creo la tabla items
	create table items (
		id_item_clasificacion nvarchar(25),
		descripcion nvarchar(max));

	-- Inserto los registros
	insert into items ([id_item_clasificacion], [descripcion])
	select DISTINCT
		[id_item_clasificacion],
		[item_descripcion]
	from licitacion;
		
	-- Elimino la columna [item_descripcion] de la tabla licitacion.
	alter table licitacion
	drop column [item_descripcion];


-- Creo la tabla proc_de_compra
	create table proc_de_compra(
		id_proc_compra nvarchar(20) NOT NULL,
		titulo nvarchar(250),

		constraint PK_procesodecompra
		primary key (id_proc_compra)
		);

	-- Inserto los registros
	insert into proc_de_compra(id_proc_compra,titulo)
	select DISTINCT
		[id_proc_compra],
		[titulo]
	from licitacion;

	-- Elimino la columna [titulo] de la tabla licitacion
	alter table licitacion
	drop column titulo;


-- Creo la tabla entidad_contratante
	create table entidad_contratante(
		id_ent_contr nvarchar(40) NOT NULL,
		nombre_entidad nvarchar(100),
		
		constraint PK_entidad
		primary key (id_ent_contr)
		);
	
	-- inserto los registros
	insert into entidad_contratante(id_ent_contr,nombre_entidad)
	select DISTINCT
		id_ent_contr,
		nombre_entidad
	from licitacion;

	-- elimino columna licitacion.nombre_entidad

	alter table licitacion
	drop column nombre_entidad;


-- Elimino la columna [item_descripcion]
alter table adjudicacion
drop column item_descripcion;


-- Elimino la columna [titulo]
alter table adjudicacion
drop column titulo;
		
	
-- (cambio datatype) Cambio los datatype de las columnas [monto], [item_cantidad], [item_valorXu] en la tabla licitacion
	alter table licitacion
	alter column monto DECIMAL(14,2);
	alter table licitacion
	alter column item_cantidad DECIMAL(11,2);
	alter table licitacion
	alter column item_valorXu DECIMAL(13,2);

	-- creo la columna nueva [valorXu]
	alter table licitacion
	add valorXu DECIMAL(14,2);

	-- inserto los datos en [valorXu]
	update licitacion set valorXu = cast(item_cantidad * item_valorXu as decimal(14,2));


-- (cambio datatype) Cambio los datatype de las columnas [monto], [item_cantidad], [item_valorXu] en la tabla adjudicacion
	alter table adjudicacion
	alter column monto DECIMAL(14,2);
	alter table adjudicacion
	alter column item_cantidad DECIMAL(11,2);
	alter table adjudicacion
	alter column item_valorXu DECIMAL(13,2);

	-- creo la columna nuevas [valorXu]
	alter table adjudicacion
	add valorXu DECIMAL(14,2);

	-- inserto los datos en [valorXu]
	update adjudicacion
	set valorXu = cast(item_cantidad * item_valorXu as decimal(14,2));


-- Elimino procesos de compra con valores erroneos		
	delete from adjudicacion_n
		where id_proc_compra in ('414-0950-LPU18', '8056-1645-LPU17'); -- 35 filas eliminadas

	delete from licitacion
		where id_proc_compra in ('414-0950-LPU18', '8056-1645-LPU17'); -- 35 filas eliminadas


-- Inserto los datos en la tabla adjudicacion_n 
	insert into adjudicacion_n(
		[id],
		[id_proc_compra],
		descripcion,
		fecha,
		monto,
		moneda,
		id_item,
		id_item_clasificacion,
		item_cantidad,
		item_tipodeunidad,
		item_valorXu,
		item_moneda
		)
	select
		id,
		[awards 0 id],
		[awards 0 description],
		[awards 0 date],
		[awards 0 value amount],
		[awards 0 value currency],
		[awards 0 items 0 id],
		[awards 0 items 0 classification id],
		[awards 0 items 0 quantity],
		[awards 0 items 0 unit name],
		[awards 0 items 0 unit value amount],
		[awards 0 items 0 unit value currency]
	from ORIGINAL_adj
	where exists(
		select 
			id
		from licitacion
		where licitacion.id = ORIGINAL_adj.id
				)

	-- elimino la tabla adjudicacion
	drop table adjudicacion;


-- transaccion para eliminar datos de la tabla licitacion
	begin tran;

	with cte as(
	select distinct
		id	
	from adjudicacion_n
	where moneda not in ('USD', 'EUR', 'ARS')
		or item_moneda not in ('USD', 'EUR', 'ARS')
	)
	delete from licitacion
		where id in (select id from cte);

	select @@ROWCOUNT as filas_eliminadas; -- elimina 38681 filas, esta OK.

	commit tran;
				
	-- transaccion para eliminar datos de la tabla adjudicacion_n
	begin tran;

	delete from adjudicacion_n
		where 
			moneda not in ('USD', 'EUR', 'ARS')
			or 
			item_moneda not in ('USD', 'EUR', 'ARS');

	select @@ROWCOUNT as filas_eliminadas; -- elimina 46362 filas, esta OK.

	commit tran;


-- Eliminamos las filas de la tabla licitacion y adjudicacion_n cuando en la tabla adjudicacion_n los valores de [monto] son 0
	-- tabla licitacion
	begin tran;

	delete from licitacion
		where id in(
					select
						id
					from adjudicacion_n
					where 
						monto = 0
						or
						item_valorXu = 0
			);
	
	select @@ROWCOUNT as filas_eliminadas;
	commit tran;

	-- tabla adjudicacion_n
	begin tran;

	delete from adjudicacion_n
		where monto = 0
			or
			item_valorXu = 0

	select @@ROWCOUNT as filas_eliminadas;
	commit tran;

	
-- Eliminamos las filas de la tabla licitacion y adjudicacion_n cuando haya mas de una moneda en el mismo renglon de compra, que solo sucede en la tabla licitacion
			
	-- eliminamos registros de la tabla adjudicacion_n
	begin tran;

	delete from adjudicacion_n
		where exists(
			select
				id
			from licitacion
			where adjudicacion_n.id = licitacion.id
			group by id
			having count(distinct(item_moneda)) > 1
		); 

	select @@ROWCOUNT as filas_eliminadas; -- 21 filas a eliminar en la tabla adjudicacion_n.

	commit tran;
			
	-- eliminamos registros de la tabla licitacion
	begin tran;

	delete from licitacion
		where exists(
			select
				1
			from licitacion x
			where x.id = licitacion.id
			group by id
			having count(distinct(item_moneda)) > 1
				or
				count(distinct(moneda)) > 1
			);
		
	select @@ROWCOUNT as filas_eliminadas; -- 16 filas a eliminar en la tabla licitacion.

	commit tran; 


-- Creo la columna monto_total en la tabla adjudicacion_n
	alter table adjudicacion_n
	add monto_total decimal(14,2);

	update adjudicacion_n set monto_total = item_cantidad * item_valorXu


-- Elimino registros con valores incorrectos
	delete from licitacion
		where id IN ('2051-0909-CME16-1', '2051-0909-CME16-3'); -- 4 filas eliminadas

	delete from adjudicacion_n
		where id IN ('2051-0909-CME16-1', '2051-0909-CME16-3'); -- 10 filas eliminadas


-- Actualizamos los valores de [monto] con los valores de [monto_total] que son los valores correctos. Tabla adjudiacion_n
	begin tran hipot;

	update adjudicacion_n set monto = monto_total;

	select
		count(*) as cant_desigual
	from adjudicacion_n
	where monto != monto_total

	commit tran hipot;

	-- elimino la columna [monto_total]
	alter table adjudicacion_n
	drop column monto_total;


-- Actualizo los valores a 'Unidad'
	begin tran u;

	update adjudicacion_n
	set item_tipodeunidad = case
								when item_tipodeunidad in ('UNIDAD', 'U', 'UNIDAD x 1u', 'UNIDADES', 'UNIDAD x 1 x 1 UNIDADES') then 'Unidad'
								else item_tipodeunidad
							end;

	commit tran u;


-- Estandarizo el campo [fecha] para transformar el datatype a date
	begin tran fecha;

	update adjudicacion_n set fecha = LEFT(fecha, charindex('T', fecha) -1)

	commit tran fecha;

	-- cambio el datatype a date.
	alter table adjudicacion_n
	alter column fecha date; 

-- elimino registros con valores nulos en las columnas de fecha de las tablas licitacion y adjudicacion_n
	delete from licitacion 
		where exists(
			select
				*
			from adjudicacion_n x
			where TRY_CONVERT(date,fecha) is null
			and
			licitacion.id = x.id
		);

	delete from adjudicacion_n
		where exists(
			select
				*
			from adjudicacion_n x
			where TRY_CONVERT(date,fecha) is null
			and
			adjudicacion_n.id = x.id
		);

	-- convierto el datatype a date.
	alter table adjudicacion_n
	alter column fecha date;

-- eliminamos el campo [item_moneda] para evitar redundancia
	alter table adjudicacion_n
	drop column item_moneda;

-- Eliminamos registros en donde hay mas de un valor de item dentro del mismo renglon de compra, ya que debería ser un valor que no varie dentro del mismo renglon de compra
	-- tabla licitacion
	delete from licitacion 
		where exists(
			select
				id
			from adjudicacion_n adj
			where adj.id = licitacion.id
			group by id
			having count(distinct(item_valorXu)) > 1
		); -- 781 registros eliminados

	-- tabla adjudicacion_n
	delete from adjudicacion_n 
		where exists(
			select
				id
			from adjudicacion_n adj
			where adj.id = adjudicacion_n.id
			group by id
			having count(distinct(item_valorXu)) > 1
		); -- 1537 registros eliminados


-- Modifico valores erroneos en la tabla LIC y adjudicacion_n
	update adjudicacion_n set id_item_clasificacion = '07.01.003.0002.3' where id_item_clasificacion = '07.01.003.002.3'; -- 5 registros modificados
	update LIC set id_item_clasificacion = '07.01.003.0002.3' where id_item_clasificacion = '07.01.003.002.3' -- 2 registros modificados

	-- elimino id_item_clasificacion = '07.01.003.002.3' de la tabla 'items'
	delete from items
		where id_item_clasificacion = '07.01.003.002.3'; -- 1 registro modificado


-- Elimino registros sobrantes en mi tabla proc_de_compra. Tomando de referencia los procesos de compra de la tabla LIC 
	begin tran proc_compra

	delete from proc_de_compra
		where not exists(
			select
				id_proc_compra
			from lic l
			where l.id_proc_compra = proc_de_compra.id_proc_compra
			);
	
	select @@ROWCOUNT as cant_permanece; -- se eliminan 7441 registros, es correcto. Realizamos el commit

	commit tran proc_compra;


-- Creo una tabla temporal que voy a utilizar de referencia para eliminar los registros de la tabla licitacion, adjudicacion_n y proc_de_compra con al menos un valor con moneda extranjera 
	select
		distinct lic.id_proc_compra
	into proc_compra_eliminar
	from LIC
	left join ADJ
		on lic.id = adj.id
	where lic.moneda in ('USD', 'EUR')
		or adj.moneda in ('USD', 'EUR')

	-- elimino las filas de las tablas LIC, ADJ y proc_de_compra
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

	-- elimino la tabla temporal proc_compra_eliminar
	drop table proc_compra_eliminar;


-- Estandarizo registros de las tablas entidad_contratante y licitacion
	update entidad_contratante
	set id_ent_contr = 'CABA-UE-2180'
	where id_ent_contr = 'CABA-UE-2180 – MINISTERIO DE GOBIERNO';

	update entidad_contratante
	set nombre_entidad = 'MINISTERIO DE GOBIERNO'
	where id_ent_contr = 'CABA-UE-2180';

	update LIC
	set id_ent_contrat = 'CABA-UE-2180'
	where id_ent_contrat = 'CABA-UE-2180 – MINISTERIO DE GOBIERNO';


-- creo la nueva columna descripcion_detallada
	alter table adj
	add descripcion_detallada nvarchar(200);

	update adj set descripcion_detallada = trim(
											SUBSTRING(
												descripcion,
												CHARINDEX('.', descripcion) + 1,
												len(descripcion)
												)
											);
		
	-- elimino la columna descripcion
	alter table adj
	drop column descripcion;


-- creo la nueva columna [descripcion_limpia], donde voy a copiar los datos de [descripcion] y a normalizarlos.
	alter table lic
	add descripcion_limpia nvarchar(100);

	update LIC set descripcion_limpia = descripcion;


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


-- elimino la columna LIC.[descripcion]
alter table LIC
drop column descripcion;


-- cambio de nombre de la columna [descripcion_limpia] a [descripcion]
exec sp_rename 'lic.descripcion_limpia', 'descripcion';


-- Elimino la columna ADJ.[item_tipodeunidad] 
alter table adj
drop column item_tipodeunidad;





