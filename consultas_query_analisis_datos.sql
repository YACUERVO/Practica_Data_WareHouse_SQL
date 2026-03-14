/*Práctica Data WareHouse & SQL*/


--Enunciado 1.
	--Explora el fichero flights y analiza:
	--1 Cuántos registros hay en total
		select 
			count(*) as total_registros
		from flights;
		/*| count |
		  | 1209  |
		Al explorar los datos encontramos que existen en total 1209 filas 
		para la tabla flights*/
	
	--2 Cuántos vuelos distintos hay
		select * 
		from flights;
		select 
			unique_identifier 
		from flights;
		/*Validamos la columan unique_identifier, el cual nos muestra un patron
		donde tenemos la aerolinea, el numero del vuelo, la fecha el lugar del 
		aeropueto de salida y el lugar del aeropuerto de llegada	
		*/
		select 
			count(distinct unique_identifier) as total_vuelos_diferentes
		from flights
		where unique_identifier is not NULL;
		/*Realizamos un distinct en la columna unique_identifier, para contar cuanto
		vuelo hay distintos*/
		/*| count |
		  |  266  |*/
			
	--3. Cuántos vuelos tienen más de un registro
		with vuelos_repetidos as (
			select 
			unique_identifier
				from flights
				group by unique_identifier
				having count(*) > 1
		)
		
		select count(*) as vuelos_con_varios_registros
		from vuelos_repetidos
					
		--Validamos cuanto vuelos tienen mas registros,donde identificamos que hay varios unique_identifier con varios registros, luego los agrupamos para mirar cuando vuelos tiene varios registros para luego contarlos
		/*"vuelos_con_varios_registros"
			250*/
		
--Enunciado 2.
	/*Por qué hay registro duplicados para un mismo vuelo. Para ello, selecciona varios vuelos y analiza la evolución temporal de cada vuelo. */
	--1. Qué información cambia de un registro a otro
		
				
		/*Realizamos una ventana donde vamos a validar los registros duplicados de acuerdo con su unique_identifier, ademas realizamos un conteo por cada unique_identifier*/
			select 
				unique_identifier,
			    flight_row_id,
			    local_departure,
			    local_actual_departure,
			    local_arrival,
			    local_actual_arrival,
			    gmt_departure,
			    gmt_actual_departure,
			    gmt_arrival,
			    gmt_actual_arrival,
			    delay_mins,
			    arrival_status,
			    created_at,
			    updated_at,
			    row_number() over(partition by unique_identifier order by created_at) as rn,
			    count(*) over(partition by unique_identifier) as total
			from flights
		-- concluimos que no se tratan de vuelos duplicados si no el hisotrico de los vuelos de acuerdo al tiempo, es decir multiplos registros donde esta la trazabilidad de los vuelos
		
--Enunciado 3.
	/*Evalúa la calidad del dato. La calidad del dato nos indica si la información es consistente,
	completa, coherente y representa una realidad verosímil. Para ello debemos establecer
	unos criterios:*/
	--1. La información de created_at debe ser única para cada vuelo aunque tenga más de un registro.
		with validar_created_at as (
			select 
				unique_identifier,			    
			    created_at,
			    count(*) as cantidad_repetidos	 
			from flights
			where created_at is not NULL
			group by unique_identifier, created_at
			having count(*)>1
			order by cantidad_repetidos desc
		)
		select * from validar_created_at 
		
	/* Validamos la informacion donde encontramos vuelos con created_At repetidos vamos analizar un vuelo para validar el update_at*/
			select 
				unique_identifier,	
				updated_at,
			    created_at			     
			from flights
			where unique_identifier = 'IB-206-20250716-MAD-JFK'
	/*Al validar los registros encontramos que el created_at es unico para cada unique_identifier, lo que encontramos es que se va actualizando el update_at*/
	
	
	--2. La información de updated_at deber ser igual o más que la información de created_at, lo que nos indica coherencia y consistencia
		with validar_update_at as (
			select 				
		        unique_identifier,			    
		        created_at,
		        updated_at		  
			from flights
			where created_at is not NULL AND updated_at is not NULL and updated_at < created_at		
		)
		select 
			count(*) as total_registros,
			case
				when count(*) = 0 then 'cumple update_at es mayor o igual que created_at'
				else 'created_at es mayor que update_at hay inconsistencia en los datos'
			end as validacion		
		from validar_update_at
	/*realizamos un cte donde filtramos la informacion que no sea nula de created_at y updated_at ademas solo compramos cuando sea el created_at mayor que el updatet_at donde vamos a mirar si hay alguna registro que este inconcistente en la data, lo que podemos concluir que los registros con consistentes*/
	
--Enunciado 4.
	/*El último estado de cada vuelo. Cada vuelo puede aparecer varias veces en el dataset, para
	avanzar con nuestro análisis necesitamos quedarnos solo con el último registro de cada
	vuelo.
	Puedes crear una tabla o vista resultante de esta query en tu base de datos local, la
	utilizaremos en los siguientes enunciados. Si prefieres no guardar la última información,
	tendrás que hacer uso de esa query como una CTE en los enunciados siguientes.*/
	create view estados_vuelos as 
	with estados as (
		select 
			*,
			row_number() over(partition by unique_identifier order by created_at) as rn	
		from flights
		where created_at is not NULL
	)
	select * from estados
	where rn = 1;
	
	/*Realizamos la vista donde nos quedamos con los created_at unicos */
	
	
	
--Enunciado 5.
	/*Considerando que los campos local_departure y local_actual_departure son necesarios
	para el análisis, valida y reconstruye estos valores siguiendo estas reglas:*/
	
	--1. Si local_departure es nulo, utiliza created_at.
	--2. Si local_actual_departure es nulo, utiliza local_departure. Si este también es nulo, utiliza created_at.
	--Crea dos nuevos campos:
		--effective_local_departure
		--effective_local_actual_departure	
	select 
		local_departure,
		local_actual_departure,
		created_at,	
		coalesce(local_departure, created_at) as effective_local_departure,
		coalesce (local_actual_departure,local_departure,created_at) as effective_local_actual_departure	
	from estados_vuelos
	
	/*Realizamos las validaciones y llenamos los datos nulos de acuerdo con las reglas, si local_departure con created_at, y local_actual_departura con local departure, pero si los dos columnas son null las llenamos con created_at, para completar los datos faltantes*/	
	--Extra: Realiza las validaciones para los campos local_arrival y local_actual_arrival.
	select 
		count(local_arrival),count(local_actual_arrival)
	from estados_vuelos
	where local_arrival is not NULL
	
	select 
		count(*)
	from estados_vuelos
	where local_actual_arrival is NULL
	
	select 
		count(*)
	from estados_vuelos
	where local_arrival is NULL
	
	/*Contamos los valores de las columnas  local_arrival y local_actual_arrival cuando no son nulos, luego hacemos la consulta individualmente para validar los valores nulos, encontramos que la columnba local_actual_arrival tiene valores nulos, entonces vamos aplicar la reglar que donde hay valores nulos de local_actual_arrival lo rellenaremos con local_arrival*/
	
	select 
		local_arrival,
		local_actual_arrival,		
		coalesce(local_actual_arrival, local_arrival) as effective_local_arrival		
	from estados_vuelos
	
	
--Enunciado 6.
	--Análisis del estado del vuelo. Haciendo uso del resultado del enunciado 4, analiza los estados de los vuelos.
	--1. Qué estados de vuelo existen
	
	
	select distinct 
		arrival_status as estado_de_los_vuelos
	from
		estados_vuelos
	order by estado_de_los_vuelos
	
	select 	  
	    delay_mins,
	    arrival_status
	from estados_vuelos
	where arrival_status = 'DY' and delay_mins  is not null
	
	/*Analizando el arrival_status se puede concluir con la columna delay_mins que los DY son los vuelos retrasados, debio al tiempo en minutos, los OT son los vuelos que llegaron a tiempo, y los CX los vuelos cancelados */
		
	--2. Cuántos vuelos hay por cada estado
	select 
		arrival_status as estado,
		count(*) as total_por_estado,
		round(count(*) * 100 / sum(count(*)) over()) as porcentaje_vuelos
	from estados_vuelos
	group by arrival_status
	order by total_por_estado desc;
	/* el 62% de los vuelos fueron retrasados, mientras que el 36% de los vuelos llegaron a tiempo, mientras que solo 4 vuelos en total fueron cancelados */
		
--Enunciado 7.
	/*País de salida de cada vuelo. Tienes disponible un csv. con información de aeropuertos
	airports.csv. Haciendo uso del resultado del enunciado 4, analiza los aeropuertos de salida.*/
	
	--1. De qué país despegan los vuelos
		select distinct
			air.airport_name,
			air.country
		from 
			estados_vuelos as est 
		inner join airports as air
		on est.departure_airport = air.airport_code
		
		/*Hacemos un inner join para que nos tome las columnas que nos conincidan para validar solo los aeropuestos donde salen los vuelos y no tenner nulos dentro*/
	
	
	--2. Cuántos vuelos despegan por país
		select 
			count(*),
			air.country
		from 
			estados_vuelos as est 
		inner join airports as air
		on est.departure_airport = air.airport_code
		group by air.country
		order by count(*) desc
	
	/*la mnayor parte de vuelos salen en españa con un total de 118, seguido por francia para un total de 26, encontramos que por ultimo lugar se encuentra reino unida */
--Enunciado 8.
	/*Delay medio y estado de vuelo por país de salida. Haciendo uso del resultado del enunciado
	4, analiza el estado y el delay/retraso medio con el objetivo de identificar si existen países
	que pueden presentar problemas operativos en los aeropuertos de salida. */
	
	--1. Cuál es el delay medio por país
		select 
			air.country as pais_de_salida,
			count(*) as total,
			round(100.0 * count(est.delay_mins) / count(*), 2) as porcentaje_datos_validos,
			count(est.delay_mins) as datos_reales,
			round(avg(est.delay_mins),2) as delay_medio_minutos,
			case 
				when avg(est.delay_mins) < 4 then 'Exelente'
				when avg(est.delay_mins) between 5 and 15 then 'Bueno'
				else 'Problemas en la oepracion'
			end as estado_operativos
			
		from 
			estados_vuelos as est 
		inner join airports as air
		on est.departure_airport = air.airport_code
		group by air.country
		order by count(*) desc 
		
	/*realizamos un analisis del total de los vuelos por cada pais donde evaluamos la calidad de los datos para encontar el rendimiento operativo. Debido que la columan delay_mins presenta muchos valores nulos, calculamos el porcentaje de datos validos para tener la confiabilidad de los resultados. Entonces en españa con un total de 118 vuelos de los cuales el 35% tienen informacion de retraso se optiene un delay medio de 8.81 minutos donde se tiene un operativo bueno, francia con 26 vuelos en total, con un 34% de datos validos se puede optener un promedio de 8.89 minutos para un rendimiento oeprativo bueno, igual manera paises como estados unidos y holanda tiene un estado de oepracion exelente devido que su promerio en minutos es de 2.78 y -4 minutos el cual se determina porque llego antes de lo esperado. El pais que presenta riesgo oeprativos es del reino unido con un delay de 4.29 con un porcentaje de datos validos del 43.75%*/
	
	/* De cierta manera podriamos haber hecho con los datos que tiene y haber filtrado los datos que no son nulos como se muestra a continuacion*/
	
	select 
			air.country as pais_de_salida,
			count(*) as total,
			round(100.0 * count(est.delay_mins) / count(*), 2) as porcentaje_datos_validos,			
			round(avg(est.delay_mins),2) as delay_medio_minutos,
			case 
				when avg(est.delay_mins) < 4 then 'Exelente'
				when avg(est.delay_mins) between 5 and 15 then 'Bueno'
				else 'Problemas en la oepracion'
			end as estado_operativos
			
		from 
			estados_vuelos as est 
		inner join airports as air
		on est.departure_airport = air.airport_code
		where delay_mins is not null
		group by air.country
		order by count(*) desc 
	
	--2. Cuál es la distribución de estados de vuelos por país.
	
	with vuelos_cte as (
		select 		
			est.departure_airport,
			est.arrival_status
		from estados_vuelos as est
	), airports_cte as (
		select
			air.airport_code,
			air.airport_name,
			air.country
		from airports as air	
	), estados_vuelos_por_paises as (
		select 
			air.country,
			count(*) as total_vuelos,
			count(case when vue.arrival_status = 'OT' THEN 1 END) as cantidad_OT,
			count(case when vue.arrival_status = 'DY' THEN 1 END) as cantidad_DY,
			count(case when vue.arrival_status = 'CX' THEN 1 END) as cantidad_CX
		from vuelos_cte as vue
		inner join airports_cte as air
		on vue.departure_airport = air.airport_code
		group by air.country
		
	), porcentaje as (
		select 
			country,
			total_vuelos,			
			round((cantidad_OT * 100.0 / total_vuelos),2) as porcentaje_ot,
			round((cantidad_DY * 100.0 / total_vuelos),2) as porcentaje_dy,
			round((cantidad_CX * 100.0 / total_vuelos),2) as porcentaje_cx			
		from estados_vuelos_por_paises		
		order by total_vuelos desc
	)			
	select 
			*
	from porcentaje
	
	/* validando la informacion encontramos que todos los paises presenta vuelos retrasados donde el porcentaje ocila entre 88 hasta 52 porciento donde francia tiene una mayor cantidad de vuelos retrasados, en estados unidos encontramos que hay un 4% de vuelos cancelados y el pais que mas completa sus vuelos a tiempo es paises bajos con un 47.06% seguido por españa*/
 
--Enunciado 9.
	/* El estado de vuelo por país y por época del año. Dado que no en todas las épocas del año
	las condiciones climatólogicas son iguales, analiza si la estaciones del año impactan en el
	delay medio por país. Considera la siguiente clasificación de meses del año por época:
	● Invierno: diciembre, enero, febrero
	● Primavera: marzo, abril, mayo
	● Verano: junio, julio, agosto
	● Otoño: septiembre, octubre, noviembre */
	 with estados_vuelos_cte as (
		select
			local_departure,
			coalesce(local_departure, created_at) as effective_local_departure,			
			departure_airport,
			delay_mins,
			arrival_status
		from estados_vuelos
	), airports_cte as (
		select			
			airport_code,
			airport_name,
			country
		from airports	
	), estacion_cte as (
		select 
			air.airport_name,
			air.country,
			est.delay_mins,
			est.effective_local_departure,
			est.arrival_status,
			case 
				when extract(month from est.effective_local_departure) in(12,1,2) then 'Invierno'
				when extract(month from est.effective_local_departure) in(3,4,5) then 'Primavera'
				when extract(month from est.effective_local_departure) in(6,7,8) then 'Verano'
				when extract(month from est.effective_local_departure) in(9,10,11) then 'Otoño'
			end as estacion			
			
		from estados_vuelos_cte as est  
		inner join airports_cte as air
		on est.departure_airport = air.airport_code
		
	),promedio_estacion_cte as (
		select
			country as paises,
			count(*) as vuelos,			
			round(avg(case when estacion = 'Invierno' and arrival_status = 'DY' then delay_mins end),2) as  promedio_invierno_DY,
			round(avg(case when estacion = 'Primavera' and arrival_status = 'DY' then delay_mins end),2) as  promedio_primavera_DY,
			round(avg(case when estacion = 'Verano' and arrival_status = 'DY' then delay_mins end),2) as  promedio_verano_DY,
			round(avg(case when estacion = 'Otoño' and arrival_status = 'DY' then delay_mins end),2) as  promedio_otoño_DY,
			round(avg(case when estacion = 'Invierno' and arrival_status = 'CX' then delay_mins end),2) as  promedio_invierno_CX,
			round(avg(case when estacion = 'Primavera' and arrival_status = 'CX' then delay_mins end),2) as  promedio_primavera_CX,
			round(avg(case when estacion = 'Verano' and arrival_status = 'CX' then delay_mins end),2) as  promedio_verano_CX,
			round(avg(case when estacion = 'Otoño' and arrival_status = 'CX' then delay_mins end),2) as  promedio_otoño_CX,
			round(avg(case when estacion = 'Invierno' and arrival_status = 'OT' then delay_mins end),2) as  promedio_invierno_OT,
			round(avg(case when estacion = 'Primavera' and arrival_status = 'OT' then delay_mins end),2) as  promedio_primavera_OT,
			round(avg(case when estacion = 'Verano' and arrival_status = 'OT' then delay_mins end),2) as  promedio_verano_OT,
			round(avg(case when estacion = 'Otoño' and arrival_status = 'OT' then delay_mins end),2) as  promedio_otoño_OT,
			round(avg(delay_mins)) as promedio		
		from estacion_cte
		group by 1
		order by 1,2 
					
	
	)	
	--select * from promedio_estacion_cte;	
	
	/*al validar la informacion encontramos que para españa el retraso de los vuelos se presenta mas en invierno y primavera. Encontamos que en primavera paises como reino unido presenta un mayor retraso en comparacion con verano que no presenta retraso de salida. Francia y holanda no presenta retrasos de vuelos cuando la estacion es primavera. El mejor paises que no tiene retrasos es holanda es el pais con menores retrasos en general lo que se determina que cumple con sus tiempos programados de los vuelos */		
	/*select
	    'Total general por estacion por DY' as paises,
	    sum(vuelos) as total_vuelos,
	    round(sum(promedio_invierno_DY), 2) as promedio_invierno_DY,
	    round(sum(promedio_primavera_DY), 2) as promedio_primavera_DY,
	    round(sum(promedio_verano_DY), 2) as promedio_verano_DY,
	    round(sum(promedio_otoño_DY), 2) as promedio_otonio_DY
	from promedio_estacion_cte;*/
	
	/*Encontramos que el mayor promedio de retraso de vuelos por estacion es primavera, y el menor retraso es invierno */
	select
	    'Total general por estacion por OT ' as paises,
	    sum(vuelos) as total_vuelos,
	    round(sum(promedio_invierno_OT), 2) as promedio_invierno_OT,
	    round(sum(promedio_primavera_OT), 2) as promedio_primavera_OT,
	    round(sum(promedio_verano_OT), 2) as promedio_verano_OT,
	    round(sum(promedio_otoño_OT), 2) as promedio_otonio_OT
	from promedio_estacion_cte;
			
	/*Encontramos que la mejor estacion para viajar y que llega antes de lo programado es invierno, primavera y verano*/
	
--Enunciado 10.
	/*Frecuencia de actualización de los vuelos. Volviendo al análisis de la calidad del dataset,
	explora con qué frecuencia se registran actualizaciones de cada vuelo y calcula la
	frecuencia media de actualización por aeropuerto de salida.*/
	with id_vuelos_cte as (
		select
			departure_airport,
			unique_identifier,
			created_at,
			updated_at,
			row_number() over(partition by unique_identifier order by created_at) as rn,
			count(case when updated_at > created_at then 1 end) over(partition by unique_identifier) as total_updated			
			from flights
			where created_at is not null 
	
	), airports_cte as (
		select 
			airport_code,
			airport_name			
		from airports	
	
	)
	, frecuencia_cte as (
	
		select  						
			air.airport_name as nombre_aeropuerto,
			vue.total_updated,
			vue.rn as ventana_rn
		from id_vuelos_cte as vue
		inner join airports_cte as air
		on vue.departure_airport = air.airport_code
		where vue.rn = 1
	
	
	)
	
	
		select 
			nombre_aeropuerto,
			count(*) total_vuelos,
			sum(total_updated) as total_update,
			round(avg(total_updated),2) as promedio_actualizaciones
			
		from frecuencia_cte
		group by 1

/*Basado en el resultadoa encontramos que cuando el rango es mayor 2, podemos analizar que hay multiples actualizaciones por vuelo, como encontramos en los aeropuestos de Gualle y Heathrow, ademas hay una frecuencia media en los aeropuestos de amsterdam con un promedio de 1.88 igualmenet que el aeropuerto de Kennedy y Prat. Encontramos que madrid tiene un total de 59 vuelos, el cual tiene un promedio de 1.77 actualizaciones por vuelo */


--Enunciado 11.
	/*Consistencia del dato. El campo unique_identifier identifica el vuelo y se construye con: aerolínea, número de vuelo, fecha y aeropuertos. Para cada vuelo (último snapshot),
	comprueba si la información del unique_identifier es consistente con las columnas del
	dataset.*/
	
	--1. Crea un flag is_consistent.
	with vuelos_cte as (
		select 
			unique_identifier,
			airline_code,
			local_departure,
			departure_airport,
			arrival_airport,
			to_char(local_departure::DATE, 'YYYYMMDD') as fecha_aeropuerto_local,
			row_number() over(partition by unique_identifier order by created_at) as rn
		from flights		
		where created_at is not null and local_departure is not null
	
	),comparacion_unique_identifier_cte as (		
		select 
			rn,
			unique_identifier,
			concat(airline_code,'-',
				split_part(unique_identifier, '-', 2), '-',
	           	fecha_aeropuerto_local, '-',
	           	departure_airport, '-',
	           	arrival_airport) AS unique_identifier_flag	
		from vuelos_cte 
	)
		select 
			unique_identifier,
			unique_identifier_flag,
			case 
				when unique_identifier = unique_identifier_flag then 'Correcto'
				else 'Incorrecto'
			end as Validacion
		
		from comparacion_unique_identifier_cte		
	/*Realizamos la compracion del unique_identifier con los registros de airline_code,local_departure, arrival_airport para identificar si existen inconsistencias en los registros de los datos*/
		
	--2.Calcula cuántos vuelos no son consistentes.
	with vuelos_cte as (
		select 
			unique_identifier,
			airline_code,
			local_departure,
			departure_airport,
			arrival_airport,
			to_char(local_departure::DATE, 'YYYYMMDD') as fecha_aeropuerto_local,
			row_number() over(partition by unique_identifier order by created_at) as rn
		from flights		
		where created_at is not null and local_departure is not null
	
	),comparacion_unique_identifier_cte as (		
		select 
			rn,
			unique_identifier,
			concat(airline_code,'-',
				split_part(unique_identifier, '-', 2), '-',
	           	fecha_aeropuerto_local, '-',
	           	departure_airport, '-',
	           	arrival_airport) AS unique_identifier_flag	
		from vuelos_cte 
	),consistencia_cte as (
		select 			
			unique_identifier,
			unique_identifier_flag,
			case 
				when unique_identifier = unique_identifier_flag then 'Correcto'
				else 'Incorrecto'
			end as Validacion	
		from comparacion_unique_identifier_cte	
		
	)	
		select 
			count(*) as total_vuelos,
			sum(case when Validacion = 'Correcto' then 1 else 0 end) as Total_Correctos,
			sum(case when Validacion = 'Incorrecto' then 1 else 0 end) as Total_Incorrectos
		from consistencia_cte
		
	/*Encontramos que el total de datos correctos es de 625 y solo 5 con incorrectos es decir el 95% de los datos estan correctos*/
	
	--3. Usando la tabla airlines, muestra el nombre de la aerolínea y cuántos vuelos no 	consistentes tiene
with vuelos_cte as (
		select 
			unique_identifier,
			airline_code,
			local_departure,
			departure_airport,
			arrival_airport,
			to_char(local_departure::DATE, 'YYYYMMDD') as fecha_aeropuerto_local,
			row_number() over(partition by unique_identifier order by created_at) as rn
		from flights		
		where created_at is not null and local_departure is not null
	
	),comparacion_unique_identifier_cte as (		
		select 
			airline_code,
			rn,
			unique_identifier,
			concat(airline_code,'-',
				split_part(unique_identifier, '-', 2), '-',
	           	fecha_aeropuerto_local, '-',
	           	departure_airport, '-',
	           	arrival_airport) AS unique_identifier_flag	
		from vuelos_cte 
	),consistencia_cte as (
		select 		
			airline_code,
			unique_identifier,
			unique_identifier_flag,
			case 
				when unique_identifier = unique_identifier_flag then 'Correcto'
				else 'Incorrecto'
			end as Validacion	
		from comparacion_unique_identifier_cte	
		
	), resumen_inconsistencias_cte as (	
		select 
			airline_code,
			count(*) as total_vuelos,
			sum(case when Validacion = 'Correcto' then 1 else 0 end) as Total_Correctos,
			sum(case when Validacion = 'Incorrecto' then 1 else 0 end) as Total_Incorrectos
		from consistencia_cte
		group by 1

	), airlines_cte as (
		select 
			airline_code,
			name		
		from airlines 
	
	)
		select 
			air.airline_code,
			air.name,
			coalesce(res.Total_Incorrectos,0) as vuelos_incorrectos		
		from airlines_cte as air  
		inner join resumen_inconsistencias_cte as res  
		on air.airline_code = res.airline_code
		
/*Se realiza el inner join para mirar el nombre de las aerolineas para veriricar el nombre de los vuelos incorrectos y encontramos que fue Iberia el unico que presenta inconsistencias*/
	
