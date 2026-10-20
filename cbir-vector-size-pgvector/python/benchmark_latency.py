"""
Benchmark độ trễ truy vấn Top-K trên PostgreSQL + pgvector (2048D, halfvec).

Nguồn: Phụ lục B.3 của báo cáo. Logic đo giữ nguyên; chỉ thay thông tin kết nối cứng
bằng biến môi trường để không commit mật khẩu lên GitHub.

Biến môi trường: PGDATABASE (mặc định cbir_db), PGUSER (postgres), PGPASSWORD,
                 PGHOST (localhost), PGPORT (5432)

Lưu ý (theo báo cáo): script chỉ ghi latency phía client, không tự tính mAP / Recall ANN.
Cần chạy Exact Search riêng làm ground truth và loại ảnh truy vấn nếu nó nằm trong DB.
"""
import os
import time

import numpy as np
import psycopg2


def benchmark_query_latency(conn, query_vector: np.ndarray,
                            table_name: str, index_type: str,
                            k: int = 10, num_runs: int = 100):
    cursor = conn.cursor()
    vec_str = "[" + ",".join(map(str, query_vector.tolist())) + "]"

    if index_type == "IVFFLAT":
        cursor.execute("SET ivfflat.probes = 32;")
    elif index_type == "HNSW":
        cursor.execute("SET hnsw.ef_search = 64;")

    # Đây là benchmark minh họa RIÊNG 2048D; với 64/512D phải dùng
    # embedding <=> %s::vector(d) và tạo index phù hợp.
    # table_name chỉ được nhận từ allowlist tin cậy, không lấy trực tiếp từ nhập liệu.
    if table_name != "image_features_large":
        raise ValueError("Mẫu benchmark này chỉ dành cho image_features_large (2048D)")

    sql_query = f"""
        SELECT id, image_path, category,
               (embedding::halfvec(2048) <=> %s::halfvec(2048)) AS distance
        FROM {table_name}
        ORDER BY embedding::halfvec(2048) <=> %s::halfvec(2048)
        LIMIT %s;
    """

    latencies = []
    for _ in range(num_runs):
        start_time = time.perf_counter()
        cursor.execute(sql_query, (vec_str, vec_str, k))
        _ = cursor.fetchall()
        end_time = time.perf_counter()
        latencies.append((end_time - start_time) * 1000.0)  # ms

    cursor.close()
    avg_latency = np.mean(latencies[10:])  # Loại bỏ 10 lần warm-up
    return avg_latency


if __name__ == "__main__":
    connection = psycopg2.connect(
        dbname=os.getenv("PGDATABASE", "cbir_db"),
        user=os.getenv("PGUSER", "postgres"),
        password=os.getenv("PGPASSWORD"),
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
    )
    dummy_query = np.random.randn(2048).astype(np.float32)
    dummy_query /= np.linalg.norm(dummy_query)

    latency = benchmark_query_latency(connection, dummy_query, "image_features_large", "HNSW")
    print(f"Thời gian truy vấn trung bình HNSW (d=2048): {latency:.2f} ms")
    connection.close()
