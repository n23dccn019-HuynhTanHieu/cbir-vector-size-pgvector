-- 09_matrix_ivfflat.sql
-- Nguồn: mục 3.3.4, Bảng 3.3 (ma trận thí nghiệm IVFFlat: lists ∈ {100, 316, 1000}; probes ∈ {1, 8, 32, 64})
--
-- Bảng 3.3 là LƯỚI ĐỀ XUẤT, chưa phải dữ liệu đã đo. Script áp dụng cho bảng Large (2048D, halfvec);
-- muốn khảo sát 64D / 512D thì đổi tên bảng và bỏ phần ép kiểu halfvec.
-- Mỗi lần chạy xử lý MỘT giá trị lists (tránh nhiều index cùng tồn tại làm planner chọn lẫn):
--
--   for l in 100 316 1000; do
--     psql -d cbir_db -v lists=$l -f sql/09_matrix_ivfflat.sql > logs/ivfflat_lists${l}.log
--   done
--
-- Latency Median/P95 và Recall ANN@10 đo bằng Python; file này tạo index, ghi build time (\timing),
-- dung lượng, và xác nhận plan cho từng giá trị probes.

\if :{?lists}
\else
  \echo 'Thiếu tham số lists. Ví dụ: psql -d cbir_db -v lists=100 -f sql/09_matrix_ivfflat.sql'
  \quit
\endif
\if :{?qid}
\else
  \set qid 1
\endif

SELECT embedding::text AS qvec_large FROM image_features_large WHERE id = :qid \gset

-- Dọn mọi ANN index trên bảng Large để chỉ còn đúng index đang khảo sát
DROP INDEX IF EXISTS idx_large_ivfflat_cosine, idx_large_hnsw_cosine,
                     idx_large_ivfflat_matrix, idx_large_hnsw_matrix;

\echo '=== IVFFlat build: lists =' :lists
\timing on
CREATE INDEX idx_large_ivfflat_matrix
ON image_features_large
USING ivfflat ((embedding::halfvec(2048)) halfvec_cosine_ops)
WITH (lists = :lists);
\timing off

SELECT pg_size_pretty(pg_relation_size('idx_large_ivfflat_matrix')) AS index_size,
       pg_relation_size('idx_large_ivfflat_matrix') AS index_bytes;

-- Quét probes ∈ {1, 8, 32, 64}
\echo '--- lists =' :lists ', probes = 1'
SET ivfflat.probes = 1;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;

\echo '--- lists =' :lists ', probes = 8'
SET ivfflat.probes = 8;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;

\echo '--- lists =' :lists ', probes = 32'
SET ivfflat.probes = 32;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;

\echo '--- lists =' :lists ', probes = 64'
SET ivfflat.probes = 64;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;
