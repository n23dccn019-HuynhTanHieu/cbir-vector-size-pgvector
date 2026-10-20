-- 02_baseline_exact_btree.sql
-- Nguồn: mục 3.2.2 (1) "Baseline Exact Search và B-Tree cho metadata"; Bảng 3.2b (dòng Flat Scan)
--
-- * B-Tree chỉ phục vụ lọc metadata (category), KHÔNG phải baseline ANN.
-- * Baseline vector = Exact Search: quét toàn bộ + xếp hạng theo khoảng cách, không dùng ANN index.
--   Đây cũng là ground truth để tính Recall ANN@10.
--
-- Chạy sau khi đã nạp dữ liệu (xem README).

-- B-Tree cho metadata
CREATE INDEX IF NOT EXISTS idx_small_category  ON image_features_small  USING btree (category);
CREATE INDEX IF NOT EXISTS idx_medium_category ON image_features_medium USING btree (category);
CREATE INDEX IF NOT EXISTS idx_large_category  ON image_features_large  USING btree (category);

-- Ảnh truy vấn lấy từ chính DB (đổi qid nếu cần). Ảnh truy vấn sẽ xuất hiện ở top-1 với khoảng cách 0;
-- khi tính chỉ số cần loại ảnh này ra (báo cáo cũng lưu ý điều này ở Phụ lục B.3).
\set qid 1
SELECT embedding::text AS qvec_small  FROM image_features_small  WHERE id = :qid \gset
SELECT embedding::text AS qvec_medium FROM image_features_medium WHERE id = :qid \gset
SELECT embedding::text AS qvec_large  FROM image_features_large  WHERE id = :qid \gset

-- Exact Search: tắt index scan trong transaction để chắc chắn là quét tuần tự.
-- 2048D dùng float32 (vector) theo Bảng 3.2b ("float32 chuẩn"); biểu thức này cũng không khớp
-- expression index halfvec nên planner không dùng ANN index.
BEGIN;
SET LOCAL enable_indexscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, image_path, category, embedding <=> :'qvec_small'::vector(64) AS cosine_distance
FROM image_features_small
ORDER BY embedding <=> :'qvec_small'::vector(64)
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, image_path, category, embedding <=> :'qvec_medium'::vector(512) AS cosine_distance
FROM image_features_medium
ORDER BY embedding <=> :'qvec_medium'::vector(512)
LIMIT 10;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, image_path, category, embedding <=> :'qvec_large'::vector(2048) AS cosine_distance
FROM image_features_large
ORDER BY embedding <=> :'qvec_large'::vector(2048)
LIMIT 10;
COMMIT;