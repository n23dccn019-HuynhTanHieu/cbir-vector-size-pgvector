-- 06_runtime_tuning.sql
-- Nguồn: mục 3.2.3 (2) "Tối ưu hóa tham số Runtime Tuning trong SQL"
--
-- Các tham số này chỉ có hiệu lực trong phiên (session) hiện tại. Khi benchmark bằng Python,
-- phải SET trên cùng connection với câu truy vấn (python/benchmark_latency.py làm đúng điều này).

-- IVFFlat: số cụm (list) được duyệt khi truy vấn. Chi phí truy vấn tăng ~ tuyến tính theo probes.
SET ivfflat.probes = 1;    -- Recall thấp, latency rất thấp (chỉ duyệt 1 cụm)
SET ivfflat.probes = 32;   -- Duyệt nhiều cụm hơn; Recall ANN phải đo, không bảo đảm 95%

-- HNSW: kích thước danh sách ứng viên động khi duyệt đồ thị.
SET hnsw.ef_search = 100;  -- giá trị minh họa ở mục 3.2.3
SET hnsw.ef_search = 64;   -- giá trị dùng trong Phụ lục B / Bảng 3.2b
SET hnsw.ef_search = 128;  -- giá trị cao nhất trong Bảng 3.2b
