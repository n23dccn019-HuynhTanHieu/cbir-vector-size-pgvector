-- 01b_load_random_data.sql
-- KHÔNG có trong báo cáo. Chỉ để chạy thử các script SQL khi chưa có vector thật.
--
-- Nạp 100.000 vector NGẪU NHIÊN cho mỗi bảng (đúng N của báo cáo). Nhãn category (cat_0..cat_9) không liên hệ
-- gì với nội dung vector, nên mAP / Precision / Recall đo trên dữ liệu này KHÔNG có ý nghĩa.
-- Độ trễ, build time và dung lượng index vẫn tham khảo được vì chỉ phụ thuộc kích thước dữ liệu.
-- Khi có vector thật (Color Histogram, BoVW, ResNet-50), TRUNCATE các bảng rồi nạp dữ liệu thật.
--
-- Chạy TỪNG KHỐI một, chạy 1 lần duy nhất mỗi khối (chạy lại sẽ nhân đôi dòng).
-- Khối large (2048 chiều) chậm nhất, chiếm ~1 GB đĩa.
-- Làm lại: TRUNCATE image_features_small, image_features_medium, image_features_large RESTART IDENTITY;

-- Khối 1: small (64 chiều)
SELECT setseed(0.42);
INSERT INTO image_features_small (image_path, category, embedding)
SELECT 'img_' || i, 'cat_' || (i % 10),
       (SELECT array_agg(random()) FROM generate_series(1, 64) WHERE i IS NOT NULL)::vector
FROM generate_series(1, 100000) AS i;

-- Khối 2: medium (512 chiều)
SELECT setseed(0.42);
INSERT INTO image_features_medium (image_path, category, embedding)
SELECT 'img_' || i, 'cat_' || (i % 10),
       (SELECT array_agg(random()) FROM generate_series(1, 512) WHERE i IS NOT NULL)::vector
FROM generate_series(1, 100000) AS i;

-- Khối 3: large (2048 chiều)
SELECT setseed(0.42);
INSERT INTO image_features_large (image_path, category, embedding)
SELECT 'img_' || i, 'cat_' || (i % 10),
       (SELECT array_agg(random()) FROM generate_series(1, 2048) WHERE i IS NOT NULL)::vector
FROM generate_series(1, 100000) AS i;

-- Khối 4: cập nhật thống kê và kiểm tra (mỗi bảng phải ra 100000)
ANALYZE image_features_small;
ANALYZE image_features_medium;
ANALYZE image_features_large;

SELECT 'small' AS tbl, count(*) FROM image_features_small
UNION ALL SELECT 'medium', count(*) FROM image_features_medium
UNION ALL SELECT 'large',  count(*) FROM image_features_large;
