-- 04_index_hnsw.sql
-- Nguồn: mục 3.2.2 (3) và Phụ lục B.2; thời gian xây dựng: Bảng 3.2
--
-- m = 16, ef_construction = 64 cho cả ba mức vector.
-- Lưu ý: khi cùng tồn tại với IVFFlat trên một bảng, planner tự chọn index (xem ghi chú ở 03).

SET maintenance_work_mem = '1GB';
\timing on

-- a) Small (d = 64)
CREATE INDEX IF NOT EXISTS idx_small_hnsw_cosine
ON image_features_small
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- b) Medium (d = 512)
CREATE INDEX IF NOT EXISTS idx_medium_hnsw_cosine
ON image_features_medium
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- c) Large (d = 2048): HNSW qua biểu thức halfvec
CREATE INDEX IF NOT EXISTS idx_large_hnsw_cosine
ON image_features_large
USING hnsw ((embedding::halfvec(2048)) halfvec_cosine_ops)
WITH (m = 16, ef_construction = 64);

\timing off
