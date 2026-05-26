lui x31, 0x10000      # x31 = 0x10000000 
    lui x30, 0x10010      # x30 = 0x10010000 
loop:
    lw x9, 0(x30)         # Đọc giá trị từ địa chỉ x30 lưu vào x9 
    sw x9, 0(x31)         # Ghi giá trị từ x9 ra địa chỉ x31 
    jal x0, -8            # Nhảy lùi lại 8 byte (tương đương 2 lệnh), quay lại nhãn 'loop'