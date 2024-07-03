module FFT(
    input [31:0] out_REG_A, out_REG_B,
    input [31:0] data_rd_ROM,
    output [31:0] out_FFT1, out_FFT0
);

    wire [31:0] out_MULT;
    wire [31:0] out_BF0, out_BF1;

    MULT MULT(
        .in_MULT_re(out_REG_B[15:0]), .in_MULT_im(out_REG_B[31:16]),
        .tw_in_re(data_rd_ROM[15:0]), .tw_in_im(data_rd_ROM[31:16]),
        .out_MULT(out_MULT)
    );

    BF BF(
        .in_re0(out_REG_A[15:0]), .in_im0(out_REG_A[31:16]),
        .in_re1(out_MULT[15:0]), .in_im1(out_MULT[31:16]),
        .out_BF0(out_BF0), .out_BF1(out_BF1)
    );

    assign out_FFT1 = out_BF1;
    assign out_FFT0 = out_BF0;
    

endmodule