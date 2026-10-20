-- 07_explain_analyze.sql
-- Nguồn: mục 3.2.3 (3) "Phân tích kế hoạch thực thi (EXPLAIN ANALYZE)"; Phụ lục B (lưu log EXPLAIN)
--
-- Mục đích: chứng minh truy vấn thực sự dùng ANN index (Index Scan using idx_...) thay vì Seq Scan.
-- Nếu plan ra "Seq Scan": kiểm tra lại biểu thức halfvec, toán tử <=>, và xem bảng có >1 index không.
-- Lưu output ra file log cho từng cấu hình, ví dụ:
--   psql -d cbir_db -f sql/07_explain_analyze.sql > logs/explain_$(date +%F_%H%M).log

\set qid 1
SELECT embedding::text AS qvec_small  FROM image_features_small  WHERE id = :qid \gset
SELECT embedding::text AS qvec_medium FROM image_features_medium WHERE id = :qid \gset
SELECT embedding::text AS qvec_large  FROM image_features_large  WHERE id = :qid \gset

SET ivfflat.probes = 32;
SET hnsw.ef_search = 64;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, embedding <=> :'qvec_small'::vector(64) AS dist
FROM image_features_small
ORDER BY embedding <=> :'qvec_small'::vector(64)
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, embedding <=> :'qvec_medium'::vector(512) AS dist
FROM image_features_medium
ORDER BY embedding <=> :'qvec_medium'::vector(512)
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) AS dist
FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048)
LIMIT 10;
