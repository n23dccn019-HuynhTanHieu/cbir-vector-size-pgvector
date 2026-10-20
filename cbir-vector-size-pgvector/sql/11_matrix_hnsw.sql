-- 10_matrix_hnsw.sql
-- Nguồn: mục 3.3.4, Bảng 3.3 (ma trận thí nghiệm HNSW: m ∈ {8, 16, 32}; ef_construction ∈ {64, 128};
--        ef_search ∈ {32, 64, 128})
--
-- Bảng 3.3 là LƯỚI ĐỀ XUẤT, chưa phải dữ liệu đã đo. Áp dụng cho bảng Large (2048D, halfvec).
-- Mỗi lần chạy xử lý MỘT cặp (m, ef_construction); ef_search được quét trong file:
--
--   for m in 8 16 32; do for efc in 64 128; do
--     psql -d cbir_db -v m=$m -v efc=$efc -f sql/10_matrix_hnsw.sql > logs/hnsw_m${m}_efc${efc}.log
--   done; done

\if :{?m}
\else
  \echo 'Thiếu tham số m. Ví dụ: psql -d cbir_db -v m=16 -v efc=64 -f sql/10_matrix_hnsw.sql'
  \quit
\endif
\if :{?efc}
\else
  \echo 'Thiếu tham số efc. Ví dụ: psql -d cbir_db -v m=16 -v efc=64 -f sql/10_matrix_hnsw.sql'
  \quit
\endif
\if :{?qid}
\else
  \set qid 1
\endif

SELECT embedding::text AS qvec_large FROM image_features_large WHERE id = :qid \gset

DROP INDEX IF EXISTS idx_large_ivfflat_cosine, idx_large_hnsw_cosine,
                     idx_large_ivfflat_matrix, idx_large_hnsw_matrix;

\echo '=== HNSW build: m =' :m ', ef_construction =' :efc
\timing on
CREATE INDEX idx_large_hnsw_matrix
ON image_features_large
USING hnsw ((embedding::halfvec(2048)) halfvec_cosine_ops)
WITH (m = :m, ef_construction = :efc);
\timing off

SELECT pg_size_pretty(pg_relation_size('idx_large_hnsw_matrix')) AS index_size,
       pg_relation_size('idx_large_hnsw_matrix') AS index_bytes;

-- Quét ef_search ∈ {32, 64, 128}
\echo '--- m =' :m ', ef_construction =' :efc ', ef_search = 32'
SET hnsw.ef_search = 32;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;

\echo '--- m =' :m ', ef_construction =' :efc ', ef_search = 64'
SET hnsw.ef_search = 64;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;

\echo '--- m =' :m ', ef_construction =' :efc ', ef_search = 128'
SET hnsw.ef_search = 128;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM image_features_large
ORDER BY embedding::halfvec(2048) <=> :'qvec_large'::halfvec(2048) LIMIT 10;
