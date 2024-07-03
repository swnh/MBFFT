//////////////////////////////////////////////////////////////////////////////////
// Company: Pusan National University
// Engineer: Seungwan Noh
// 
// Create Date: 05/08/2024 06:09:59 PM
// Design Name: FFT
// Module Name: FFT
// Project Name: Dual-port FFT
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FFT(
    input clk,
    input rstn,
    input [31:0] data0_rd_AMEM, data1_rd_AMEM,    
    input [31:0] data0_rd_BMEM, data1_rd_BMEM,
    input [31:0] data_rd_CROM,
    input sel_mux,
    input en_REG,
    output [31:0] out_FFT0, out_FFT1
    );
    
    wire [31:0] out_mux0;
    wire [31:0] out_mux1;
    wire [31:0] out_MULT;
    wire [31:0] out_REG_A;
    wire [31:0] out_REG_B;
    wire [31:0] out_BF0;
    wire [31:0] out_BF1;
    
    reg [31:0] REG_A;
    reg [31:0] REG_B;
    

    /* MUX */
    assign out_mux0 = (!sel_mux) ? data0_rd_AMEM : data0_rd_BMEM;
    assign out_mux1 = (!sel_mux) ? data1_rd_AMEM : data1_rd_BMEM;

    MULT MULT(
        .in_MULT_re(out_mux1[15:0]), .in_MULT_im(out_mux1[31:16]),
        .tw_in_re(data_rd_CROM[15:0]), .tw_in_im(data_rd_CROM[31:16]),
        .out_MULT(out_MULT)
    );
    
    BF BF(
        .in_re0(out_REG_A[15:0]), .in_im0(out_REG_A[31:16]),
        .in_re1(out_REG_B[15:0]), .in_im1(out_REG_B[31:16]),
        .out_BF0(out_BF0), .out_BF1(out_BF1)
    );
    
    always @(posedge clk)
    begin
        if(!rstn)       REG_A <= 0;
        else if(!en_REG) REG_A <= out_mux0;
        else            REG_A <= REG_A;
    end
    
    always @(posedge clk)
    begin
        if(!rstn)       REG_B <= 0;
        else if(!en_REG) REG_B <= out_MULT;
        else            REG_B <= REG_B;
    end
    
    assign out_REG_A = REG_A;
    assign out_REG_B = REG_B;
    assign out_FFT0 = out_BF0;
    assign out_FFT1 = out_BF1; 
    
endmodule
