module ctrl_unit(
    input   wire  [31:0]    i_inst,
    input   wire            i_br_less,i_br_equal,
    output  reg             o_pc_sel,o_br_un,o_rd_wren,o_mem_wren,o_mem_rden,o_opa_sel,o_opb_sel,o_insn_vld,
    output  reg  [1:0]      o_wb_sel,
    output  reg  [3:0]      o_alu_op
);
    
    //  opcode
    localparam          R_TYPE  = 5'b01100,
                        I_TYPE  = 5'b00100,
                        I_LOAD  = 5'b00000,
                        S_TYPE  = 5'b01000,
                        B_TYPE  = 5'b11000,
                        JAL     = 5'b11011,
                        JALR    = 5'b11001,
                        LUI     = 5'b01101,
                        AUIPC   = 5'b00101;

    //  alu_option
    localparam  [3:0]   OP_ADD  = 4'b0000,
                        OP_SUB  = 4'b0001,
                        OP_SLT  = 4'b0010, 
                        OP_SLTU = 4'b0011,
                        OP_XOR  = 4'b0100,
                        OP_OR   = 4'b0101,
                        OP_AND  = 4'b0110,
                        OP_SLL  = 4'b0111,
                        OP_SRL  = 4'b1000,
                        OP_SRA  = 4'b1001,
                        OP_OPB  = 4'b1010;

    //func_3 branch
    localparam  [2:0]   BEQ     = 3'b000,
                        BNE     = 3'b001,
                        BLT     = 3'b100,
                        BGE     = 3'b101,
                        BLTU    = 3'b110,
                        BGEU    = 3'b111;

    //func_3  R_TYPE   
    localparam  [2:0]   ADD     = 3'b000, // = SUB,  difference func7: i_inst[30] -> SUB:1, ADD:0
                        SLL     = 3'b001,
                        SLT     = 3'b010,
                        SLTU    = 3'b011,
                        XOR     = 3'b100,
                        SRL     = 3'b101, // = SRA, difference  func7: i_inst[30] ->  SRL:0, SRA:1
                        OR      = 3'b110,
                        AND     = 3'b111;   
                   
    //func_3  S_TYPE  
    localparam  [2:0]   SB      = 3'b000,
                        SH      = 3'b001,
                        SW      = 3'b010;
    
    //func_3  I_LOAD  
    localparam  [2:0]   LB      = 3'b000,
                        LH      = 3'b001,
                        LW      = 3'b010,
                        LBU     = 3'b100,
                        LHU     = 3'b101;
    
    //op_a_sel
    localparam          rs1_sel = 1'b0,
                        pc_sel  = 1'b1;
  
    //op_b_sel          
    localparam          rs2_sel = 1'b0,
                        imm_sel = 1'b1;

    //insn_vld  
    localparam          unvalid = 1'b0,
                        valid   = 1'b1;
    
    //pc_sel
    localparam          pc_four       = 1'b0,
                        pc_plus_imm   = 1'b1;
    
    //rd_wren 
    localparam          rd_unwr = 1'b0,
                        rd_wr   = 1'b1;

    //W_data
    localparam          wb_pc_four    = 2'b00,
                        wb_alu_data   = 2'b01,
                        wb_lsu_data   = 2'b10;

    //br_un
    localparam          br_unsign     = 1'b1,
                        br_sign       = 1'b0;

    
    always  @(*)  begin 
      case(i_inst[6:2]) //opcode
            R_TYPE: begin 
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign; //mac dinh -> tranh bi high_z
                o_opa_sel   = rs1_sel;  
                o_opb_sel   = rs2_sel;
    
                case(i_inst[14:12]) //func3
                    ADD   : o_alu_op  = ( i_inst[30] ) ? OP_SUB : OP_ADD; //func7 = 1 -> sub va nguoc lai
                    SLT   : o_alu_op  = OP_SLT;
                    SLTU  : o_alu_op  = OP_SLTU;
                    XOR   : o_alu_op  = OP_XOR;
                    SRL   : o_alu_op  = ( i_inst[30] ) ? OP_SRA : OP_SRL; //func7 = 1 -> SRA va nguoc lai
                    OR    : o_alu_op  = OP_OR;
                    AND   : o_alu_op  = OP_AND;
                    SLL   : o_alu_op  = OP_SLL;
                endcase
          
                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data;
             end
//..........................................................................................................
             I_TYPE:  begin 
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign; //mac dinh -> tranh bi high_z
                o_opa_sel   = rs1_sel;  
                o_opb_sel   = imm_sel;
          
                case(i_inst[14:12]) //func3
                    ADD   : o_alu_op  = OP_ADD; //func7 = 1 -> sub va nguoc lai
                    SLT   : o_alu_op  = OP_SLT;
                    SLTU  : o_alu_op  = OP_SLTU;
                    XOR   : o_alu_op  = OP_XOR;
                    SRL   : o_alu_op  = ( i_inst[30] ) ? OP_SRA : OP_SRL; //func7 = 1 -> SRA va nguoc lai
                    OR    : o_alu_op  = OP_OR;
                    AND   : o_alu_op  = OP_AND;
                    SLL   : o_alu_op  = OP_SLL;
                endcase
      
                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data;
             end
//...........................................................................................................
             
             I_LOAD:  begin 
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_wr;
                o_insn_vld  = ((i_inst[14:12] == LB)||(i_inst[14:12] == LH)||(i_inst[14:12] == LW)||(i_inst[14:12] == LBU)||(i_inst[14:12] == LHU)) ? valid:unvalid;
                o_br_un     = br_unsign; //mac dinh -> tranh bi high_z
                o_opa_sel   = rs1_sel;
                o_opb_sel   = imm_sel;

                o_alu_op    = OP_ADD;
            
                o_mem_wren  = unvalid;
                o_mem_rden  = valid;
                o_wb_sel    = wb_lsu_data;
             end
//...........................................................................................................
             S_TYPE:  begin 
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_unwr;
                o_insn_vld  = ((i_inst[14:12] == SB)||(i_inst[14:12] == SH)||(i_inst[14:12] == SW)) ? valid:unvalid;;
                o_br_un     = br_unsign; //mac dinh -> tranh bi high_z
                o_opa_sel   = rs1_sel;
                o_opb_sel   = imm_sel;
                
                o_alu_op    = OP_ADD;
  
                o_mem_wren  = valid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data;
              end
//............................................................................................................
             
             B_TYPE:  begin 
                o_rd_wren   = rd_unwr;
                o_opa_sel   = pc_sel; 
                o_opb_sel   = imm_sel;
              
                o_alu_op    = OP_ADD;
              
                o_wb_sel    = wb_alu_data;  //default hoac co the "don't care" 
                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;

                case(i_inst[14:12]) //func3
                    BEQ   : begin 
                          o_pc_sel    = i_br_equal;
                          o_insn_vld  = valid;
                          o_br_un     = br_sign;
                    end

                    BNE   : begin 
                          o_pc_sel    = !i_br_equal;
                          o_insn_vld  = valid;
                          o_br_un     = br_sign;
                    end
                
                    BLT   : begin 
                          o_pc_sel    = i_br_less;
                          o_insn_vld  = valid;
                          o_br_un     = br_sign;
                    end

                    BGE   : begin
                          o_pc_sel    = !i_br_less;
                          o_insn_vld  = valid;
                          o_br_un     = br_sign;
                    end

                    BLTU  : begin
                          o_pc_sel    = i_br_less;
                          o_insn_vld  = valid;
                          o_br_un     = br_unsign;
                    end

                    BGEU  : begin 
                          o_pc_sel    = ~i_br_less;
                          o_insn_vld  = valid;
                          o_br_un     = br_unsign;
                    end
                            
                    default : begin 
                          o_pc_sel    = pc_four;
                          o_insn_vld  = unvalid;
                          o_br_un     = br_unsign;
                    end
                endcase
             end
//.................................................................
             JALR: begin
                o_pc_sel    = pc_plus_imm;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign;
                o_opa_sel   = rs1_sel;
                o_opb_sel   = imm_sel;

                o_alu_op    = OP_ADD;
                    
                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_pc_four;
             end
//................................................................
             JAL:  begin 
                o_pc_sel    = pc_plus_imm;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign;
                o_opa_sel   = pc_sel;
                o_opb_sel   = imm_sel;

                o_alu_op    = OP_ADD;

                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_pc_four;
             end
//................................................................
             AUIPC: begin
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign;
                o_opa_sel   = pc_sel;
                o_opb_sel   = imm_sel;

                o_alu_op    = OP_ADD;

                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data ;
             end
//................................................................ 
              
             LUI: begin
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_wr;
                o_insn_vld  = valid;
                o_br_un     = br_unsign;
                o_opa_sel   = rs1_sel;   /////////   pc_sel;
                o_opb_sel   = imm_sel;

                o_alu_op    = OP_OPB;

                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data;
             end
//.................................................................
             default: begin 
                o_pc_sel    = pc_four;
                o_rd_wren   = rd_unwr;
                o_insn_vld  = unvalid;
                o_br_un     = br_unsign;
                o_opa_sel   = rs1_sel;
                o_opb_sel   = rs2_sel;

                o_alu_op    = OP_ADD;

                o_mem_wren  = unvalid;
                o_mem_rden  = unvalid;
                o_wb_sel    = wb_alu_data;
             end
      endcase
    end

endmodule        
 
             
                
                



