module controller(
    input clk, rstn, in_vld, out_rdy,
    output wire in_rdy, out_vld,
    output wire en_REG_RD, en_REG_C,
    output wire en_REG_WR,
    output wire we_BANK1, we_BANK0,
    output wire we_out_BANK,
    output wire sel_wr_swap, sel_rd_swap, sel_wr_bank,
    output wire sel_din, sel_out_bank,   
    output wire [2:0] addr_in_BANK1, addr_in_BANK0,
    output wire [2:0] addr_out_BANK1, addr_out_BANK0,
    output wire [2:0] addr_out_BANK3, addr_out_BANK2,
    output wire [2:0] addr_out_ROM
); 

    reg [2:0] cnt_wr, cnt_rd, cnt_ROM;
    reg [3:0] cnt_data;
    reg [3:0] cstate_wr, cstate_rd;
    reg [3:0] nstate_wr, nstate_rd;
    reg [2:0] data_index, data_index_fwd;
    reg bank_index, bank_index_dly;
    

    localparam
        PRE_IN   = 4'b0000,
        IDLE     = 4'b1000, // 8
        RUN      = 4'b1001, // 9
        STAGE_1  = 4'b0001,
        STAGE_2  = 4'b0010,
        STAGE_3  = 4'b0011,
        STAGE_4  = 4'b0100;

    always @(posedge clk) // COUNTER FOR WR
    begin
        if (!rstn)
            cnt_wr <= 0;
        else
        begin
            if (cnt_wr == 7)
                cnt_wr <= 0;
            else
            begin
                case (cstate_wr)
                    STAGE_1,
                    STAGE_2,
                    STAGE_3,
                    STAGE_4: cnt_wr <= cnt_wr + 1;
                    default: cnt_wr <= cnt_wr;
                endcase
            end
        end
    end

    always @(posedge clk) // COUNTER FOR RD
    begin
        if (!rstn)
            cnt_rd <= 0;
        else
        begin
            if (cnt_rd == 7)
                cnt_rd <= 0;
            else
            begin
                case (cstate_rd)
                    STAGE_1,
                    STAGE_2,
                    STAGE_3,
                    STAGE_4: cnt_rd <= cnt_rd + 1;
                    default: cnt_rd <= cnt_rd;
                endcase
            end
        end
    end    

    always @(posedge clk) // COUTER FOR DATA IN
    begin
        if (!rstn) cnt_data <= 0;
        else
        begin
            if (cnt_data == 15) cnt_data <= 0;
            else if (cstate_wr == RUN) cnt_data <= cnt_data + 1;
            else cnt_data <= cnt_data;
        end
    end

    always @(posedge clk) // NEXT STATE LOGIC
    begin
        if (!rstn)
        begin
            cstate_wr <= PRE_IN;
            cstate_rd <= IDLE;
        end
        else
        begin
            cstate_wr <= nstate_wr;
            cstate_rd <= nstate_rd;
        end
    end

    always @(*) // FSM
    begin
        case (cstate_wr)
        PRE_IN : if (in_vld)         nstate_wr <= RUN;     else nstate_wr <= PRE_IN;
        RUN    : if (cnt_data == 15) nstate_wr <= IDLE;    else nstate_wr <= RUN;
        IDLE   : if (cnt_rd == 2)    nstate_wr <= STAGE_1; else nstate_wr <= IDLE;
        STAGE_1: if (cnt_wr == 7)    nstate_wr <= STAGE_2; else nstate_wr <= STAGE_1;
        STAGE_2: if (cnt_wr == 7)    nstate_wr <= STAGE_3; else nstate_wr <= STAGE_2;
        STAGE_3: if (cnt_wr == 7)    nstate_wr <= STAGE_4; else nstate_wr <= STAGE_3;
        STAGE_4: if (cnt_wr == 7)    nstate_wr <= RUN;     else nstate_wr <= STAGE_4;
        default: nstate_wr <= RUN;
        endcase

        case(cstate_rd)
        IDLE   : if (cnt_data == 15) nstate_rd <= STAGE_1; else if (cnt_wr == 7) nstate_rd <= RUN; else nstate_rd <= IDLE;
        STAGE_1: if (cnt_rd == 7)    nstate_rd <= STAGE_2; else nstate_rd <= STAGE_1;
        STAGE_2: if (cnt_rd == 7)    nstate_rd <= STAGE_3; else nstate_rd <= STAGE_2;
        STAGE_3: if (cnt_rd == 7)    nstate_rd <= STAGE_4; else nstate_rd <= STAGE_3;
        STAGE_4: if (cnt_rd == 7)    nstate_rd <= IDLE;    else nstate_rd <= STAGE_4;
        RUN    : if (cnt_data == 15) nstate_rd <= STAGE_1; else nstate_rd <= RUN;
        default: nstate_rd <= IDLE;
        endcase
    end

    wire [2:0] cnt_wr_dly, cnt_rd_dly;
    wire [3:0] cnt_data_dly, cnt_data_fwd; 

    assign cnt_wr_dly = (cnt_wr > 0) ? (cnt_wr - 1) : 1'b0;
    assign cnt_rd_dly = (cnt_rd > 0) ? (cnt_rd - 1) : 1'b0; 
    assign cnt_data_dly = (cnt_data > 0) ? (cnt_data - 1) : 0;
    assign cnt_data_fwd = cnt_data + 1; 
    
    always @(cnt_data)
    begin 
        bank_index <= ( cnt_data[3] + cnt_data[2] + cnt_data[1] + cnt_data[0] ) % 2;
        data_index <= { cnt_data[3] , cnt_data[2] , cnt_data[1] };
        data_index_fwd <= { cnt_data_fwd[3] , cnt_data_fwd[2] , cnt_data_fwd[1] };
        bank_index_dly <= ( cnt_data_dly[3] + cnt_data_dly[2] + cnt_data_dly[1] + cnt_data_dly[0] ) % 2;
    end

    reg buffer;
    always @(posedge clk) buffer <= en_REG_C;
    
    assign in_rdy  = (cstate_wr == RUN) ? 1'b1 : 1'b0;
    assign out_vld = buffer;

    assign we_BANK1 = (cstate_wr == RUN) ?  bank_index : ( (cstate_wr == IDLE || cstate_wr == STAGE_4) ? 1'b0 : 1'b1 );
    assign we_BANK0 = (cstate_wr == RUN) ? ~bank_index : ( (cstate_wr == IDLE || cstate_wr == STAGE_4) ? 1'b0 : 1'b1 );
    assign we_out_BANK = (cstate_wr == STAGE_4) ? 1'b1 : 1'b0;

    assign en_REG_RD = ( (cstate_rd == STAGE_1 || cstate_rd == STAGE_2 || cstate_rd == STAGE_3 || cstate_rd == STAGE_4 || (cstate_rd == IDLE && cnt_wr == 5)) ) ? 1'b1 : 1'b0;
    assign en_REG_WR = ( (cnt_rd >= 1 ||cstate_wr == STAGE_1 || cstate_wr == STAGE_2 || cstate_wr == STAGE_3 || cstate_wr == STAGE_4) ) ? 1'b1 : 1'b0;
    assign en_REG_C  = (cstate_rd == RUN) ? 1'b1 : 1'b0;

    // WR MODULE CONTROL SIGNALS
    assign sel_wr_bank = (cstate_wr == RUN) ? bank_index : 1'b0;
    assign sel_din     = (cstate_wr == RUN) ? 1'b1 : 1'b0;
    assign sel_wr_swap = (cstate_wr == STAGE_1 || cstate_wr == STAGE_2 || cstate_wr == STAGE_3 || cstate_wr == STAGE_4) ? ~( (cnt_wr[2] + cnt_wr[1] + cnt_wr[0]) % 2 ) : 1'b0;

    // RD MODULE CONTROL SIGNALS
    assign sel_out_bank = (cstate_rd == RUN) ? bank_index : 1'b0;
    assign sel_rd_swap  = ( (cnt_rd) && (cstate_rd == STAGE_1 || cstate_rd == STAGE_2 || cstate_rd == STAGE_3 || cstate_rd == STAGE_4) ) ? ~( (cnt_rd_dly[2] + cnt_rd_dly[1] + cnt_rd_dly[0]) % 2 ) : 1'b0;

    // AGU
    AGU AGU_WR(
        .clk(clk),
        .rstn(rstn),
        .sel_wr(1'b1), // WR
        .data_index(data_index),
        .cstate_wr(cstate_wr),
        .cstate_rd(cstate_rd),
        .cnt(cnt_wr),
        .cnt_data(cnt_data),
        .addr_BANK1(addr_in_BANK1),
        .addr_BANK0(addr_in_BANK0)
    );
    AGU AGU_RD(
        .clk(clk),
        .rstn(rstn),
        .sel_wr(1'b0), // RD
        .data_index(data_index),
        .cstate_wr(cstate_wr),
        .cstate_rd(cstate_rd),
        .cnt(cnt_rd),
        .cnt_data(cnt_data),
        .addr_BANK1(addr_out_BANK1),
        .addr_BANK0(addr_out_BANK0)
    );


    // ROM Address
    reg [2:0] iter;
    always @(posedge clk)
    begin
        if (!rstn) iter <= 0;
        else
        begin
            if (iter == 4) iter <= 0;
            else if (cnt_ROM == 7) iter <= iter + 1;
            else iter <= iter;
        end
    end

    always @(posedge clk) cnt_ROM <= cnt_rd;

    wire [2:0] tmp1_addr, tmp2_addr, tmp3_addr, tmp4_addr;
    
    assign tmp4_addr = (iter == 3) ? cnt_ROM : 0;
    assign tmp3_addr = (iter == 2) ? {cnt_ROM[1], cnt_ROM[0], 1'b0} : tmp4_addr;
    assign tmp2_addr = (iter == 1) ? {cnt_ROM[0], 1'b0, 1'b0} : tmp3_addr;
    assign tmp1_addr = (iter == 0) ? 0: tmp2_addr;
    assign addr_out_ROM = tmp1_addr;

    assign addr_out_BANK3 = (cstate_wr == RUN) ? data_index_fwd : 1'b0;
    assign addr_out_BANK2 = (cstate_wr == RUN) ? data_index_fwd : 1'b0;


endmodule