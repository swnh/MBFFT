module FFT(
            input clk,
            input rstn,
            input [31:0] data_rd_AMEM,
            input [31:0] data_rd_BMEM,
            input [31:0] data_rd_CROM,
            input sel_mem,
            input sel_res,
            input en_REG_A,
            input en_REG_B,
            input en_REG_C,
            
            output [31:0] out_FFT
);

wire [31:0] out_mux_mem;
wire [31:0] out_mux_res;
wire [31:0] out_MULT;

wire [31:0] out_REG_A;
wire [31:0] out_REG_B;
wire [31:0] out_REG_C;

wire [31:0] out_BF0;
wire [31:0] out_BF1;

reg [31:0] REG_A;
reg [31:0] REG_B;
reg [31:0] REG_C;

assign out_mux_mem = sel_mem <= 0 ? data_rd_AMEM : data_rd_BMEM;
assign out_mux_res = sel_res <= 0 ? out_REG_C : out_BF1;

MULT i_MULT(
            .in_MULT_re(out_mux_mem[15:0]),
            .in_MULT_im(out_mux_mem[31:16]),
            .in_tw_re(data_rd_CROM[15:0]),
            .in_tw_im(data_rd_CROM[31:16]),
            .out_MULT(out_MULT)
);

BF i_BF(
            .in_re0(out_REG_A[15:0]),
            .in_im0(out_REG_A[31:16]),
            .in_re1(out_REG_B[15:0]),
            .in_im1(out_REG_B[31:16]),
            .out_BF0(out_BF0),
            .out_BF1(out_BF1)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        REG_A <= 0;
    end else if (en_REG_A) begin
        REG_A <= out_mux_mem;
    end else begin
        REG_A <= REG_A;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        REG_B <= 0;
    end else if (en_REG_B) begin
        REG_B <= out_MULT;
    end else begin
        REG_B <= REG_B;
    end
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        REG_C <= 0;
    end else if (en_REG_C) begin
        REG_C <= out_BF0;
    end else begin
        REG_C <= REG_C;
    end
end

assign out_REG_A = REG_A;
assign out_REG_B = REG_B;
assign out_REG_C = REG_C;
assign out_FFT   = out_mux_res;

endmodule