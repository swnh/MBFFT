module AGU (
    input clk, rstn,
    input sel_wr,
    input [2:0] data_index,
    input [3:0] cstate_wr, cstate_rd,
    input [2:0] cnt,
    input [3:0] cnt_data,
    output [2:0] addr_BANK1, addr_BANK0
);
    reg        on, sel_switch;
    reg  [1:0] iter;
    reg  [2:0] cnt_addr, cnt_dly;
    reg  [2:0] REG_SH1, REG_SH0;
    wire [2:0] out_sh1, out_sh0;
    wire [2:0] out_REG_SH1, out_REG_SH0;
    wire en_REG_SH;

    parameter
        PRE_IN   = 4'b0000,
        IDLE     = 4'b1000, // 8
        RUN      = 4'b1001, // 9
        STAGE_1  = 4'b0001,
        STAGE_2  = 4'b0010,
        STAGE_3  = 4'b0011,
        STAGE_4  = 4'b0100;
        

        always @(posedge clk) 
        begin
            if (!rstn) 
            begin
                iter <= 2'b00;
                on   <= 1'b0;
                cnt_addr <= 0;
            end
            else 
            begin
                case(sel_wr)
                    0: 
                    begin
                        if (cstate_rd == STAGE_1 && cnt == 5)
                            on <= 1'b1;
                        else if (iter == 2 && cnt_addr == 7)
                            on <= 1'b0;
                        else
                            on <= on;
                    end
                    1: 
                    begin
                        if (cstate_wr == STAGE_1 && cnt == 5)
                            on <= 1'b1;
                        else if (iter == 2 && cnt_addr == 7)
                            on <= 1'b0;
                        else
                            on <= on;
                    end
                    default: 
                        on <= 1'b0;
                endcase

                if (on) 
                begin
                    if (cnt_addr == 7) 
                    begin
                        cnt_addr <= 0;
                        if (iter == 2) 
                        begin
                            iter <= 0;
                        end
                        else 
                        begin
                            iter <= iter + 1;
                        end
                    end
                    else 
                    begin
                        cnt_addr <= cnt_addr + 1;
                    end
                end
                else 
                begin
                    cnt_addr <= 0;
                end
            end
        end

    // reg [2:0] BUF;
    always @(posedge clk)
    begin
        if (!rstn) cnt_dly <= 0;
        else cnt_dly <= cnt_addr;
    end

    // SHIFTER
    wire [2:0] tmp3_out_sh1, tmp2_out_sh1, tmp1_out_sh1;

    assign tmp3_out_sh1 = (iter == 2) ? {cnt_addr[0], cnt_addr[2], cnt_addr[1]} : 0;
    assign tmp2_out_sh1 = (iter == 1) ? {cnt_addr[2], cnt_addr[0], cnt_addr[1]} : tmp3_out_sh1;
    assign tmp1_out_sh1 = (iter == 0) ? cnt_addr : tmp2_out_sh1;
    assign out_sh1 = tmp1_out_sh1;

    wire [2:0] tmp3_out_sh0, tmp2_out_sh0, tmp1_out_sh0;
    assign tmp3_out_sh0 = (iter == 2) ? {cnt_dly[0], cnt_dly[2], cnt_dly[1]} : 0;
    assign tmp2_out_sh0 = (iter == 1) ? {cnt_dly[2], cnt_dly[0], cnt_dly[1]} : tmp3_out_sh0;
    assign tmp1_out_sh0 = (iter == 0) ? cnt_dly : tmp2_out_sh0;
    assign out_sh0 = tmp1_out_sh0;

    always @(posedge clk)
    begin
        if (!rstn) REG_SH1 <= 0;
        else if (en_REG_SH) REG_SH1 <= out_sh1;
        else REG_SH1 <= REG_SH1;
    end

    always @(posedge clk)
    begin
        if (!rstn) REG_SH0 <= 0;
        else if (en_REG_SH) REG_SH0 <= out_sh0;
        else REG_SH0 <= REG_SH0;
    end
 
    always @(posedge clk)
    begin 
        if (!rstn) sel_switch <= 1'b0;
        else
        begin
            if (cnt_dly == 0) sel_switch <= 1'b0;
            else if (cnt_dly == 2 || cnt_dly == 6) sel_switch <= sel_switch;
            else sel_switch <= ~sel_switch;
        end
    end

    assign en_REG_SH  = cnt_addr[0];
    assign out_REG_SH1 = REG_SH1;
    assign out_REG_SH0 = REG_SH0;

    wire [2:0] tmp0_addr_BANK1, tmp1_addr_BANK1, tmp2_addr_BANK1, tmp3_addr_BANK1;
    wire [2:0] tmp0_addr_BANK0, tmp1_addr_BANK0, tmp2_addr_BANK0, tmp3_addr_BANK0;

    assign tmp3_addr_BANK1 = (!sel_switch) ? out_REG_SH1 : out_REG_SH0;
    assign tmp2_addr_BANK1 = (!sel_wr) ? ( (cstate_rd == STAGE_1) ? cnt : tmp3_addr_BANK1 ) : 0;
    assign tmp1_addr_BANK1 = ( sel_wr) ? ( (cstate_wr == STAGE_1) ? cnt : tmp3_addr_BANK1 ) : tmp2_addr_BANK1; // WRITE
    assign tmp0_addr_BANK1 = (cstate_wr == RUN) ? {1'b0, cnt_data[0], cnt_data[1], cnt_data[2]} : tmp1_addr_BANK1;
    assign addr_BANK1 = tmp0_addr_BANK1;


    assign tmp3_addr_BANK0 = (!sel_switch) ? out_REG_SH0 : out_REG_SH1;
    assign tmp2_addr_BANK0 = (!sel_wr) ? ( (cstate_rd == STAGE_1) ? cnt : tmp3_addr_BANK0 ) : 0;
    assign tmp1_addr_BANK0 = ( sel_wr) ? ( (cstate_wr == STAGE_1) ? cnt : tmp3_addr_BANK0 ) : tmp2_addr_BANK0;
    assign tmp0_addr_BANK0 = (cstate_wr == RUN) ? {1'b0, cnt_data[0], cnt_data[1], cnt_data[2]} : tmp1_addr_BANK0;
    assign addr_BANK0 = tmp0_addr_BANK0;

endmodule