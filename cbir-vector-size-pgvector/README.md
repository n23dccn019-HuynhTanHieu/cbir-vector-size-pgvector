# Ảnh hưởng của kích thước vector đặc trưng đến hiệu quả CBIR (PostgreSQL + pgvector)

Mã SQL và script đo đạc đi kèm báo cáo *"Nghiên cứu ảnh hưởng của kích thước vector đặc trưng đến hiệu quả CBIR"*.
Repo chỉ chứa phần **cơ sở dữ liệu và benchmark**; mã trích xuất đặc trưng (Color Histogram, BoVW, ResNet-50) không nằm ở đây.

## Nội dung thực nghiệm

| Mức vector | Chiều | Đặc trưng |
|---|---|---|
| Small | 64 | Color Histogram |
| Medium | 512 | Bag-of-Visual-Words |
| Large | 2048 | ResNet-50 embeddings |

Ba cách truy vấn được so sánh trên mỗi mức: **Exact Search** (quét tuần tự, làm baseline và ground truth),
**IVFFlat** và **HNSW**. Ba tiêu chí đánh giá: độ chính xác (mAP@10, Precision@10, Recall@10),
độ trễ (Median / P95 / QPS) và dung lượng index (`pg_relation_size`).

Dữ liệu theo mô tả báo cáo: 100.000 ảnh, 10 danh mục, tập truy vấn 1.000 ảnh.

## Cấu trúc repo

```
sql/
  00_extension.sql           Bật pgvector
  01_schema.sql              3 bảng vector 64 / 512 / 2048 chiều
  02_load_random_data.sql     Tạo random vector
  03_baseline_exact_btree.sql  B-Tree metadata + Exact Search (baseline)
  04_index_ivfflat.sql       Tạo index IVFFlat
  05_index_hnsw.sql          Tạo index HNSW
  06_query_topk.sql          Truy vấn Top-10 cosine
  07_runtime_tuning.sql      ivfflat.probes, hnsw.ef_search
  08_explain_analyze.sql     Kiểm tra plan có dùng index
  09_storage_size.sql        Đo dung lượng bảng và index
  10_matrix_ivfflat.sql      Ma trận lists × probes (Bảng 3.3)
  11_matrix_hnsw.sql         Ma trận m × ef_construction × ef_search (Bảng 3.3)
  99_reset.sql               Xóa ANN index / làm lại
python/
  benchmark_latency.py       Đo độ trễ Top-K (Phụ lục B.3)
requirements.txt
```

## Đối chiếu script với các phần của báo cáo

| Script | Mục trong báo cáo | Phần thực nghiệm |
|---|---|---|
| `00`, `01` | 3.2.1, Phụ lục A.1, B.1 | Thiết kế schema |
| `02` | 3.2.2 (1), Bảng 3.2b | Baseline Exact Search, B-Tree metadata |
| `03` | 3.2.2 (2), Phụ lục B.2, Bảng 3.1 | Index IVFFlat, thời gian xây dựng |
| `04` | 3.2.2 (3), Phụ lục B.2, Bảng 3.2 | Index HNSW, thời gian xây dựng |
| `05` | 3.2.3 (1) | Truy vấn Top-K |
| `06` | 3.2.3 (2) | Tối ưu tham số runtime |
| `07` | 3.2.3 (3) | Phân tích kế hoạch thực thi |
| `08` | 3.3.2 (3), Bảng 3.2b, 3.6 | Tiêu chí 3: dung lượng index |
| `09`, `10` | 3.3.4, Bảng 3.3 | Ma trận tham số / tái lập thí nghiệm |
| `benchmark_latency.py` | 3.3.2 (2), Phụ lục B.3 | Tiêu chí 2: độ trễ |

Tiêu chí 1 (mAP / Precision / Recall) tính ở phía Python từ kết quả truy vấn; repo chưa có script cho phần này.

## Yêu cầu

- PostgreSQL 16
- pgvector **>= 0.7.0** (cần kiểu `halfvec` để index vector 2048 chiều, vì index trên `vector` chỉ hỗ trợ tối đa 2000 chiều)
- Python 3.10+ với `numpy`, `psycopg2-binary`

## Cài đặt

```bash
# PostgreSQL 16 + pgvector (Ubuntu, theo Phụ lục A.1)
sudo apt update && sudo apt install -y postgresql-16 postgresql-contrib
sudo apt install -y git build-essential postgresql-server-dev-16
git clone https://github.com/pgvector/pgvector.git && cd pgvector && make && sudo make install

# Python
python3 -m venv cbir_env && source cbir_env/bin/activate
pip install -r requirements.txt
```

Môi trường đầy đủ để trích xuất đặc trưng (torch, opencv, faiss...) xem Phụ lục A.2 của báo cáo.

## Cách chạy

```bash
createdb cbir_db
psql -d cbir_db -f sql/00_extension.sql
psql -d cbir_db -f sql/01_schema.sql

# >>> Nạp vector vào 3 bảng image_features_* (từ code trích xuất đặc trưng của bạn) <<<
# Phải nạp dữ liệu TRƯỚC khi tạo ANN index (IVFFlat phân cụm trên dữ liệu có sẵn).

psql -d cbir_db -f sql/03_baseline_exact_btree.sql   # baseline
psql -d cbir_db -f sql/04_index_ivfflat.sql          # đo IVFFlat
psql -d cbir_db -f sql/08_explain_analyze.sql        # xác nhận dùng index
psql -d cbir_db -f sql/09_storage_size.sql

psql -d cbir_db -f sql/99_reset.sql                  # bỏ index cũ
psql -d cbir_db -f sql/05_index_hnsw.sql             # đo HNSW
psql -d cbir_db -f sql/08_explain_analyze.sql
psql -d cbir_db -f sql/09_storage_size.sql

PGPASSWORD=... python python/benchmark_latency.py
```

Ma trận tham số:

```bash
for l in 100 316 1000; do psql -d cbir_db -v lists=$l -f sql/09_matrix_ivfflat.sql > logs/ivfflat_lists${l}.log; done
for m in 8 16 32; do for efc in 64 128; do
  psql -d cbir_db -v m=$m -v efc=$efc -f sql/10_matrix_hnsw.sql > logs/hnsw_m${m}_efc${efc}.log
done; done
```

Quy trình đo theo mục 3.3.3: nạp dữ liệu, dựng index, warm-up 100 truy vấn, chạy 1.000 truy vấn thật × 10 lần,
ghi log (Precision, Recall, latency, kích thước index) rồi lấy trung bình và độ lệch chuẩn.

## Lưu ý quan trọng

1. **Hai biến thể schema.** Báo cáo có hai bộ tên bảng: mục 3.2 (`images` + `feature_*_N`) và Phụ lục B (`image_features_*`).
   Repo dùng bộ Phụ lục B; không chạy lẫn hai bộ. Dọn bộ cũ bằng `99_reset.sql`.
2. **Vector 2048 chiều dùng `halfvec`.** Index được tạo trên biểu thức `embedding::halfvec(2048)`, nên mọi truy vấn muốn dùng index
   phải dùng đúng biểu thức đó. Độ chính xác trong index là float16, không phải float32. Baseline Exact Search 2048D chạy bằng float32.
3. **Mỗi bảng chỉ nên có một ANN index khi đo.** Nếu có cả IVFFlat và HNSW, planner tự chọn; hãy kiểm tra bằng `07_explain_analyze.sql`.
4. **Dung lượng bảng.** `pg_relation_size` không tính TOAST; với vector lớn có thể thấp hơn dung lượng thực.
   `08_storage_size.sql` in thêm `pg_table_size` để đối chiếu.
5. **Số liệu trong bản thảo chưa kiểm chứng hết** (theo chính ghi chú của báo cáo): đơn vị thời gian xây dựng index ở Bảng 3.1 / 3.2 chưa xác minh,
   giá trị Recall CBIR@10 ở Bảng 3.4 chưa nhất quán với số ảnh liên quan mỗi truy vấn, và nhánh PCA (64 / 512 / 1536 chiều trên cùng ResNet-50) chưa có phép đo.
   Bảng 3.3 là lưới tham số đề xuất, chưa phải dữ liệu đã chạy. README này vì vậy không sao chép bảng kết quả nào.
6. Các tham số `lists = 316 / 1000`, `m = 16`, `ef_construction = 64` là giá trị khảo sát, không phải cấu hình tối ưu được bảo đảm.
   So sánh các index nên thực hiện tại cùng mức Recall ANN@10.
7. Mỗi lần đo nên ghi lại phiên bản PostgreSQL và pgvector, CPU/RAM, số truy vấn, số lần lặp, chế độ cache, seed và kiểu dữ liệu (`vector` / `halfvec`).
