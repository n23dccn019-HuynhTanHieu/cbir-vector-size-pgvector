-- 99_reset.sql
-- Nguồn: ghi chú cuối Phụ lục B.2 ("xóa/chuyển index cũ nếu có")
--
-- Xóa toàn bộ ANN index (IVFFlat/HNSW) để về trạng thái Exact Search hoặc để đo từng loại index riêng.
-- Không đụng tới bảng dữ liệu và B-Tree metadata.
DROP INDEX IF EXISTS
    idx_small_ivfflat_cosine,  idx_medium_ivfflat_cosine,  idx_large_ivfflat_cosine,
    idx_small_hnsw_cosine,     idx_medium_hnsw_cosine,     idx_large_hnsw_cosine,
    idx_large_ivfflat_matrix,  idx_large_hnsw_matrix;

-- Nếu trước đó đã chạy nhầm biến thể schema ở mục 3.2 (images + feature_*_N), bỏ comment để dọn:
-- DROP TABLE IF EXISTS feature_small_64, feature_medium_512, feature_large_2048, images CASCADE;

-- Muốn làm lại từ đầu hoàn toàn (MẤT DỮ LIỆU, phải nạp lại vector), bỏ comment:
-- DROP TABLE IF EXISTS image_features_small, image_features_medium, image_features_large;
