module imem (
    input  wire [31:0] i_imem_addr,
    output wire [31:0] o_imem_data
);

    reg [31:0] memory [2000 - 1 : 0]; // 2048  
      
    initial begin   
        $readmemh("../02_test/dump/isa_4b.hex", memory);  
    end  
      
    // Su dung i_imem_addr de truy cap o nho (Word-aligned address)  
    assign o_imem_data = memory[i_imem_addr[13:2]];

endmodule
