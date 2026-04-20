module wrapper(
    input   logic           CLOCK_50,    // Xung clock 50MHz từ board
    
    input   logic   [17:0]  SW,          // 18 công tắc gạt
    
    output  logic   [17:0]  LEDR,        // 18 LED đỏ
    output  logic   [8:0]   LEDG,        // 9 LED xanh lá

    output  logic   [6:0]   HEX0, HEX1, HEX2, HEX3,
    output  logic   [6:0]   HEX4, HEX5, HEX6, HEX7,
    
    output  logic           LCD_BLON,    // Điều khiển đèn nền LCD
    output  logic           LCD_ON,      // Bật/tắt LCD
    output  logic           LCD_EN,      // Xung Enable LCD
    output  logic           LCD_RS,      // Lựa chọn thanh ghi (Register Select)
    output  logic           LCD_RW,      // Read/Write LCD
    output  logic   [7:0]   LCD_DATA     // Bus dữ liệu 8-bit cho LCD
);

    // --- Các tín hiệu nội bộ nối giữa Wrapper và CPU ---
    logic [31:0] io_sw;
    logic [31:0] io_lcd;
    logic [31:0] io_ledg;
    logic [31:0] io_ledr;
    logic [31:0] pc_debug;
    logic        insn_vld;

    // --- Xử lý tín hiệu đầu vào (Input Mapping) ---
    // Gán 18 công tắc vào bus 32-bit. SW[17] là chân Reset hệ thống.
    assign io_sw = {14'b0, SW[17:0]};

    // --- Xử lý tín hiệu đầu ra (Output Mapping) ---
    // LED Đỏ: 17 LED đầu hiển thị dữ liệu, LEDR[17] sáng khi đang Reset.
    assign LEDR[16:0] = io_ledr[16:0];
    assign LEDR[17]   = ~SW[17]; 

    // LED Xanh: 8 LED đầu hiển thị dữ liệu, LEDG[8] báo lệnh hợp lệ (Debug)[cite: 71, 377, 421].
    assign LEDG[7:0]  = io_ledg[7:0];
    assign LEDG[8]    = insn_vld; 

    // Giao tiếp LCD: Tách các bit từ register 32-bit ra các chân vật lý[cite: 430].
    assign LCD_DATA   = io_lcd[7:0];
    assign LCD_RW     = io_lcd[8];
    assign LCD_RS     = io_lcd[9];
    assign LCD_EN     = io_lcd[10];
    assign LCD_ON     = io_lcd[31];
    assign LCD_BLON   = 1'b0; // Luôn tắt đèn nền hoặc gán cố định

    // --- Bộ chia xung Clock (50MHz -> 1MHz) ---
    // Giúp CPU chạy ở tốc độ phù hợp để quan sát và đáp ứng thời gian thực của ngoại vi.
    logic [5:0] clk_count = 6'd0;
    logic       clk_1mhz  = 1'b0;
    
    always_ff @(posedge CLOCK_50 or negedge SW[17]) begin
        if (!SW[17]) begin
            clk_count <= 6'd0;
            clk_1mhz  <= 1'b0;
        end else begin
            if (clk_count == 6'd24) begin
                clk_count <= 6'd0;
                clk_1mhz  <= ~clk_1mhz;
            end else begin
                clk_count <= clk_count + 1'b1;
            end
        end
    end

    // --- Khởi tạo bộ xử lý Single Cycle ---
    single_cycle singleCycle_inst (
        .i_clk        (clk_1mhz),    // Xung clock đã chia
        .i_rstn      (SW[17]),      // Reset hệ thống (Active Low) 
        .i_io_sw      (io_sw),       // Dữ liệu từ Switch [cite: 180, 432]
.o_insn_vld   (insn_vld),    // Báo lệnh hợp lệ [cite: 164, 377]
        .o_io_hex0    (HEX0), .o_io_hex1 (HEX1),
        .o_io_hex2    (HEX2), .o_io_hex3 (HEX3),
        .o_io_hex4    (HEX4), .o_io_hex5 (HEX5),
        .o_io_hex6    (HEX6), .o_io_hex7 (HEX7),
        
        .o_pc_debug   (pc_debug),    // Debug PC qua Signal Tap hoặc các LED [cite: 163, 180]
        .o_io_ledr    (io_ledr),     // Dữ liệu điều khiển LED đỏ [cite: 160, 416]
        .o_io_ledg    (io_ledg),     // Dữ liệu điều khiển LED xanh [cite: 160, 420]
        .o_io_lcd     (io_lcd)       // Dữ liệu điều khiển LCD [cite: 161, 427]
    );

endmodule
