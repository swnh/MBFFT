//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2024 11:01:37 AM
// Design Name: 
// Module Name: tb_TopFFT
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
`timescale 1ns / 1ps

module tb_TopFFT;
    /* TopFFT */
    reg clk, rstn, in_vld, out_rdy;
    wire in_rdy, out_vld;
    wire [31:0] ext_data_input0, ext_data_input1;
    wire [31:0] ext_data_output0, ext_data_output1;


    /* CLOCK GEN */
    parameter CLK_PERIOD = 10;
    initial
    begin
        clk = 1'b1;
        forever
        #(CLK_PERIOD/2) clk = ~clk;
    end

    initial 
    begin
        rstn = 1'b0;
        in_vld = 1'b1;
        out_rdy = 1'b1;
        #(0.5*CLK_PERIOD) rstn = 1'b1;    
    end

    /* DATA INPUT COUNT */
    integer data_cnt;
    initial
    begin
        data_cnt = 0;
    end

    always @(negedge clk)
    begin
        if(in_rdy && in_vld) data_cnt = data_cnt + 2;
    end

    /* TB DATA INPUT*/
    parameter INFILE = "RTLin.txt";
    reg [31:0] txt_data_in[4096:0];
    initial 
    begin
        $readmemh(INFILE, txt_data_in);
    end

    assign ext_data_input0 = (in_rdy) ? ( (data_cnt <= -2) ? 0 : ( (data_cnt > 4097) ? 0 : txt_data_in[data_cnt] ) ) : 0;
    assign ext_data_input1 = (in_rdy) ? ( (data_cnt <= -2) ? 0 : ( (data_cnt > 4097) ? 0 : txt_data_in[data_cnt + 1] ) ) : 0;

    TopFFT TopFFT(
        .clk(clk),
        .rstn(rstn),
        .in_vld(in_vld),
        .out_rdy(out_rdy),
        .ext_data_input0(ext_data_input0),
        .ext_data_input1(ext_data_input1),
        .in_rdy(in_rdy),
        .out_vld(out_vld),
        .ext_data_output0(ext_data_output0),
        .ext_data_output1(ext_data_output1)
    );

    parameter W = 50;

    reg [W:0] output_re[4096:0];
    reg [W:0] output_im[4096:0];
    
    integer out_cnt;
    
    initial 
    begin 
        out_cnt = 0; 
    end
 
    always @(posedge clk)
    begin
        if(out_vld && out_rdy)
        begin
            output_im[2*out_cnt]     <= ext_data_output0[31:16];
            output_re[2*out_cnt]     <= ext_data_output0[15:0];
            output_im[2*out_cnt + 1] <= ext_data_output1[31:16];
            output_re[2*out_cnt + 1] <= ext_data_output1[15:0];
            out_cnt = out_cnt + 1;
        end
     end
            

    /* TB REFERENCE OUTPUT */
    parameter COMPFILE = "RTLout_ref.txt";
    reg [W:0] txt_compare[8192:0];
    reg [W:0] Temp, Noise, Signal;

    initial
    begin
        $readmemh(COMPFILE, txt_compare);
    end

    real Result;
    initial
    begin
        Result = 0.0;
    end

    integer dumpfile, i;
    initial 
    begin
        Noise  <= 0;
        Signal <= 0;
        #(20000*CLK_PERIOD);
        // TB Output
        dumpfile = $fopen("RTLout.txt", "w");

        for(i=0; i<4096; i=i+1)
        begin
            $fwrite(dumpfile, "%4h\n", output_re[i]);
            $fwrite(dumpfile, "%4h\n", output_im[i]);

            Noise = Noise + (output_re[i] - txt_compare[2*i])*(output_re[i] - txt_compare[2*i])
                          + (output_im[i] - txt_compare[(2*i)+1])*(output_im[i] - txt_compare[(2*i)+1]);

            $display ("Signal : %h \n", Signal);
            Temp = (output_re[i]*output_re[i]) + (output_im[i]*output_im[i]);
            Signal = Signal + Temp;
            $display ("%d : Signal : %h Temp : %h\n", i, Signal, Temp);
        end
        $fclose(dumpfile);
        $display("\nnoise : %h-dec : %d, signal : %h-dec : %d\n",Noise,Noise, Signal,Signal);
        $display("\nDivided : %7.20f\n",$bitstoreal(Noise)/$bitstoreal(Signal));
    
        Result = 10 * $log10($bitstoreal(Noise)/$bitstoreal(Signal));
        $display("NSR : %f",Result);  
    end

endmodule