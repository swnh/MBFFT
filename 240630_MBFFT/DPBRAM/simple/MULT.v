//////////////////////////////////////////////////////////////////////////////////
// Company: Personal
// Engineer: Seungwan Noh
// 
// Create Date: 05/08/2024 06:25:15 PM
// Design Name: Multiplier
// Module Name: MULT
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


module MULT(
    input signed [15:0] in_MULT_re,
    input signed [15:0] in_MULT_im,
    input signed [15:0] tw_in_re,
    input signed [15:0] tw_in_im,
    output signed [31:0] out_MULT
    );
    
    wire signed [30:0] MULT_re;
    wire signed [30:0] MULT_im;
    wire signed [30:0] tmp_re0;
    wire signed [30:0] tmp_im0;
    wire signed [30:0] tmp_re1;
    wire signed [30:0] tmp_im1;
    
    assign tmp_re0 = in_MULT_re * tw_in_re;
    assign tmp_re1 = in_MULT_im * tw_in_im;
    
    assign tmp_im0 = in_MULT_re * tw_in_im;
    assign tmp_im1 = in_MULT_im * tw_in_re;   
    
    assign MULT_re = tmp_re0 - tmp_re1;
    assign MULT_im = tmp_im0 + tmp_im1;
    
    assign out_MULT = {MULT_im[30:15], MULT_re[30:15]};
    
endmodule
