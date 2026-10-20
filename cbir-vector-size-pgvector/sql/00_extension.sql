-- 00_extension.sql
-- Nguồn: Phụ lục A.1, mục 3.2.1 (bước 1)
-- Kích hoạt pgvector. Cần pgvector >= 0.7.0 vì vector 2048D được index qua kiểu halfvec.
CREATE EXTENSION IF NOT EXISTS vector;
