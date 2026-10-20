-- 01_schema.sql
-- Nguồn: Phụ lục B.1 (DDL tạo bảng lưu vector 3 mức kích thước)
--
-- Repo dùng biến thể schema của Phụ lục B (image_features_*), vì benchmark Python
-- và các bảng kết quả 3.1 / 3.2 / 3.2b của báo cáo dùng bộ tên này.
-- Biến thể trong mục 3.2 (images + feature_*_N) KHÔNG được trộn với bộ này.

-- Small: Color Histogram, d = 64
CREATE TABLE IF NOT EXISTS image_features_small (
    id         SERIAL PRIMARY KEY,
    image_path VARCHAR(512) NOT NULL,
    category   VARCHAR(100) NOT NULL,
    embedding  vector(64)   NOT NULL
);

-- Medium: Bag-of-Visual-Words, d = 512
CREATE TABLE IF NOT EXISTS image_features_medium (
    id         SERIAL PRIMARY KEY,
    image_path VARCHAR(512) NOT NULL,
    category   VARCHAR(100) NOT NULL,
    embedding  vector(512)  NOT NULL
);

-- Large: ResNet-50 embeddings, d = 2048 (lưu float32, index qua halfvec ở bước sau)
CREATE TABLE IF NOT EXISTS image_features_large (
    id         SERIAL PRIMARY KEY,
    image_path VARCHAR(512) NOT NULL,
    category   VARCHAR(100) NOT NULL,
    embedding  vector(2048) NOT NULL
);
