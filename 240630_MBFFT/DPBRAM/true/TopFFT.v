//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Seungwan Noh
// 
// Create Date: 05/09/2024 11:26:55 PM
// Design Name: 
// Module Name: TopFFT
// Project Name: 
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


module TopFFT#(
    N = 4
)
(
    input clk, rstn, in_vld, out_rdy,
    input [31:0] ext_data_input0, ext_data_input1,
    output in_rdy, out_vld,
    output [31:0] ext_data_output0, ext_data_output1
    );

    /* WIRE */
    wire we_AMEM;
    wire we_BMEM;
    wire we_OMEM;
    wire [31:0] data0_rd_AMEM, data1_rd_AMEM;
    wire [31:0] data0_rd_BMEM, data1_rd_BMEM;
    wire [31:0] data0_rd_OMEM, data1_rd_OMEM;
    wire [31:0] data_rd_CROM;
    wire [31:0] out_FFTcore0;
    wire [31:0] out_FFTcore1;
    wire [N-1:0] addr0_AMEM, addr1_AMEM;
    wire [N-1:0] addr0_BMEM, addr1_BMEM;
    wire [N-1:0] addr0_OMEM, addr1_OMEM;
    wire [N-1:0] addr_CROM;
    wire sel_input;
    wire [31:0] out_mux_input0, out_mux_input1;

    assign out_mux_input0 = (sel_input) ? ext_data_input0 : out_FFTcore0; 
    assign out_mux_input1 = (sel_input) ? ext_data_input1 : out_FFTcore1;

    assign ext_data_output0 = (out_vld) ? data0_rd_OMEM : 0;
    assign ext_data_output1 = (out_vld) ? data1_rd_OMEM : 0;

    /* FFT INSTANTIATION */
    FFTcore FFTcore(
        // input
        .clk(clk),
        .rstn(rstn),
        .in_vld(in_vld),
        .out_rdy(out_rdy),
        .data0_rd_AMEM(data0_rd_AMEM),
        .data1_rd_AMEM(data1_rd_AMEM),
        .data0_rd_BMEM(data0_rd_BMEM),
        .data1_rd_BMEM(data1_rd_BMEM),
        .data_rd_CROM(data_rd_CROM),
        // output
        .we_AMEM(we_AMEM),
        .we_BMEM(we_BMEM),
        .we_OMEM(we_OMEM),
        .out_FFT0(out_FFTcore0),
        .out_FFT1(out_FFTcore1),
        .addr0_AMEM(addr0_AMEM),
        .addr1_AMEM(addr1_AMEM),
        .addr0_BMEM(addr0_BMEM),
        .addr1_BMEM(addr1_BMEM),
        .addr0_OMEM(addr0_OMEM),
        .addr1_OMEM(addr1_OMEM),
        .addr_CROM(addr_CROM),
        .sel_input(sel_input),
        .out_vld(out_vld),
        .in_rdy(in_rdy)
    );

    blk_mem_gen_0 AMEM(
        // Port A
        .clka(clk),
        .wea(~we_AMEM),
        .addra(addr0_AMEM),
        .dina(out_mux_input0),
        .douta(data0_rd_AMEM),
        // Port B
        .clkb(clk),
        .web(~we_AMEM),
        .addrb(addr1_AMEM),
        .dinb(out_mux_input1),
        .doutb(data1_rd_AMEM)
    );

    blk_mem_gen_0 BMEM(
        // Port A
        .clka(clk),
        .wea(~we_BMEM),
        .addra(addr0_BMEM),
        .dina(out_FFTcore0),
        .douta(data0_rd_BMEM),
        // Port B
        .clkb(clk),
        .web(~we_BMEM),
        .addrb(addr1_BMEM),
        .dinb(out_FFTcore1),
        .doutb(data1_rd_BMEM)
    );

    blk_mem_gen_0 OMEM(
        // Port A
        .clka(clk),
        .wea(~we_OMEM),
        .addra(addr0_OMEM),
        .dina(out_FFTcore0),
        .douta(data0_rd_OMEM),
        // Port B
        .clkb(clk),
        .web(~we_OMEM),
        .addrb(addr1_OMEM),
        .dinb(out_FFTcore1),
        .doutb(data1_rd_OMEM)
    );

    blk_mem_gen_1 CROM(
        .clka(clk),
        .addra(addr_CROM),
        .douta(data_rd_CROM)
    );

endmodule
