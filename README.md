# Proyecto BAC — Análisis de Compras Públicas

## Descripción del proyecto

Este proyecto consiste en el análisis de datos de **Buenos Aires Compras (BAC)**, utilizando información pública sobre procesos de contratación y compras del Gobierno de la Ciudad de Buenos Aires.

El objetivo principal fue transformar datos provenientes de fuentes públicas en un **modelo de datos estructurado y un dashboard interactivo en Power BI**, orientado al análisis de los montos licitados y adjudicados, las desviaciones presupuestarias y el comportamiento de las distintas entidades contratantes.

El proyecto abarca el proceso completo, desde la preparación de los datos hasta la generación de visualizaciones e insights.

---

## Objetivo

El análisis busca responder principalmente:

* ¿Cómo se distribuyen los procesos de compra según categoría y método de adquisición?
* ¿Qué diferencias existen entre los montos originalmente licitados y los montos finalmente adjudicados?
* ¿Qué procesos presentan mayores desviaciones presupuestarias?
* ¿Qué entidades contratantes concentran las mayores desviaciones?
* ¿Existen valores atípicos o comportamientos que requieran un análisis más detallado?

---

## Proceso realizado

El proyecto se desarrolló en diferentes etapas:

### 1. Exploración de los datos

Se realizó un análisis inicial de las tablas disponibles para comprender su estructura, identificar las principales variables y detectar posibles problemas de calidad.

Durante esta etapa se analizaron aspectos como:

* Estructura y contenido de las tablas.
* Valores nulos y duplicados.
* Distribución de variables.
* Consistencia de los datos.
* Relaciones entre las diferentes tablas.

### 2. Limpieza y transformación

Los datos fueron procesados utilizando **SQL Server**, manteniendo las tablas originales sin modificaciones y generando nuevas estructuras para trabajar con datos preparados para el análisis.

Se realizaron tareas de:

* Corrección de inconsistencias.
* Transformación de formatos.
* Tratamiento de valores.
* Eliminación de redundancias.
* Creación de nuevas tablas.
* Integración de información proveniente de diferentes fuentes.

### 3. Validación

Se implementaron diferentes controles para comprobar la calidad e integridad de los datos después de las transformaciones.

Entre las verificaciones realizadas se encuentran:

* Unicidad de identificadores.
* Correspondencia entre tablas.
* Integridad de relaciones.
* Consistencia de montos y cantidades.
* Validación de valores y resultados obtenidos durante las transformaciones.

### 4. Modelado de datos

A partir de los datos procesados se construyó un **modelo dimensional orientado al análisis**, reduciendo redundancias y organizando la información en tablas relacionadas.

El modelo fue posteriormente utilizado como fuente para el desarrollo del dashboard en Power BI.

### 5. Análisis y visualización

Los datos procesados fueron importados a **Power BI**, donde se desarrolló un dashboard interactivo compuesto por tres páginas principales:

1. **Visión general**
2. **Análisis de desviaciones**
3. **Análisis por entidad contratante**

El dashboard permite explorar los datos mediante filtros, segmentadores, interacciones entre visualizaciones y diferentes indicadores calculados con DAX.

---

## Análisis principal

Uno de los principales focos del proyecto fue el análisis de la diferencia entre el **monto licitado** y el **monto adjudicado**.

A partir de esta diferencia se construyeron indicadores que permiten analizar la desviación tanto en términos absolutos como porcentuales.

La clasificación de los procesos permite distinguir entre resultados:

* **Favorables:** el monto adjudicado es inferior al monto licitado.
* **Iguales:** ambos montos coinciden.
* **Desfavorables:** el monto adjudicado supera al monto licitado.

Esto permite pasar de una simple descripción de los datos a un análisis orientado a la **identificación de desviaciones, patrones y posibles anomalías**.

---

## Dashboard

El resultado final es un dashboard interactivo desarrollado en Power BI, diseñado para comenzar con una visión general y avanzar progresivamente hacia análisis más específicos.


### Principales funcionalidades

* Segmentación por período.
* Análisis por categoría.
* Análisis por método de adquisición.
* Análisis por entidad contratante.
* Indicadores de montos licitados y adjudicados.
* Cálculo de desviaciones absolutas y porcentuales.
* Identificación de valores atípicos.
* Interacción entre visualizaciones.
* Navegación entre páginas.
* Tooltips personalizados.

---

## Tecnologías utilizadas

| Tecnología       | Uso                                               |
| ---------------- | ------------------------------------------------- |
| **SQL Server**   | Limpieza, transformación, validación y modelado   |
| **Power BI**     | Modelado, análisis y visualización                |
| **DAX**          | Creación de medidas e indicadores                 |
| **Git / GitHub** | Control de versiones y documentación del proyecto |

---

## Estructura del repositorio

```text
Proyecto-BAC/
│
├── sql/
│   ├── README.md
│   ├── limpieza/
│   ├── exploracion/
│   ├── validacion/
│   ├── modelado/
│   └── imagenes/
│
├── power_bi/
│   ├── README.md
│   └── imagenes/
│
├── python/
│
└── README.md
```

Cada sección contiene la documentación correspondiente a las diferentes etapas del proyecto.

El README de **SQL** presenta consultas representativas de las etapas de exploración, limpieza, transformación, validación y modelado.

El README de **Power BI** documenta el dashboard, sus páginas, principales indicadores y funcionalidades.

---

## Resultado

El proyecto permitió desarrollar un flujo completo de análisis de datos, desde datos públicos sin procesar hasta un producto analítico interactivo.

El resultado integra **preparación de datos, SQL, modelado dimensional, análisis, DAX y visualización**, con el objetivo de convertir datos de compras públicas en información útil para analizar el comportamiento de los procesos y detectar desviaciones que puedan requerir una revisión más detallada.
