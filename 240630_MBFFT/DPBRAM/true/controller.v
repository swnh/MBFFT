//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2024 06:51:39 PM
// Design Name: 
// Module Name: controller
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

module controller #(
    parameter N = 4
)
(
    input clk, rstn, in_vld, out_rdy,
    output wire in_rdy, out_vld,
    output wire sel_input,
    output wire sel_mux,
    output wire en_REG,
    output wire we_AMEM, we_BMEM, we_OMEM,
    output wire [N-1:0] addr0_AMEM, addr1_AMEM,
    output wire [N-1:0] addr0_BMEM, addr1_BMEM,
    output wire [N-1:0] addr0_OMEM, addr1_OMEM,
    output wire [N-1:0] addr_CROM
    );
    
    reg [N:0] cnt, cnt_in, cnt_out;
    reg [N-1:0] cstate, cstate_in, cstate_out;
    reg [N-1:0] nstate, nstate_in, nstate_out;
    
    localparam
        PRE_IN  = 4'b0000,
        IDLE    = 4'b1000, // 8
        RUN     = 4'b1001, // 9
        STAGE_1 = 4'b0001,
        STAGE_2 = 4'b0010,
        STAGE_3 = 4'b0011,
        STAGE_4 = 4'b0100,
        /*
        STAGE_5 = 4'b0101,
        STAGE_6 = 4'b0110
        */ 
        LCNT = 2**(N-1) + 1; // N = 4, LCNT = 9
    
    /* STATE MACHINE */
    always @(posedge clk)
    begin
        if(!rstn)
        begin
            cstate     <= IDLE;
            cstate_in  <= PRE_IN;
            cstate_out <= IDLE;
        end
        else
        begin
            cstate     <= nstate;
            cstate_in  <= nstate_in;
            cstate_out <= nstate_out;
        end
    end

    always @(*)
    begin
        case(cstate_in)
            PRE_IN:
            begin
                if(in_vld) nstate_in <= RUN;
                else nstate_in <= PRE_IN;
            end
            
            RUN:
            begin
                if(cnt_in == LCNT - 2) nstate_in <= IDLE;
                else nstate_in <= RUN;
            end

            IDLE:
            begin
                if(cstate == STAGE_4 && cnt == 1) nstate_in <= RUN;
                else nstate_in <= IDLE;
            end

            default nstate_in <= RUN;
        endcase

        case(cstate)
            IDLE:
            begin
                if(nstate_in == IDLE) nstate <= STAGE_1;
                else nstate <= IDLE;
            end

            STAGE_1:
            begin
                if(cnt == LCNT) nstate <= STAGE_2;
                else nstate <= STAGE_1;
            end
            
            STAGE_2:
            begin
                if(cnt == LCNT) nstate <= STAGE_3;
                else nstate <= STAGE_2;
            end

            STAGE_3:
            begin
                if(cnt == LCNT) nstate <= STAGE_4;
                else nstate <= STAGE_3;
            end

            STAGE_4:
            begin
                if(cnt == LCNT) nstate <= STAGE_1;
                else nstate <= STAGE_4;
            end

            default: nstate <= IDLE;
        endcase

        case(cstate_out)
            IDLE:
            begin
                if(cstate == STAGE_4 && cnt == LCNT) nstate_out <= RUN;
                else nstate_out <= IDLE;
            end

            RUN:
            begin
                if(cnt_out == LCNT - 1) nstate_out <= IDLE;
                else nstate_out <= RUN;
            end
            
            default: nstate_out <= IDLE;
        endcase
    end
    

    /* COUNTER */
    always @(posedge clk) // cnt
    begin
        if(!rstn) cnt <= 0;
        else
        begin
            if(cstate == IDLE)   cnt <= 0;
            else if(cnt == LCNT) cnt <= 0;
            else                 cnt <= cnt + 1;
        end
    end
    
    always @(posedge clk) // cnt_in
    begin
        if(!rstn) cnt_in <= 0;
        else
        begin
            if(cstate_in == PRE_IN || cstate_in == IDLE) cnt_in <= 0;
            else if(cstate_in == RUN)                    cnt_in <= cnt_in + 1;
            else                                         cnt_in <= cnt_in;
        end
    end
    
    always @(posedge clk) // cnt_out
    begin
        if(!rstn) cnt_out <= 0;
        else 
        begin
            if(cstate_out == IDLE)      cnt_out <= 0;
            else if(cstate_out == RUN)  cnt_out <= cnt_out + 1; 
            else                        cnt_out <= cnt_out; 
        end
    end
    

    /* MEMORY ENABLE */
    assign we_AMEM = (cstate_in == RUN || (cstate == STAGE_2 && cnt > 1)) ? 0 : 1;
    assign we_BMEM = (cstate == STAGE_1 && cnt > 1 || cstate == STAGE_3 && cnt > 1) ? 0 : 1;
    assign we_OMEM = (cstate_in == RUN && cstate == STAGE_4) ? 0 : 1;

    /* REG ENABLE */
    assign en_REG = (cstate == IDLE) ? 1 : ( (cnt > 0) ? 0 : 1 );

    /* HANDSHAKE SIGNAL*/
    assign out_vld = (cstate_out == RUN && cnt_out) ? 1 : 0;
    assign in_rdy  = (cstate_in == RUN) ? 1 : 0;

    /* MUX */
    assign sel_input = in_rdy;
    assign sel_mux  = (cstate == STAGE_2 || cstate == STAGE_4) ? 1 : 0; // sel_mux == 1 --> BMEM 선택

    wire [N:0] cnt_dly, cnt_CROM;
    assign cnt_dly  = (cnt > 1) ? (cnt - 2) : 0;
    assign cnt_CROM = (cnt > 0) ? (cnt - 1) : 0;


    /* AMEM ADDRESS */
    wire [N-1:0] tmp4_addr0_AMEM, tmp4_addr1_AMEM;
    wire [N-1:0] tmp3_addr0_AMEM, tmp3_addr1_AMEM;
    wire [N-1:0] tmp2_addr0_AMEM, tmp2_addr1_AMEM;
    wire [N-1:0] tmp1_addr0_AMEM, tmp1_addr1_AMEM;
    wire [N-1:0] tmp0_addr0_AMEM, tmp0_addr1_AMEM;
    
    // STAGE_4
    assign tmp4_addr0_AMEM = (!we_AMEM && cstate == STAGE_4) ? {cnt_dly[3],cnt_dly[0], cnt_dly[1], cnt_dly[2]} : 0;
    assign tmp4_addr1_AMEM = (!we_AMEM && cstate == STAGE_4) ? tmp4_addr0_AMEM + 4'b1000 : 0;
    // STAGE_3
    assign tmp3_addr0_AMEM = (we_AMEM && cstate == STAGE_3) ? {cnt[2], cnt[3], cnt[1], cnt[0]} : tmp4_addr0_AMEM;
    assign tmp3_addr1_AMEM = (we_AMEM && cstate == STAGE_3) ? tmp3_addr0_AMEM + 4'b0100 : tmp4_addr1_AMEM;
    // STAGE_2
    assign tmp2_addr0_AMEM = (!we_AMEM && cstate == STAGE_2) ? {cnt_dly[2], cnt_dly[1], cnt_dly[3], cnt_dly[0]} : tmp3_addr0_AMEM;
    assign tmp2_addr1_AMEM = (!we_AMEM && cstate == STAGE_2) ? tmp2_addr0_AMEM + 4'b0010 : tmp3_addr1_AMEM;
    // STAGE_1
    assign tmp1_addr0_AMEM = (we_AMEM && cstate == STAGE_1) ? {cnt[2], cnt[1], cnt[0], cnt[3]} : tmp2_addr0_AMEM;
    assign tmp1_addr1_AMEM = (we_AMEM && cstate == STAGE_1) ? tmp1_addr0_AMEM + 4'b0001 : tmp2_addr1_AMEM;
    // Pre-stage
    assign tmp0_addr0_AMEM = (!we_AMEM && cstate == IDLE) ? {cnt_in[3], cnt_in[0], cnt_in[1], cnt_in[2]} : tmp1_addr0_AMEM;
    assign tmp0_addr1_AMEM = (!we_AMEM && cstate == IDLE) ? tmp0_addr0_AMEM + 4'b1000 : tmp1_addr1_AMEM;

    assign addr0_AMEM = tmp0_addr0_AMEM;
    assign addr1_AMEM = tmp0_addr1_AMEM;
    

    /* BMEM ADDRESS */
    wire [N-1:0] tmp4_addr0_BMEM, tmp4_addr1_BMEM;
    wire [N-1:0] tmp3_addr0_BMEM, tmp3_addr1_BMEM;
    wire [N-1:0] tmp2_addr0_BMEM, tmp2_addr1_BMEM;
    wire [N-1:0] tmp1_addr0_BMEM, tmp1_addr1_BMEM;

    // STAGE_4
    assign tmp4_addr0_BMEM = (we_BMEM && cstate == STAGE_4) ? {cnt[3],cnt[2], cnt[1], cnt[0]} : 0;
    assign tmp4_addr1_BMEM = (we_BMEM && cstate == STAGE_4) ? tmp4_addr0_BMEM + 4'b1000 : 0;
    // STAGE_3
    assign tmp3_addr0_BMEM = (!we_BMEM && cstate == STAGE_3) ? {cnt_dly[2], cnt_dly[3], cnt_dly[1], cnt_dly[0]} : tmp4_addr0_BMEM;
    assign tmp3_addr1_BMEM = (!we_BMEM && cstate == STAGE_3) ? tmp3_addr0_BMEM + 4'b0100 : tmp4_addr1_BMEM;
    // STAGE_2
    assign tmp2_addr0_BMEM = (we_BMEM && cstate == STAGE_2) ? {cnt[2], cnt[1], cnt[3], cnt[0]} : tmp3_addr0_BMEM;
    assign tmp2_addr1_BMEM = (we_BMEM && cstate == STAGE_2) ? tmp2_addr0_BMEM+ 4'b0010 : tmp3_addr1_BMEM;
    // STAGE_1
    assign tmp1_addr0_BMEM = (!we_BMEM && cstate == STAGE_1) ? {cnt_dly[2], cnt_dly[1], cnt_dly[0], cnt_dly[3]} : tmp2_addr0_BMEM;
    assign tmp1_addr1_BMEM = (!we_BMEM && cstate == STAGE_1) ? tmp1_addr0_BMEM + 4'b0001 : tmp2_addr1_BMEM;

    assign addr0_BMEM = tmp1_addr0_BMEM;
    assign addr1_BMEM = tmp1_addr1_BMEM;


    /* OMEM ADDRESS */
    wire[N-1:0] tmp1_addr0_OMEM, tmp1_addr1_OMEM;
    wire[N-1:0] tmp4_addr0_OMEM, tmp4_addr1_OMEM;

    // SET T+1 STAGE_1
    assign tmp1_addr0_OMEM = (cstate_out == RUN) ? {cnt_out[2], cnt_out[1], cnt_out[0], cnt_out[3]} : 0;
    assign tmp1_addr1_OMEM = (cstate_out == RUN) ? tmp1_addr0_OMEM + 4'b0001 : 0;
    // SET T STAGE_4
    assign tmp4_addr0_OMEM = (!we_OMEM) ? {cnt_dly[3], cnt_dly[2], cnt_dly[1], cnt_dly[0]} : tmp1_addr0_OMEM;
    assign tmp4_addr1_OMEM = (!we_OMEM) ? tmp4_addr0_OMEM + 4'b1000 : tmp1_addr1_OMEM;

    assign addr0_OMEM = tmp4_addr0_OMEM;
    assign addr1_OMEM = tmp4_addr1_OMEM;


    /* CROM ADDRESS */
    wire [N-1:0] tmp4_addr_CROM = (cstate == STAGE_4) ? {cnt[3], cnt[2], cnt[1], cnt[0]} : 0;
    wire [N-1:0] tmp3_addr_CROM = (cstate == STAGE_3) ? {1'b0, cnt[1], cnt[0], 1'b0} : tmp4_addr_CROM;
    wire [N-1:0] tmp2_addr_CROM = (cstate == STAGE_2) ? {1'b0, cnt[0], 1'b0, 1'b0} : tmp3_addr_CROM;
    wire [N-1:0] tmp1_addr_CROM = (cstate == STAGE_1) ? 4'b0000 : tmp2_addr_CROM;
    
    assign addr_CROM = (cnt > 0 && cnt < LCNT + 1) ? tmp1_addr_CROM : 0;

endmodule