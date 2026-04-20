module single_cycle(
    input   logic           i_clk, 
    input   logic           i_reset,      // Global active low reset theo specifications
    input   logic   [31:0]  i_io_sw,
    
    output  logic           o_insn_vld,
    output  logic   [6:0]   o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output  logic   [6:0]   o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
    output  logic   [31:0]  o_pc_debug,
    output  logic   [31:0]  o_io_ledr, o_io_ledg, o_io_lcd
);

//------------------------------------------------------------------------------
// PROGRAM COUNTER & PC LOGIC
//------------------------------------------------------------------------------
    wire  [31:0]  pc, pc_next, pc_four;
    wire          pc_sel;

    pc PC_INST (
        .i_clk(i_clk),
        .i_rst_n(i_reset),        // Noi vao i_reset toan cuc
        .i_pc_en(1'b1),
        .i_pc_next(pc_next),
        .o_pc(pc)
    );

    pc_plus4 PC_FOUR_INST (
        .pc(pc),
        .pc_four(pc_four)
    );

    wire  [31:0]  alu_data;
    
    mux_2to1 PC_SELECT (          // 1'b0 -> pc_four, 1'b1 -> alu_data
        .i_sel(pc_sel),
        .i_data_0(pc_four),
        .i_data_1(alu_data),
        .o_data(pc_next)
    );

//------------------------------------------------------------------------------
// INSTRUCTION MEMORY
//------------------------------------------------------------------------------
    wire  [31:0]  instruction;
    wire  [2:0]   func3;
    wire          func7;

    imem IMEM_INST (
        .i_imem_addr(pc),
        .o_imem_data(instruction)
    );

    assign func3 = instruction[14:12];
    assign func7 = instruction[30];

//------------------------------------------------------------------------------
// CONTROL UNIT
//------------------------------------------------------------------------------
    wire          rd_wren, insn_vld, br_un, opa_sel, opb_sel, wr_en, rd_en;
    wire  [1:0]   wb_sel;
    wire          br_less, br_equal;
    wire  [3:0]   alu_op;

    ctrl_unit CONTROL_LOGIC (
        .i_inst(instruction),
        .i_br_less(br_less),
        .i_br_equal(br_equal),
        .o_pc_sel(pc_sel),
        .o_br_un(br_un),
        .o_rd_wren(rd_wren),
        .o_mem_wren(wr_en),
        .o_mem_rden(rd_en),
        .o_opa_sel(opa_sel),
        .o_opb_sel(opb_sel),
        .o_insn_vld(insn_vld),
        .o_wb_sel(wb_sel),
        .o_alu_op(alu_op)
    );

//------------------------------------------------------------------------------
// REGISTER FILE
//------------------------------------------------------------------------------
    wire  [4:0] rs1_addr, rs2_addr, rd_addr;
    wire  [31:0] rs1_data, rs2_data, wb_data;

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    regfile REGISTER_FILE_INST (
        .i_clk(i_clk),
        .i_rst_n(i_reset),
        .i_rs1_addr(rs1_addr),
        .i_rs2_addr(rs2_addr),
        .i_rd_addr(rd_addr),
        .i_rd_wren(rd_wren),
        .i_rd_data(wb_data),
        .o_rs1_data(rs1_data),
        .o_rs2_data(rs2_data)
    );

//------------------------------------------------------------------------------
// BRANCH COMPARATOR & IMM GEN
//------------------------------------------------------------------------------
    brc BRANCH_INST (
        .i_br_un(br_un),
        .i_rs1_data(rs1_data),
        .i_rs2_data(rs2_data),
        .o_br_less(br_less),
        .o_br_equal(br_equal)
    );

    wire  [31:0]  immgen_data;
    ImmGen IMMEDIATE_GENERATOR_INST ( 
        .i_inst(instruction),
        .o_imm(immgen_data)
    );

//------------------------------------------------------------------------------
// ALU OPERAND MUXES & ALU
//------------------------------------------------------------------------------
    wire  [31:0]  operand_a;
    mux_2to1 OPA_MUX (            // 1'b0 -> rs1_data, 1'b1 -> pc
        .i_sel(opa_sel),
        .i_data_0(rs1_data),
        .i_data_1(pc),
        .o_data(operand_a)
    ); 

    wire  [31:0]  operand_b;
    mux_2to1 OPB_MUX (            // 1'b0 -> rs2_data, 1'b1 -> immgen_data
        .i_sel(opb_sel),
        .i_data_0(rs2_data),
        .i_data_1(immgen_data),
        .o_data(operand_b)
    );

    alu ARITHMETIC_LOGIC_UNIT_INST (
        .i_operand_a(operand_a),
        .i_operand_b(operand_b),
        .i_alu_op(alu_op),
        .o_alu_data(alu_data)
    );

//------------------------------------------------------------------------------
// LOAD STORE UNIT (LSU)
//------------------------------------------------------------------------------
    wire  [31:0]  ld_data;

    lsu LOAD_STORE_UNIT (
        .i_clk      (i_clk),      
        .i_reset    (i_reset),    
        .i_lsu_addr (alu_data),   
        .i_st_data  (rs2_data),   
        .i_lsu_wren (wr_en),      
        .i_control  (func3),      
        .o_ld_data  (ld_data),    
        .o_io_ledr  (o_io_ledr),  
        .o_io_ledg  (o_io_ledg),  
        .o_io_hex0  (o_io_hex0),  
        .o_io_hex1  (o_io_hex1),  
        .o_io_hex2  (o_io_hex2),  
        .o_io_hex3  (o_io_hex3),  
        .o_io_hex4  (o_io_hex4),  
        .o_io_hex5  (o_io_hex5),  
        .o_io_hex6  (o_io_hex6),  
        .o_io_hex7  (o_io_hex7),  
        .o_io_lcd   (o_io_lcd),   
        .i_io_sw    (i_io_sw)     
    );

//------------------------------------------------------------------------------
// WRITE-BACK SELECTION
//------------------------------------------------------------------------------
    mux_4to1 WB_SEL_INST (        // 2'b00 -> pc_four, 2'b01 -> alu_data, 2'b10 -> ld_data
        .i_sel(wb_sel),
        .i_data_0(pc_four),
        .i_data_1(alu_data),
        .i_data_2(ld_data),
        .i_data_3(32'b0),
        .o_data(wb_data)
    );

//------------------------------------------------------------------------------
// DEBUG SIGNALS & OUTPUT MONITORING
//------------------------------------------------------------------------------
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_insn_vld <= 1'b0;
            o_pc_debug <= 32'b0;
        end else begin
            o_insn_vld <= insn_vld;
            o_pc_debug <= pc;
        end
    end

endmodule
