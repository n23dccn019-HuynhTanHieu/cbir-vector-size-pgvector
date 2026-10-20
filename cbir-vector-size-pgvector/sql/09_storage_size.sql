-- 08_storage_size.sql
-- Nguồn: mục 3.3.2 (3) "Dung lượng lưu trữ Index"; Bảng 3.2b, Bảng 3.6
--
-- Báo cáo đo dung lượng bằng pg_relation_size. Hàm này chỉ tính file chính của quan hệ
-- (không gồm TOAST). Với vector chiều lớn (đặc biệt 2048D ~ 8 KB/dòng) dữ liệu có thể nằm
-- trong TOAST, nên script này xuất thêm pg_table_size / pg_total_relation_size để đối chiếu
-- với dung lượng bảng thô lý thuyết N * d * 4 byte.

-- 1) Từng index trên các bảng image_features_*
SELECT c.relname                                         AS table_name,
       i.relname                                         AS index_name,
       am.amname                                         AS access_method,
       round(pg_relation_size(c.oid) / 1048576.0, 2)     AS table_mb_relation_size,
       round(pg_table_size(c.oid)    / 1048576.0, 2)     AS table_mb_incl_toast,
       round(pg_relation_size(i.oid) / 1048576.0, 2)     AS index_mb,
       round(100.0 * pg_relation_size(i.oid)
             / NULLIF(pg_relation_size(c.oid), 0), 1)    AS index_pct_of_table
FROM pg_index x
JOIN pg_class c ON c.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_am   am ON am.oid = i.relam
WHERE c.relname LIKE 'image_features_%'
ORDER BY c.relname, i.relname;

-- 2) Ví dụ gốc ở mục 3.3.2 (đã đổi tên index theo schema của repo)
SELECT pg_size_pretty(pg_relation_size('idx_large_hnsw_cosine')) AS index_size;

-- 3) Số dòng mỗi bảng (đối chiếu N = 100.000 của báo cáo)
SELECT 'small'  AS tbl, count(*) FROM image_features_small
UNION ALL SELECT 'medium', count(*) FROM image_features_medium
UNION ALL SELECT 'large',  count(*) FROM image_features_large;
