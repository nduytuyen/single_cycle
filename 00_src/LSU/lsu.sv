module lsu (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic [31:0] i_lsu_addr,
    input  logic [31:0] i_st_data,
    input  logic        i_lsu_wren,
    input  logic [2:0]  i_control,
    output logic [31:0] o_ld_data,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
    output logic [31:0] o_io_lcd,
    input  logic [31:0] i_io_sw
);

    logic [31:0] dmem_data;
    logic [31:0] out_buf_data;
    logic [31:0] in_buf_data;

    // ================== MEMORY MAPPING ==================
    logic is_dmem;
    logic is_out_buf;
    logic is_in_buf;

    always_comb begin
        is_dmem    = (i_lsu_addr[31:15] == 17'h00000);     // 0x0000_0000 - 0x0000_7FFF (Data Memory)
        
        // (LEDs, HEX, LCD)
        is_out_buf = (i_lsu_addr[31:16] == 16'h1000);      // 0x1000_0000 - 0x1000_FFFF
        
        is_in_buf  = (i_lsu_addr[31:12] == 20'h10010);     // 0x1001_0000 - 0x1001_0FFF (Switches)
    end

    // Load data mux
    always_comb begin
        if      (is_dmem)    o_ld_data = dmem_data;
       // else if (is_out_buf) o_ld_data = out_buf_data;
       else if (is_in_buf)  o_ld_data = in_buf_data;
        else                 o_ld_data = 32'h0;
    end

    // Instantiate sub-modules
    input_buffer i_buf (
        .i_ctrl    (i_control),
        .i_addr    (i_lsu_addr[15:12]),
        .i_switch  (i_io_sw),
        .o_in_buf_data(in_buf_data)
    );

    output_buffer o_buf (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_write_en (i_lsu_wren & is_out_buf),
        .i_ctrl     (i_control),
        .i_addr     (i_lsu_addr[15:12]),
        .i_wdata    (i_st_data),
        .o_rdata    (out_buf_data),
        .o_ledr     (o_io_ledr),
        .o_ledg     (o_io_ledg),
        .o_hex0     (o_io_hex0), .o_hex1(o_io_hex1),
        .o_hex2     (o_io_hex2), .o_hex3(o_io_hex3),
        .o_hex4     (o_io_hex4), .o_hex5(o_io_hex5),
        .o_hex6     (o_io_hex6), .o_hex7(o_io_hex7),
        .o_lcd      (o_io_lcd)
    );

    data_memory dmem (
        .i_clk          (i_clk),
        .i_addr         (i_lsu_addr[11:0]),      // 2KB
        .i_st_data      (i_st_data),
        .i_write_enable (i_lsu_wren & is_dmem),
        .i_ctrl         (i_control),
        .o_memory_data  (dmem_data)
    );

endmodule
