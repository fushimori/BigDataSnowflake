SELECT COUNT(*) FROM sellers;

SELECT DISTINCT md.sale_seller_id 
FROM mock_data md
LEFT JOIN sellers s ON md.sale_seller_id = s.seller_id
WHERE s.seller_id IS NULL;