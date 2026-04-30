module forwarding_unit(
    // Producer 1 (EX/MEM)
    input  logic       ex_mem_valid,
    input  logic       ex_mem_reg_write,
    input  logic [4:0] ex_mem_rd,
    
    // Producer 2 (MEM/WB)
    input  logic       mem_wb_valid,
    input  logic       mem_wb_reg_write,
    input  logic [4:0] mem_wb_rd,
    
    // Consumer (ID/EX)
    input  logic [4:0] id_ex_rs1,
    input  logic [4:0] id_ex_rs2,

    output logic [1:0] fwd_a_sel,
    output logic [1:0] fwd_b_sel
);

    logic ex_mem_will_write;
    logic mem_wb_will_write;
    
    assign ex_mem_will_write = ex_mem_valid & ex_mem_reg_write & (ex_mem_rd != 0);
    assign mem_wb_will_write = mem_wb_valid & mem_wb_reg_write & (mem_wb_rd != 0);

    // Forwarding logic for ALU input A (rs1)
    always_comb begin
        if      (ex_mem_will_write & (ex_mem_rd == id_ex_rs1)) fwd_a_sel = 2'b10;
        else if (mem_wb_will_write & (mem_wb_rd == id_ex_rs1)) fwd_a_sel = 2'b01;
        else                                                   fwd_a_sel = 2'b00;
    end

    // Forwarding logic for ALU input B (rs2)
    always_comb begin
        if      (ex_mem_will_write & (ex_mem_rd == id_ex_rs2)) fwd_b_sel = 2'b10;
        else if (mem_wb_will_write & (mem_wb_rd == id_ex_rs2)) fwd_b_sel = 2'b01;
        else                                                   fwd_b_sel = 2'b00;
    end
    
endmodule
