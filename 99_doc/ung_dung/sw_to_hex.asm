# ==============================================================================
# PHẦN 1: KHỞI TẠO ĐỊA CHỈ NGOẠI VI
# ==============================================================================
    lui t0, 0x10010       # t0 (x5)  = 0x10010000 (Địa chỉ cơ sở của Switches)
    lui t1, 0x10002       # t1 (x6)  = 0x10002000 (Địa chỉ cơ sở của LED HEX 3-0)
    lui t2, 0x10003       # t2 (x7)  = 0x10003000 (Địa chỉ cơ sở của LED HEX 7-4)

MAIN_LOOP:
# ==============================================================================
# PHẦN 2: ĐỌC DỮ LIỆU TỪ SWITCH & LỌC LẤY 13 BIT
# ==============================================================================
    lw a0, 0(t0)          # a0 (x10) = Đọc trạng thái hiện tại của các công tắc
    lui t5, 0x2           # t5 (x30) = 0x00002000
    addi t5, t5, -1       # t5 = 0x1FFF (Mặt nạ 13 bit, giá trị max là 8191)
    and a0, a0, t5        # a0 &= 0x1FFF (Chỉ lấy 13 công tắc đầu tiên)

# ==============================================================================
# PHẦN 3: TÁCH TỪNG CHỮ SỐ THẬP PHÂN (CHIA LIÊN TỤC CHO 10)
# ==============================================================================
    # Tách hàng đơn vị (Digit 0)
    add a1, a0, zero      # a1 = a0 (Nạp giá trị vào đối số của hàm)
    jal ra, DIV10_MOD10   # Gọi hàm chia 10. (Thương số trả về a2, phần dư trả về a3)
    add s0, a3, zero      # s0 (x8) = Phần dư (Chữ số hàng đơn vị)

    # Tách hàng chục (Digit 1)
    add a1, a2, zero      # Lấy thương số bước trước làm số bị chia mới
    jal ra, DIV10_MOD10
    add s1, a3, zero      # s1 (x9) = Chữ số hàng chục

    # Tách hàng trăm (Digit 2)
    add a1, a2, zero
    jal ra, DIV10_MOD10
    add s2, a3, zero      # s2 (x18) = Chữ số hàng trăm

    # Tách hàng ngàn (Digit 3)
    add a1, a2, zero
    jal ra, DIV10_MOD10
    add s3, a3, zero      # s3 (x19) = Chữ số hàng ngàn

    # Tách hàng chục ngàn (Digit 4)
    add a1, a2, zero
    jal ra, DIV10_MOD10
    add s4, a3, zero      # s4 (x20) = Chữ số hàng chục ngàn

    # Tách hàng trăm ngàn (Digit 5)
    add a1, a2, zero
    jal ra, DIV10_MOD10
    add s5, a3, zero      # s5 (x21) = Chữ số hàng trăm ngàn

# ==============================================================================
# PHẦN 4: GIẢI MÃ VÀ XUẤT RA LED 7 ĐOẠN
# ==============================================================================
    add t3, s0, zero      # Đưa hàng đơn vị vào t3 (x28) để giải mã
    jal ra, HEX_DECODE    # Gọi hàm giải mã LED (Kết quả trả về ở t6/x31)
    sb t6, 0(t1)          # Hiển thị lên HEX0

    add t3, s1, zero
    jal ra, HEX_DECODE
    sb t6, 1(t1)          # Hiển thị lên HEX1

    add t3, s2, zero
    jal ra, HEX_DECODE
    sb t6, 2(t1)          # Hiển thị lên HEX2

    add t3, s3, zero
    jal ra, HEX_DECODE
    sb t6, 3(t1)          # Hiển thị lên HEX3

    add t3, s4, zero
    jal ra, HEX_DECODE
    sb t6, 0(t2)          # Hiển thị lên HEX4

    add t3, s5, zero
    jal ra, HEX_DECODE
    sb t6, 1(t2)          # Hiển thị lên HEX5

    # Ghi số '0' (hoặc khoảng trắng) cố định vào 2 LED cao nhất
    addi t4, zero, 0x40   # t4 = 0x40 (Mã 7 bit của số '0')
    sb t4, 2(t2)          # Ghi '0' ra HEX6
    sb t4, 3(t2)          # Ghi '0' ra HEX7

    jal zero, MAIN_LOOP   # Lặp lại toàn bộ quá trình liên tục

# ==============================================================================
# CHƯƠNG TRÌNH CON: DIV10_MOD10 (Phép chia và lấy dư cho 10)
# ==============================================================================
# Đầu vào: a1 (Số bị chia)
# Đầu ra:  a2 (Thương số), a3 (Phần dư)
DIV10_MOD10:
    add a2, zero, zero    # a2 (Quotient) = 0
    add a3, a1, zero      # a3 (Remainder) = a1
    addi t4, zero, 10     # t4 = 10 (Số chia)
div_loop:
    slt t5, a3, t4        # Nếu phần dư < 10, t5 = 1, ngược lại t5 = 0
    bne t5, zero, div_end # Nếu phần dư < 10, thoát khỏi vòng lặp trừ
    addi a2, a2, 1        # Tăng thương số thêm 1
    addi a3, a3, -10      # Trừ phần dư đi 10
    jal zero, div_loop    # Tiếp tục vòng lặp
div_end:
    jalr zero, ra, 0      # Quay lại nơi gọi hàm

# ==============================================================================
# CHƯƠNG TRÌNH CON: HEX_DECODE (Giải mã số thập phân sang mã LED 7 đoạn)
# ==============================================================================
# Đầu vào: t3 (x28) - Chữ số từ 0 đến 9
# Đầu ra:  t6 (x31) - Mã thập lục phân của LED 7 đoạn tương ứng
HEX_DECODE:
    beq t3, zero, ret_0
    addi t4, zero, 1
    beq t3, t4, ret_1
    addi t4, zero, 2
    beq t3, t4, ret_2
    addi t4, zero, 3
    beq t3, t4, ret_3
    addi t4, zero, 4
    beq t3, t4, ret_4
    addi t4, zero, 5
    beq t3, t4, ret_5
    addi t4, zero, 6
    beq t3, t4, ret_6
    addi t4, zero, 7
    beq t3, t4, ret_7
    addi t4, zero, 8
    beq t3, t4, ret_8

    # Default (Trường hợp số 9)
    addi t6, zero, 0x10   # Mã LED cho số '9'
    jalr zero, ra, 0      # Quay lại

ret_0: 
    addi t6, zero, 0x40   # Mã LED cho số '0'
    jalr zero, ra, 0

ret_1: 
    addi t6, zero, 0x79   # Mã LED cho số '1'
    jalr zero, ra, 0

ret_2: 
    addi t6, zero, 0x24   # Mã LED cho số '2'
    jalr zero, ra, 0

ret_3: 
    addi t6, zero, 0x30   # Mã LED cho số '3'
    jalr zero, ra, 0

ret_4: 
    addi t6, zero, 0x19   # Mã LED cho số '4'
    jalr zero, ra, 0

ret_5: 
    addi t6, zero, 0x12   # Mã LED cho số '5'
    jalr zero, ra, 0

ret_6: 
    addi t6, zero, 0x02   # Mã LED cho số '6'
    jalr zero, ra, 0

ret_7: 
    addi t6, zero, 0x78   # Mã LED cho số '7'
    jalr zero, ra, 0

ret_8: 
    addi t6, zero, 0x00   # Mã LED cho số '8'
    jalr zero, ra, 0