-- Вычищаем по ключевым словам
CREATE VIEW cc_tender as
WITH
filtred_tender AS (
  SELECT * FROM tender t 
  WHERE t.purchase_name ilike '%горяч%лин%'
    or t.purchase_name ilike '%контакт%центр%'
    or t.purchase_name ilike '%call%центр%'
    or t.purchase_name ilike '%колл%центр%'
    or t.purchase_name ilike '%прием% и обработк% вызова%'
    or t.purchase_name ilike '%обработк% телефонных вызовов%'
    or t.purchase_name ilike '%центр% обработки вызовов%'
)  
select * from filtred_tender ft
WHERE ft.purchase_name NOT ilike '%атс%'
    AND ft.purchase_name NOT ilike '%оборудовани%'
    AND ft.purchase_name NOT ilike '%лиценз%'
    AND ft.purchase_name NOT ilike '%дорог%'
    AND ft.purchase_name NOT ilike '%поставк%'
    AND ft.purchase_name NOT ilike '%производств%'
    AND ft.purchase_name NOT ilike '%мебел%'
    AND ft.purchase_name NOT ilike '%крес%'
    AND ft.purchase_name NOT ilike '%гарнитур%'
    AND ft.purchase_name NOT ilike '%наушник%'
    AND ft.purchase_name NOT ilike '%канал%связи%'
    AND ft.purchase_name NOT ilike '%программ%обеспеч%'
    AND ft.purchase_name NOT ilike '%ремонт%'
    AND ft.purchase_name NOT ilike '%sip-транк%'
    AND ft.purchase_name NOT ilike '%sip-номер%'
    AND ft.purchase_name NOT ilike '%vpn%'
    AND ft.purchase_name NOT ilike '%техническ%обслуживан%'
    AND ft.purchase_name NOT ilike '%сервис%обслуживан%'
    AND ft.purchase_name NOT ilike '%услуг%связ%'
    AND ft.purchase_name NOT ilike '%техническ%поддержк%'
    AND ft.purchase_name NOT ilike '%рабоч%мест%'
    AND ft.purchase_name NOT ilike '%техническ%сопровожд%'
    AND ft.purchase_name NOT ilike '%модернизац%'
    AND ft.purchase_name NOT ilike '%информацион%систем%'
    AND ft.purchase_name NOT ilike '%курс%'
    AND ft.purchase_name NOT ilike '%тестирован%'
    AND ft.purchase_name NOT ilike '%кабель%'
    AND ft.purchase_name NOT ilike '%RFI%'
    AND ft.purchase_name NOT ilike '%IP%телефон%'
    

--  сделать из этого таблицу, к которой потом будет обращаться python 
CREATE MATERIALIZED VIEW filtered_tender AS
	SELECT * FROM cc_tendert
	WHERE status NOT IN ('Дублированная', 'Закупка "Ростелеком"', 'Ошибочная закупка')


-- СОЗДАЕМ ТАБЛИЦУ - отфльтрованная биг дата

DELETE FROM contactcc 
WHERE contact in  (
	'www.sberbank.ru', 'www.bosch-group.ru', 'www.teleplast.ru',
	'74955005550', '74952492979', '74952492979' , '74852338122', '78202676366', '78005059730')

	
CREATE MATERIALIZED VIEW filtered_clientactivity AS
	select * from clientactivity c 
	where value in (
		SELECT 
			c.contact
		FROM 
			contactcc c)
		
		
CREATE MATERIALIZED VIEW inn  AS
SELECT
	distinct 
	inn_union.customer_inn,
	t2.customer_name,
	0::numeric  as scrore_baall
FROM (

	SELECT
		distinct t.customer_inn
	FROM tender t
	UNION
	SELECT
		distinct c.inn
	FROM clientactivity c
) as inn_union
LEFT JOIN tender t2 on t2.customer_inn = inn_union.customer_inn
ORDER BY customer_name 





CREATE MATERIALIZED VIEW inn_tender_count  AS
SELECT customer_inn, count(*)
FROM filtered_tender ft 
WHERE customer_inn is not null
GROUP BY customer_inn
ORDER BY count DESC

CREATE MATERIALIZED VIEW inn_tender_ad  AS
SELECT customer_inn, avg(duration) ad
FROM filtered_tender ft 
WHERE customer_inn is not null
GROUP BY customer_inn
ORDER BY ad DESC


CREATE MATERIALIZED VIEW inn_web_count  AS
SELECT
	inn,	
	count(value) 
FROM filtered_clientactivity fc 
WHERE type = 'web'
GROUP BY INN
ORDER BY count DESC 


CREATE MATERIALIZED VIEW inn_phone_count  AS
SELECT
	inn,	
	count(value) 
FROM filtered_clientactivity fc 
WHERE type != 'web'
GROUP BY INN
ORDER BY count DESC



CREATE MATERIALIZED VIEW inn_nmc_all  AS
WITH
nmc_low AS (
	select customer_inn, count(*)
	  from filtered_tender ft 
	  where nmc_type = 'Low' and customer_inn IS NOT NULL
	  group by customer_inn 
	  having count(*) > 1
),
nmc_middle AS (
	select customer_inn, count(*)
	  from filtered_tender ft 
	  where nmc_type = 'Middle'  and customer_inn IS NOT NULL
	  group by customer_inn 
	  having count(*) > 1
),
nmc_high AS (
	select customer_inn, count(*)
	  from filtered_tender ft 
	  where nmc_type = 'High'  and customer_inn IS NOT NULL
	  group by customer_inn 
	  having count(*) > 1
)
SELECT
	ai.customer_inn as inn,
	nl.count AS low_count,
	nm.count AS mid_count,
	nh.count AS high_count
FROM inn ai
LEFT JOIN nmc_low nl on ai.customer_inn = nl.customer_inn
LEFT JOIN nmc_middle nm on ai.customer_inn = nm.customer_inn
LEFT JOIN nmc_high nh on ai.customer_inn = nh.customer_inn






	
-- ОЦЕНКА  ПАРАМЕТРОВ
	
-- INN PHONE COUNT SCORE
WITH 
ipc AS (
	SELECT
		inn,
		count
	FROM inn_phone_count 
	WHERE (count / (SELECT avg(count) FROM inn_phone_count)) <= 5
)
SELECT
	ipc.inn,
	ipc.count,
	round(ipc.count / (SELECT avg(count) FROM ipc), 2) score_w
from ipc


-- INN WEB COUNT SCORE
WITH 
iwc AS (
	SELECT
		inn,
		count
	FROM inn_web_count 
	WHERE (count / (SELECT avg(count) FROM inn_web_count)) <= 5
)
SELECT
	iwc.inn,
	iwc.count,
	round(iwc.count / (SELECT avg(count) FROM iwc), 2) score_w
from iwc



-- INN TENDER COUNT SCORE
WITH 
itc AS (
	SELECT
		customer_inn inn,
		count
	FROM inn_tender_count
	WHERE (count / (SELECT avg(count) FROM inn_tender_count)) <= 5
)
SELECT
	itc.inn,
	itc.count,
	round(itc.count / (SELECT avg(count) FROM itc), 2) score_w
from itc



-- INN TENDER DURATION SCORE

WITH
iad AS (
	SELECT
		customer_inn inn ,
		ad 
	FROM inn_tender_ad
	WHERE (ad / (SELECT avg(ad) from inn_tender_ad)) <= 5
)
SELECT
	iad.inn,
	iad.ad,
	round(iad.ad/ (SELECT max(iad.ad) FROM iad), 2) score_w
FROM iad
ORDER BY iad.ad DESC



-- INN TENDER NMC SCORE
SELECT
	inn,
	coalesce(low_count, 0) + coalesce(mid_count * 3, 0) + coalesce(high_count * 5, 0) nmc_score
FROM inn_nmc_all ina 
ORDER BY nmc_score DESC





