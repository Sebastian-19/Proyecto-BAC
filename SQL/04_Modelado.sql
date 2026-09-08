use Contratos

-- Creo la tabla items
	create table items (
		id_item_clasificacion nvarchar(25) NOT NULL,
		descripcion nvarchar(max),

		constraint PK_items
		primary key (id_item_clasificacion)
		)


-- Creo la tabla proc_de_compra
	create table proc_de_compra(
		id_proc_compra nvarchar(20) NOT NULL,
		titulo nvarchar(250),

		constraint PK_procesodecompra
		primary key (id_proc_compra)
		);


-- Creo la tabla entidad_contratante
	create table entidad_contratante(
		id_ent_contr nvarchar(40) NOT NULL,
		nombre_entidad nvarchar(100),
		
		constraint PK_entidad
		primary key (id_ent_contr)
		);

-- Creo la tabla adjudicacion_n
create table adjudicacion_n(
	id nvarchar(100) not null,
	id_proc_compra nvarchar(100),
	descripcion nvarchar(1000),
	fecha nvarchar(100),
	monto decimal(14,2),
	moneda varchar(3),
	id_item nvarchar(100) not null,
	id_item_clasificacion nvarchar(100),
	item_cantidad decimal(11,2),
	item_tipodeunidad nvarchar(100),
	item_valorXu decimal(13,2),
	item_moneda varchar(3),
	total_valorXu decimal(14,2)
	)

-- (Tabla deduplicada) Creo la tabla LIC, proveniente de los datos deduplicados de la tabla licitacion

	-- cuento cuantas filas deberia importar a la tabla LIC
	select
		count(distinct(id)) as cant_ids
	from licitacion; -- 212160 filas

	-- creo la tabla LIC
	create table LIC(
		id nvarchar(100) PRIMARY KEY not null,
		descripcion nvarchar(100),
		fecha date,
		monto decimal (14,2),
		moneda varchar (3),
		metodo_adquisicion nvarchar (100),
		metodo_adquisicion_det nvarchar (100),
		categoria nvarchar (100),
		categoria_det nvarchar (100),
		item_cantidad decimal (11,2),
		item_tipodeunidad nvarchar(100),
		item_valorXu decimal (12,2),
		fecha_cierredeLIC date,
		id_proc_compra nvarchar(100),
		id_ent_contrat nvarchar(100),
		id_item_clasificacion nvarchar(100)
		);

	-- inserto los datos a la tabla LIC
	insert into LIC(
		id,
		descripcion,
		fecha,
		monto,
		moneda,
		metodo_adquisicion,
		metodo_adquisicion_det,
		categoria,
		categoria_det,
		item_cantidad,
		item_tipodeunidad,
		item_valorXu,
		fecha_cierredeLIC,
		id_proc_compra,
		id_ent_contrat,
		id_item_clasificacion
		)
	select DISTINCT
		id,
		descripcion
		fecha,
		monto,
		moneda,
		metodo_adquisicion,
		metodo_adquisicion_detalle,
		categoria,
		categoria_detalle,
		item_cantidad,
		item_tipodeunidad,
		item_valorXu,
		fecha_cierredelicitacion,
		id_proc_compra,
		id_ent_contr,
		id_item_clasificacion
	from licitacion;


-- Creo la nueva tabla ADJ. En donde voy a unificar aquellas filas que tengan el mismo valor [id]
	create table ADJ(
		id nvarchar(100) PRIMARY KEY not null,
		descripcion nvarchar(1000),
		fecha date,
		monto decimal(14,2),
		moneda varchar(3),
		item_cantidad decimal(11,2),
		item_tipodeunidad nvarchar(100),
		item_valorXu decimal(13,2),
		id_proc_compra nvarchar(100),
		id_item_clasificacion nvarchar(100)
		);

	begin tran ADJ;
    insert into ADJ(
		id,
		descripcion,
		fecha,
		monto,
		moneda,
		item_cantidad,
		item_tipodeunidad,
		item_valorXu,
		id_proc_compra,
		id_item_clasificacion
		)
	select
		id,
		descripcion,
		fecha,
		sum(monto) as monto,
		moneda,
		sum(item_cantidad) as item_cantidad,
		item_tipodeunidad,
		item_valorXu,
		id_proc_compra,
		id_item_clasificacion
			from adjudicacion_n
			group by id, descripcion,fecha,moneda,item_tipodeunidad,item_valorXu,id_proc_compra,id_item_clasificacion; -- 212160 filas afectadas, es correcto.

	commit tran ADJ;


-- Creo dos columnas agregadas en la tabla proc_de_compra. Contendran los montos totales del presupuesto y del gasto 
	alter table proc_de_compra add
		monto_LIC decimal(14,2),
		monto_ADJ decimal(14,2);

	-- Importo los datos a la columna monto_LIC
	begin tran;

	with total_LIC as(
		select
			sum(monto) as monto_total,
			id_proc_compra
		from LIC
		group by id_proc_compra
			)
	update PDC
	set PDC.monto_LIC = t_LIC.monto_total
	from proc_de_compra PDC
	left join total_LIC t_LIC
		on PDC.id_proc_compra = t_LIC.id_proc_compra
				
	-- Busco valores nulos para constatar de que la importacion fue correcta y poder hacer la transaccion 
	select
		count(*) as cantidad_nulos
	from proc_de_compra
	where monto_LIC is null; 

	-- no hay nulos, ejecutamos la transaccion
	commit tran;
		

	-- Importo los datos a la columna monto_ADJ
	begin tran;

	with total_ADJ as(
		select
			SUM(monto) as monto_total,
			id_proc_compra
		from ADJ
		group by id_proc_compra
				)
	update PDC
	set PDC.monto_ADJ = t_ADJ.monto_total
	from proc_de_compra PDC
	left join total_ADJ t_ADJ
		on PDC.id_proc_compra = t_ADJ.id_proc_compra;

	-- Busco valores nulos para constatar de que la importacion fue correcta y poder hacer la transaccion 
	select
		count(*) as cant_nulos
	from proc_de_compra
	where monto_ADJ is null;

	-- no hay nulos, ejecutamos la transaccion
	commit tran;

/*
(Integracion y transformacion)
Creo mi nueva tabla de hechos, nombrada 'renglon', en donde voy a integrar todos los valores que correspondan a los renglones individuales de cada proceso de compra. En mi modelo de datos tipo estrella esta tabla 
va a funcionar como la tabla principal.
*/

-- Creo la tabla y las llaves PK y FKs correspondientes
	create table renglon(
		id_renglon nvarchar(100) not null,
		descripcion nvarchar(100) null,
		descripcion_detallada nvarchar(200) null,
		monto_lic decimal(14,2) null,
		monto_adj decimal(14,2) null,
		valorxunidad_lic decimal(13,2) null,
		valorxunidad_adj decimal(13,2) null,
		cantidad_lic decimal(11,2) null,
		cantidad_adj decimal(11,2) null,
		item_tipodeunidad nvarchar(100) null,
		categoria nvarchar(100) null,
		categoria_det nvarchar(100) null,
		fecha_lic date null,
		fecha_adj date null,
		id_proc_compra nvarchar(20) null,
		id_item nvarchar(25) null,
		id_ent_contrat nvarchar(40) null,

		constraint PK_renglon
			primary key (id_renglon),

		constraint FK_procdecompra
			foreign key (id_proc_compra)
			references proc_de_compra (id_proc_compra),

		constraint FK_item
			foreign key (id_item)
			references items (id_item_clasificacion),

		constraint FK_entidadcontratante
			foreign key (id_ent_contrat)
			references entidad_contratante (id_ent_contr)
	);

	-- Inserto los datos a la tabla renglon
	insert into renglon (id_renglon)
	select id
	from LIC;

	select * from renglon
	update r
	set descripcion = lic.descripcion,
		descripcion_detallada = adj.descripcion_detallada,
		monto_lic = lic.monto,
		monto_adj = adj.monto,
		valorxunidad_lic = lic.item_valorXu,
		valorxunidad_adj = adj.item_valorXu,
		cantidad_lic = lic.item_cantidad,
		cantidad_adj = adj.item_cantidad,
		item_tipodeunidad = lic.item_tipodeunidad,
		categoria = lic.categoria,
		categoria_det = lic.categoria_det,
		fecha_lic = lic.fecha,
		fecha_adj = adj.fecha,
		id_proc_compra = lic.id_proc_compra,
		id_item = lic.id_item_clasificacion,
		id_ent_contrat = lic.id_ent_contrat
	from renglon r
	inner join lic
		on r.id_renglon = lic.id
	inner join adj
		on r.id_renglon = adj.id;


	-- ahora actualizo mis FKs a NOT NULL.
	alter table renglon
	alter column id_proc_compra nvarchar(20) NOT NULL;
	
	alter table renglon
	alter column id_item nvarchar(25) NOT NULL;
	
	alter table renglon
	alter column id_ent_contrat nvarchar(40) NOT NULL;


-- Agrego los campos de la tabla lic (metodo_adquisicion, metodo_adquisicion_det) en la tabla proc_de_compra
	alter table proc_de_compra
	add metodo_adquisicion nvarchar(100),
		metodo_adquisicion_detalle nvarchar(100);

	update p
		set p.metodo_adquisicion = lic.metodo_adquisicion,
			p.metodo_adquisicion_detalle = lic.metodo_adquisicion_det
	from proc_de_compra p
	inner join LIC
		on lic.id_proc_compra = p.id_proc_compra;