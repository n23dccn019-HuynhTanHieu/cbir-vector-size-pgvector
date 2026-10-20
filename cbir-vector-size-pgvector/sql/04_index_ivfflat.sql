-- 03_index_ivfflat.sql
-- Nguồn: mục 3.2.2 (2) và Phụ lục B.2; thời gian xây dựng: Bảng 3.1
--
-- Tạo index SAU KHI đã nạp dữ liệu (IVFFlat phân cụm trên dữ liệu có sẵn).
-- lists = 316 (~ sqrt(100.000)) cho 64D, lists = 1000 cho 512D / 2048D là giá trị khảo sát
-- của nhóm, không phải cấu hình tối ưu được bảo đảm (xem 09_matrix_ivfflat.sql).
--
-- Khi một bảng có cả IVFFlat và HNSW, planner tự chọn index. Muốn đo riêng từng loại,
-- chỉ giữ một index trên bảng (xem 99_reset.sql) và xác minh bằng EXPLAIN (07_explain_analyze.sql).

SET maintenance_work_mem = '1GB';
\timing on

-- a) Small (d = 64), cosine
CREATE INDEX IF NOT EXISTS idx_small_ivfflat_cosine
ON image_features_small
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000);

-- b) Medium (d = 512), cosine
CREATE INDEX IF NOT EXISTS idx_medium_ivfflat_cosine
ON image_features_medium
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000);

-- c) Large (d = 2048): cột giữ vector(2048), index qua biểu thức halfvec.
-- Cảnh báo: độ chính xác của index là float16, không phải float32.
CREATE INDEX IF NOT EXISTS idx_large_ivfflat_cosine
ON image_features_large
USING ivfflat ((embedding::halfvec(2048)) halfvec_cosine_ops)
WITH (lists = 1000);

\timing off
