module BF(
            input signed [15:0] in_re0,
            input signed [15:0] in_im0,
            input signed [15:0] in_re1,
            input signed [15:0] in_im1,
            output signed [31:0] out_BF0,
            output signed [31:0] out_BF1
);

wire signed [16:0] tmp_re0;
wire signed [16:0] tmp_im0;
wire signed [16:0] tmp_re1;
wire signed [16:0] tmp_im1;

assign tmp_re0 = in_re0 - in_re1; // real - real
assign tmp_re1 = in_re0 + in_re1; // real - real

assign tmp_im0 = in_im0 - in_im1; // imag - imag
assign tmp_im1 = in_im0 + in_im1; // imag - imag

assign out_BF0 = {tmp_im0[16:1], tmp_re0[16:1]};
assign out_BF1 = {tmp_im1[16:1], tmp_re1[16:1]};

endmodule