# --- THIẾT LẬP ĐỊA CHỈ THEO MAPPING MỚI (MILESTONE 2 SPEC) ---
li x23, 0x10010000    # Địa chỉ SWITCH 
li x21, 0x10002000    # Địa chỉ LED HEX 3-0 
li x24, 0x10003000    # Địa chỉ LED HEX 7-4 

# Reset tất cả các đèn về 0 ban đầu
li x22, 0xC0      # Mã 7 đoạn cho số 0
sb x22, 0(x21)    # HEX0 = 0
sb x22, 1(x21)    # HEX1 = 0  
sb x22, 2(x21)    # HEX2 = 0
sb x22, 3(x21)    # HEX3 = 0

sb x22, 0(x24)    # HEX4 = 0 (Ghi vào byte 0 của 0x10003000)
sb x22, 1(x24)    # HEX5 = 0
sb x22, 2(x24)    # HEX6 = 0
sb x22, 3(x24)    # HEX7 = 0

# Khởi tạo các biến đếm
li x12, 0         # HEX0 = 0 
li x13, 0         # HEX1 = 0
li x14, 0         # HEX2 = 0 
li x15, 0         # HEX3 = 0
li x20, 10        # Giới hạn đếm decimal (0-9)

li x4 , 0x10010000    # Địa chỉ đọc SWITCH 
MAIN_LOOP:
    # Kiểm tra nếu đạt 1000
    li x30, 0x01          # So sánh với 1   
    lw x5, 0(x4)          # Đọc giá trị switch
    beq x5, x30, DISPLAY  # Nếu bật SW0 thì nhảy đến DISPLAY (tạm dừng)
    beq x15, x30, CHECK_1000  # Nếu HEX3 = 1, kiểm tra các chữ số còn lại
    j COUNT               # Nếu chưa đạt, tiếp tục đếm
    
CHECK_1000:
    bne x14, x0, COUNT 
    bne x13, x0, COUNT
    bne x12, x0, COUNT
    j RESET               # Reset về 0 nếu đạt 1000

COUNT:
    # Tăng HEX0
    addi x12, x12, 1       # HEX0 + 1
    blt x12, x20, DISPLAY  # Nếu < 10, hiển thị
    
    # Reset HEX0, tăng HEX1
    li x12, 0              
    addi x13, x13, 1
    blt x13, x20, DISPLAY
    
    # Reset HEX1, tăng HEX2
    li x13, 0
    addi x14, x14, 1
    blt x14, x20, DISPLAY
    
    # Reset HEX2, tăng HEX3
    li x14, 0
    addi x15, x15, 1
    blt x15, x20, DISPLAY

RESET:
    li x12, 0              # Reset tất cả về 0
    li x13, 0
    li x14, 0
    li x15, 0

DISPLAY:
    # Chuyển đổi và hiển thị HEX0
    add x16, x0, x12       # Copy giá trị cần chuyển đổi
    jal x1, BCD_TO_HEX     # Chuyển sang mã 7 đoạn
    sb x22, 0(x21)         # Hiển thị HEX0
    
    # Chuyển đổi và hiển thị HEX1
    add x16, x0, x13
    jal x1, BCD_TO_HEX
    sb x22, 1(x21)
    
    # Chuyển đổi và hiển thị HEX2
    add x16, x0, x14
    jal x1, BCD_TO_HEX
    sb x22, 2(x21)
    
    # Chuyển đổi và hiển thị HEX3
    add x16, x0, x15
    jal x1, BCD_TO_HEX
    sb x22, 3(x21)

    # Delay 0.5s
    li x29, 5              # 5 * 100ms = 0.5s
    jal x1, DELAY_n_100ms
    
    j MAIN_LOOP           # Lặp lại

# Hàm chuyển đổi BCD sang mã 7 đoạn
BCD_TO_HEX:
    # Input: x16 (số BCD)
    # Output: x22 (mã 7 đoạn)
    
    ZERO:
        li x30, 0
        bne x16, x30, ONE
        li x22, 0xC0       # Mã cho số 0
        ret
    ONE:
        li x30, 1
        bne x16, x30, TWO
        li x22, 0xF9       # Mã cho số 1
        ret
    TWO:
        li x30, 2
        bne x16, x30, THREE
        li x22, 0xA4       # Mã cho số 2
        ret
    THREE:
        li x30, 3
        bne x16, x30, FOUR
        li x22, 0xB0       # Mã cho số 3
        ret
    FOUR:
        li x30, 4
        bne x16, x30, FIVE
        li x22, 0x99       # Mã cho số 4
        ret
    FIVE:
        li x30, 5
        bne x16, x30, SIX
        li x22, 0x92       # Mã cho số 5
        ret
    SIX:
        li x30, 6
        bne x16, x30, SEVEN
        li x22, 0x82       # Mã cho số 6
        ret
    SEVEN:
        li x30, 7
        bne x16, x30, EIGHT
        li x22, 0xF8       # Mã cho số 7
        ret
    EIGHT:
        li x30, 8
        bne x16, x30, NINE
        li x22, 0x80       # Mã cho số 8
        ret
    NINE:
        li x22, 0x90       # Mã cho số 9
        ret

# Hàm delay
DELAY_n_100ms:
    # Input: x29 (số lần delay 100ms)
DELAY_100ms:
    li x31, 100000         # 100,000 cycles ở 1MHz = 100ms
    LOOP_DELAY:
        addi x31, x31, -1
        beq x31, x0, NEXT_DELAY
        j LOOP_DELAY
    NEXT_DELAY:
        addi x29, x29, -1
        bgt x29, x0, DELAY_100ms
        ret