-- INN PHONE COUNT SCORE
CREATE VIEW pre_total_score as
WITH 
INN_PHONE_COUNT_SCORE AS (
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
),
INN_WEB_COUNT_SCORE AS (
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
),
INN_TENDER_COUNT_SCORE AS (
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
),
INN_TENDER_DURATION_SCORE AS (
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
),
INN_TENDER_NMC_SCORE AS (
	SELECT
		inn,
		coalesce(low_count, 0) + coalesce(mid_count * 3, 0) + coalesce(high_count * 5, 0) nmc_score
	FROM inn_nmc_all ina 
	ORDER BY nmc_score DESC
)
SELECT
	ia.customer_inn AS INN,
	coalesce(ipcs.score_w, 0) + coalesce(iwcs.score_w, 0) + coalesce(itcs.score_w, 0) + coalesce(itds.score_w, 0) + coalesce(itns.nmc_score, 0) AS TOTAL_SCORE
FROM 
	inn ia
LEFT JOIN INN_PHONE_COUNT_SCORE ipcs on ia.customer_inn = ipcs.inn
LEFT JOIN INN_WEB_COUNT_SCORE iwcs on ia.customer_inn = iwcs.inn
LEFT JOIN INN_TENDER_COUNT_SCORE itcs on ia.customer_inn = itcs.inn
LEFT JOIN INN_TENDER_DURATION_SCORE itds on ia.customer_inn = itds.inn
LEFT JOIN INN_TENDER_NMC_SCORE itns on ia.customer_inn = itns.inn
ORDER BY TOTAL_SCORE DESC


CREATE VIEW total_score as
SELECT
	inn,
	total_score / (SELECT max(total_score) from pre_total_score) as total_score
FROM pre_total_score 
	
