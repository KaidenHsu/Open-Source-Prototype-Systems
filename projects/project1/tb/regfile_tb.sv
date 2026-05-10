module regfile_tb;

logic clk = 0;
logic reset;

logic we;
logic [5-1:0] rs1, rs2, rd;
logic [32-1:0] wd;

logic [32-1:0] read_data1, read_data2;

regfile dut (
    .clk(clk), .reset(reset),

    .RegWrite(we),
    .rs1(rs1), .rs2(rs2), .rd(rd),
    .write_data(wd),

    .read_data1(read_data1),
    .read_data2(read_data2)
);

initial begin
    /* write-read test */
    // write x5 = 42
    we = 1; rd = 5; wd = 42; #10;

    // read x5
    we = 0; rs1 = 5; #1;
    assert (read_data1 == 42) else $fatal(1, "x5 read test failed, x5= %0d", read_data1);


    /* x0 is ABI zero */
    // attempt write to x0
    we = 1; rd = 0; wd = 123; #10;

    // read x0
    we = 0; rs1 = 0; #1;
    assert (read_data1 == 0) else $fatal(1, "x0 read test failed, x0= %0d", read_data1);


    $finish;
end

endmodule
