//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Seungwan Noh
// 
// Create Date: 05/09/2024 11:39:13 PM
// Design Name: 
// Module Name: FFTcore
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


module FFTcore#(
    parameter N = 4
)
(
    input clk, rstn, in_vld, out_rdy,
    input [31:0] data0_rd_AMEM, data1_rd_AMEM,
    input [31:0] data0_rd_BMEM, data1_rd_BMEM,
    input [31:0] data_rd_CROM,

    output we_AMEM, we_BMEM, we_OMEM,
    output [31:0] out_FFT0, out_FFT1,
    output [N-1:0] addr0_AMEM, addr1_AMEM,
    output [N-1:0] addr0_BMEM, addr1_BMEM,
    output [N-1:0] addr0_OMEM, addr1_OMEM,
    output [N-1:0] addr_CROM,
    output sel_input,
    output in_rdy, out_vld
    );

    /* WIRE */
    wire en_REG;

    /* FFT INSTANTIATION */
    FFT FFT(
        .clk(clk),
        .rstn(rstn),
        .data0_rd_AMEM(data0_rd_AMEM),
        .data1_rd_AMEM(data1_rd_AMEM),
        .data0_rd_BMEM(data0_rd_BMEM),
        .data1_rd_BMEM(data1_rd_BMEM),
        .data_rd_CROM(data_rd_CROM),
        .sel_mux(sel_mux),
        .en_REG(en_REG),
        .out_FFT0(out_FFT0),
        .out_FFT1(out_FFT1)
    );

    /* CONTROLLER INSTANTIATION */
    controller controller(
        .clk(clk),
        .rstn(rstn),
        .in_vld(in_vld),
        .out_rdy(out_rdy),
        .sel_input(sel_input),
        .sel_mux(sel_mux),
        .en_REG(en_REG),
        .we_AMEM(we_AMEM),
        .we_BMEM(we_BMEM),
        .we_OMEM(we_OMEM),
        .addr0_AMEM(addr0_AMEM),
        .addr1_AMEM(addr1_AMEM),
        .addr0_BMEM(addr0_BMEM),
        .addr1_BMEM(addr1_BMEM),
        .addr0_OMEM(addr0_OMEM),
        .addr1_OMEM(addr1_OMEM),
        .addr_CROM(addr_CROM),
        .in_rdy(in_rdy),
        .out_vld(out_vld)
    );

endmodule