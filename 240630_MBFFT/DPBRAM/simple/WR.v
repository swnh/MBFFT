module WR(
    input clk, rstn,
    input [31:0] ext_data_input,
    input [31:0] in_REG_D, in_REG_E,
    input en_REG_WR,
    input sel_din, sel_wr_swap, sel_wr_bank,
    output [31:0] data_wr_BANK1, data_wr_BANK0
); 
    reg  [31:0] REG_D, REG_E; 
    
    wire [31:0] out_REG_D, out_REG_E;
    wire [31:0] out_bank1, out_bank0;
    wire [31:0] out_swap1, out_swap0;

    always @(posedge clk)
    begin
        if (!rstn) REG_D <= 0;
        else if (en_REG_WR) REG_D <= in_REG_D;
        else REG_D <= REG_D;
    end

    always @(posedge clk)
    begin
        if (!rstn) REG_E <= 0;
        else if (en_REG_WR) REG_E <= in_REG_E;
        else REG_E <= REG_E;
    end
    
    assign out_REG_D = REG_D;
    assign out_REG_E = REG_E;

    assign out_swap1 =  sel_wr_swap ? out_REG_E : out_REG_D;
    assign out_swap0 =  sel_wr_swap ? out_REG_D : out_REG_E;
    assign out_bank1 =  sel_wr_bank ? ext_data_input : 0;
    assign out_bank0 = !sel_wr_bank ? ext_data_input : 0;
    assign data_wr_BANK1 = sel_din ? out_bank1 : out_swap1;
    assign data_wr_BANK0 = sel_din ? out_bank0 : out_swap0;


endmodule