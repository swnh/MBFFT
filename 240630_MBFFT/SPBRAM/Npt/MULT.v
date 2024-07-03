module MULT(
            input signed [15:0] in_MULT_re,
            input signed [15:0] in_MULT_im,
            input signed [15:0] in_tw_re,
            input signed [15:0] in_tw_im,
            
            output signed [31:0] out_MULT
);

wire signed [30:0] MULT_re;
wire signed [30:0] MULT_im;
wire signed [30:0] tmp_re0;
wire signed [30:0] tmp_im0;
wire signed [30:0] tmp_re1;
wire signed [30:0] tmp_im1;

assign tmp_re0 = in_MULT_re * in_tw_re; // real * real
assign tmp_re1 = in_MULT_im * in_tw_im; // imag * imag

assign tmp_im0 = in_MULT_re * in_tw_im; // real * imag
assign tmp_im1 = in_MULT_im * in_tw_re; // imag * real

assign MULT_re = tmp_re0 - tmp_re1; // tmp_re1 --> j * j = -1
assign MULT_im = tmp_im0 + tmp_im1;

// Trunctaion
assign out_MULT = {MULT_im[30:15], MULT_re[30:15]};

endmodule