module RD(
    input clk, rstn,
    input [31:0] data_rd_BANK1, data_rd_BANK0,
    input en_REG_RD,
    input wire sel_rd_swap,
    output [31:0] out_REG_A, out_REG_B
); 

    reg  [31:0] REG_A, REG_B, REG_C;
    wire [31:0] out_change0, out_change1;
    wire [31:0] out_dout;

    assign out_change1 = !sel_rd_swap ? data_rd_BANK1 : data_rd_BANK0;
    assign out_change0 = !sel_rd_swap ? data_rd_BANK0 : data_rd_BANK1;

    always @(posedge clk)
    begin
        if (!rstn) REG_A <= 0;
        else if (en_REG_RD) REG_A <= out_change1;
        else REG_A <= REG_A;
    end

    always @(posedge clk)
    begin
        if (!rstn) REG_B <= 0;
        else if (en_REG_RD) REG_B <= out_change0;
        else REG_B <= REG_B;
    end


    assign out_REG_A = REG_A;
    assign out_REG_B = REG_B;


endmodule