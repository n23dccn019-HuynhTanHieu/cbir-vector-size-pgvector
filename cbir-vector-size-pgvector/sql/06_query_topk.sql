-- 05_query_topk.sql
-- Nguồn: mục 3.2.3 (1) "Câu lệnh SQL truy vấn so khớp Top-K"
--
-- Toán tử khoảng cách pgvector: <-> (Euclid), <=> (Cosine), <#> (tích vô hướng âm).
-- Các index trong repo dùng *_cosine_ops nên truy vấn phải dùng <=> mới kích hoạt được index.
--
-- Báo cáo dùng placeholder :query_halfvec (không phải cú pháp psql thuần). Ở đây lấy vector truy vấn
-- từ chính DB bằng \gset để script chạy được trực tiếp; trong Python dùng %s của psycopg2 (xem python/).

\set qid 1
SELECT embedding::text AS qvec_small  FROM image_features_small  WHERE id = :qid \gset
SELECT embedding::text AS qvec_medium FROM image_features_medium WHERE id = :qid \gset
SELECT embedding::text AS qvec_large  FROM image_features_large  WHERE id = :qid \gset

-- Small (64D): dùng vector(64) để khớp index vector_cosine_ops
SELECT id, image_path, category,
       embedding <=> :'qvec_small'::vector(64) AS cosine_distance
FROM image_features_small
ORDER BY embedding <=> :'qvec_small'::vector(64)
LIMIT 10;

-- Medium (512D)
SELECT id, image_path, category,
       embedding <=> :'qvec_medium'::vector(512) AS cosine_distance
FROM image_features_medium
ORDER BY embedding <=> :'qvec_medium'::vector(512)
LIMIT 10;

-- Large (2048D): PHẢI dùng cùng biểu thức halfvec(2048) như lúc tạo index,
-- nếu không planner không dùng được index.
SELECT id, image_path, category,
       embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) AS cosine_distance
FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048)
LIMIT 10;
