module topFFT#(
            PNT = 16,
              N = $clog2(PNT)
)(
            input clk,
            input rstn,
            input in_vld,
            input out_rdy,
            input [31:0] ext_data_input,
            
            output in_rdy,
            output out_vld,
            output [31:0] ext_data_output
);

wire [31:0] data_rd_AMEM;
wire [31:0] data_rd_BMEM;
wire [31:0] data_rd_OMEM;
wire [31:0] data_rd_CROM;

wire [31:0] out_FFT;

wire [N-1:0] addr_AMEM;
wire [N-1:0] addr_BMEM;
wire [N-1:0] addr_OMEM;
wire [9:0]   addr_CROM;

wire we_AMEM;
wire we_BMEM;
wire we_OMEM;

wire en_REG_A;
wire en_REG_B;
wire en_REG_C;

wire sel_input;
wire sel_res;
wire sel_mem;

wire [31:0] out_mux_input;
assign out_mux_input = (sel_input) ? ext_data_input : out_FFT;
assign ext_data_output = (out_vld) ? data_rd_OMEM : 0;

FFT i_FFT(           
            // Input
            .clk(clk),
            .rstn(rstn),
            .data_rd_AMEM(data_rd_AMEM),
            .data_rd_BMEM(data_rd_BMEM),
            .data_rd_CROM(data_rd_CROM),
            .sel_mem(sel_mem),
            .sel_res(sel_res),
            .en_REG_A(en_REG_A),
            .en_REG_B(en_REG_B),
            .en_REG_C(en_REG_C),
            // Output
            .out_FFT(out_FFT)
);

controller #(.PNT(PNT), .N(N)) 
i_controller(
            // Input
            .clk(clk),
            .rstn(rstn),
            .in_vld(in_vld),
            .out_rdy(out_rdy),
            // Output
            .in_rdy(in_rdy),
            .out_vld(out_vld),
            .sel_input(sel_input),
            .sel_res(sel_res),
            .sel_mem(sel_mem),
            .we_AMEM(we_AMEM),
            .we_BMEM(we_BMEM),
            .we_OMEM(we_OMEM),
            .addr_AMEM(addr_AMEM),
            .addr_BMEM(addr_BMEM),
            .addr_OMEM(addr_OMEM),
            .addr_CROM(addr_CROM),
            .en_REG_A(en_REG_A),
            .en_REG_B(en_REG_B),
            .en_REG_C(en_REG_C)  
);

//Instantiate with the name of the BRAM module you created
blk_mem_gen_0 AMEM(
	.clka(clk),	
	.wea(we_AMEM),	
	.addra(addr_AMEM),
	.dina(out_mux_input),	
	.douta(data_rd_AMEM)
);

//Instantiate with the name of the BRAM module you created
blk_mem_gen_0 BMEM(	
	.clka(clk),
	.wea(we_BMEM),
	.addra(addr_BMEM),
	.dina(out_FFT),
	.douta(data_rd_BMEM)
);

//Instantiate with the name of the BRAM module you created
blk_mem_gen_0 OMEM(
	.clka(clk),
	.wea(we_OMEM),
	.addra(addr_OMEM),
	.dina(out_FFT),
	.douta(data_rd_OMEM)
);

//Instantiate with the name of the BROM module you created
blk_mem_gen_1 CROM(
    .clka(clk),
	.addra(addr_CROM),
	.douta(data_rd_CROM)
);
endmodule