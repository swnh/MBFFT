/******************************************************************************
Copyright (c) 2022 SoC Design Laboratory, Konkuk University, South Korea
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met: redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer;
redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution;
neither the name of the copyright holders nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUPRE_G, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUPRE_G, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUPRE_G NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Uyong Lee (uyonglee@konkuk.ac.kr)

Revision History
2022.11.17: Started by Uyong Lee
*******************************************************************************/
module controller
	#(parameter N = 6) // 64pt
(
        input 		    clk, nrst, in_vld, out_rdy,
        output wire 	in_rdy, out_vld,
	    output wire	    sel_input,
	    output wire 	sel_res,
        output wire 	sel_mem,
        output wire 	we_AMEM, we_BMEM, we_OMEM,
        output wire 	[N-1:0] addr_AMEM,
        output wire 	[N-1:0] addr_BMEM,
        output wire 	[N-1:0] addr_OMEM,
        output wire 	[N-1:0] addr_CROM, //
        output wire 	en_REG_A,
	    output reg	    en_REG_B, en_REG_C
);

reg [N:0] cnt, cnt_in, cnt_out; // 2^7 = 128
reg [N/2:0] cstate, cstate_in, cstate_out;
reg [N/2:0] nstate, nstate_in, nstate_out;

// FSM
localparam
	PRE_IN  = 4'b0000, // 0
	IDLE    = 4'b1000, // 8
	RUN     = 4'b1001, // 9
	STAGE_1 = 4'b0001, // 1
	STAGE_2 = 4'b0010, // 2
	STAGE_3 = 4'b0011, // 3
	STAGE_4 = 4'b0100, // 4
	STAGE_5 = 4'b0101, // 5
	STAGE_6 = 4'b0110, // 6
	/*
	STALL   = 4'b1111; // 15
	*/
	LCNT	= 2**N + 2;

always @(posedge clk) // 1 cycle delayed
begin
	if(!nrst)
	begin
		cstate 	   <= IDLE;
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


always@(*)
begin
	case(cstate_in)
		PRE_IN:
		begin
			if(in_vld) // nrst = 1
				nstate_in <= RUN;
			else 
				nstate_in <= PRE_IN;
		end

		RUN:
		begin
			if(cnt_in == LCNT - 3) // Pipeline depth = 3
				nstate_in <= IDLE;
			else
				nstate_in <= RUN;
		end

		IDLE:
		begin
			if(cstate == STAGE_6 && cnt == 2) // after 3 cycles ext data in for set 2
				nstate_in <= RUN;
			else
				nstate_in <= IDLE;
		end

		default: nstate_in <= RUN;
	endcase

	case(cstate)
		IDLE:
		begin
			if(nstate_in == IDLE) 
				nstate <= STAGE_1;
			else 
				nstate <= IDLE;
		end
		STAGE_1:
		begin
			if(cnt == LCNT) // 66; 67 cycles
				nstate <= STAGE_2;
			else
				nstate <= STAGE_1;
		end
		STAGE_2:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_3;
			else
				nstate <= STAGE_2;
		end
		STAGE_3:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_4;
			else
				nstate <= STAGE_3;
		end
		STAGE_4:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_5;
			else
				nstate <= STAGE_4;
		end
		STAGE_5:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_6;
			else
				nstate <= STAGE_5;
		end
		STAGE_6:
		begin
			if(cnt == LCNT)
				nstate <= STAGE_1;
			else
				nstate <= STAGE_6;
		end

		default: nstate <= IDLE;
	endcase

	case(cstate_out)
	IDLE:
	begin
		if(cstate == STAGE_6 && cnt == LCNT)
			nstate_out <= RUN;
		else
			nstate_out <= IDLE;
	end

	RUN:
	begin
		if(cnt_out == LCNT - 2)
			nstate_out <= IDLE;
		else
			nstate_out <= RUN;
	end

	default: nstate <= IDLE;
	endcase
end

// Counter
// cnt
always @(posedge clk) 
begin
	if(!nrst) cnt <= 0;
	else
	begin
		if(cstate == IDLE) 		 cnt <= 0;
		else if(cnt == LCNT) 	 cnt <= 0;
		else 			   		 cnt <= cnt + 1;
	end
end

// cnt_in
always @(posedge clk) 
begin
	if(!nrst) cnt_in <= 0;
	else
	begin
		if(cstate_in == PRE_IN || cstate_in == IDLE)
		begin
			cnt_in <= 0;
		end
		else if(cstate_in == RUN)
		begin
			cnt_in <= cnt_in + 1;
		end
		else cnt_in <= cnt_in;
	end
end

// cnt_out
always @(posedge clk) 
begin
	if(!nrst) cnt_out <= 0;
	else
	begin
		if(cstate_out == IDLE)
		begin
			cnt_out <= 0;
		end
		else if(cnt_out == LCNT - 2)
		begin
			cnt_out <= 0;
		end
		else if(cstate_out == RUN)
		begin
			cnt_out <= cnt_out + 1;
		end
		else cnt_out <= cnt_out;
	end
end

// REG_A
assign en_REG_A = cnt[0]; // 1 for odd count

// REG_B, REG_C
always @(posedge clk) 
begin
	if(!nrst) 
    begin
		en_REG_B <= 0;
		en_REG_C <= 0;
	end
    else if(cstate != IDLE)
    begin
		en_REG_B <= en_REG_A;
		en_REG_C <= en_REG_B;
	end
	else 
    begin
		en_REG_B <= en_REG_B;
		en_REG_C <= en_REG_C;
	end 
end

// Memory Write Enable
assign we_AMEM 	= (cstate == STAGE_1 || cstate == STAGE_3 || cstate == STAGE_5) ? 1 : (cstate == IDLE ? 0 : (cnt < 3 ? 1 : 0));
assign we_BMEM 	= (cstate == STAGE_2 || cstate == STAGE_4 || cstate == STAGE_6) ? 1 : (cstate == IDLE ? 1 : (cnt < 3 ? 1 : 0));
assign we_OMEM 	= (cstate == STAGE_6 && cnt >= 3) ? 0 : 1;

assign out_vld = (cstate_out == RUN && cnt_out) ? 1 : 0;
assign in_rdy  = (cstate_in  == RUN) ? 1 : 0;		

assign sel_input = in_rdy;
assign sel_res   = en_REG_C;  
assign sel_mem   = (cstate == STAGE_2 || cstate == STAGE_4 || cstate == STAGE_6) ? 1 : 0;

// Address
wire [N:0] cnt_dly, cnt_CROM;
assign cnt_dly  = (cnt > 2) ? (cnt - 3) : 0; // Count starts when cnt == 3
assign cnt_CROM = (cnt > 0) ? (cnt - 1) : 0; // Count starts when cnt == 1

wire [N-1:0] tmp0_addr_AMEM, tmp1_addr_AMEM, tmp2_addr_AMEM, tmp3_addr_AMEM, tmp4_addr_AMEM, tmp5_addr_AMEM, tmp6_addr_AMEM;
wire [N-1:0] tmp0_addr_BMEM, tmp1_addr_BMEM, tmp2_addr_BMEM, tmp3_addr_BMEM, tmp4_addr_BMEM, tmp5_addr_BMEM, tmp6_addr_BMEM;
wire [N-1:0] tmp1_addr_CROM, tmp2_addr_CROM, tmp3_addr_CROM, tmp4_addr_CROM, tmp5_addr_CROM, tmp6_addr_CROM;

assign tmp6_addr_AMEM = (!we_AMEM && cstate == STAGE_6) ? {cnt_dly[0], cnt_dly[1], cnt_dly[2], cnt_dly[3], cnt_dly[4], cnt_dly[5]} : 0;
assign tmp5_addr_AMEM = ( we_AMEM && cstate == STAGE_5) ? {cnt[5], cnt[0], cnt[4], cnt[3], cnt[2], cnt[1]} : tmp6_addr_AMEM;
assign tmp4_addr_AMEM = (!we_AMEM && cstate == STAGE_4) ? {cnt_dly[5], cnt_dly[4], cnt_dly[0], cnt_dly[3], cnt_dly[2], cnt_dly[1]} : tmp5_addr_AMEM;
assign tmp3_addr_AMEM = ( we_AMEM && cstate == STAGE_3) ? {cnt[5], cnt[4], cnt[3], cnt[0], cnt[2], cnt[1]} : tmp4_addr_AMEM;
assign tmp2_addr_AMEM = (!we_AMEM && cstate == STAGE_2) ? {cnt_dly[5], cnt_dly[4], cnt_dly[3], cnt_dly[2], cnt_dly[0], cnt_dly[1]} : tmp3_addr_AMEM;
assign tmp1_addr_AMEM = ( we_AMEM && cstate == STAGE_1) ? {cnt[5], cnt[4], cnt[3], cnt[2], cnt[1], cnt[0]} : tmp2_addr_AMEM;
assign tmp0_addr_AMEM = (!we_AMEM && cstate == IDLE   ) ? {cnt_in[0], cnt_in[1], cnt_in[2], cnt_in[3], cnt_in[4], cnt_in[5]} : tmp1_addr_AMEM;

assign tmp6_addr_BMEM = ( we_BMEM && cstate == STAGE_6) ? {cnt[0], cnt[5], cnt[4], cnt[3], cnt[2], cnt[1]} : 0;
assign tmp5_addr_BMEM = (!we_BMEM && cstate == STAGE_5) ? {cnt_dly[5], cnt_dly[0], cnt_dly[4], cnt_dly[3], cnt_dly[2], cnt_dly[1]} : tmp6_addr_BMEM;
assign tmp4_addr_BMEM = ( we_BMEM && cstate == STAGE_4) ? {cnt[5], cnt[4], cnt[0], cnt[3], cnt[2], cnt[1]} : tmp5_addr_BMEM;
assign tmp3_addr_BMEM = (!we_BMEM && cstate == STAGE_3) ? {cnt_dly[5], cnt_dly[4], cnt_dly[3], cnt_dly[0], cnt_dly[2], cnt_dly[1]} : tmp4_addr_BMEM;
assign tmp2_addr_BMEM = ( we_BMEM && cstate == STAGE_2) ? {cnt[5], cnt[4], cnt[3], cnt[2], cnt[0], cnt[1]} : tmp3_addr_BMEM;
assign tmp1_addr_BMEM = (!we_BMEM && cstate == STAGE_1) ? {cnt_dly[5], cnt_dly[4], cnt_dly[3], cnt_dly[2], cnt_dly[1], cnt_dly[0]} :tmp2_addr_BMEM;

assign tmp6_addr_CROM = (cstate == STAGE_6) ? ( 1*cnt_CROM[1] +  2*cnt_CROM[2] +  4*cnt_CROM[3] +  8*cnt_CROM[4]+ 16*cnt_CROM[5]) : 0;
assign tmp5_addr_CROM = (cstate == STAGE_5) ? ( 2*cnt_CROM[1] +  4*cnt_CROM[2] +  8*cnt_CROM[3] + 16*cnt_CROM[4]) : tmp6_addr_CROM;
assign tmp4_addr_CROM = (cstate == STAGE_4) ? ( 4*cnt_CROM[1] +  8*cnt_CROM[2] + 16*cnt_CROM[3]) : tmp5_addr_CROM;
assign tmp3_addr_CROM = (cstate == STAGE_3) ? ( 8*cnt_CROM[1] + 16*cnt_CROM[2]) : tmp4_addr_CROM;
assign tmp2_addr_CROM = (cstate == STAGE_2) ? (16*cnt_CROM[1]) : tmp3_addr_CROM;
assign tmp1_addr_CROM = (cstate == STAGE_1) ? 0 : tmp2_addr_CROM;

assign addr_AMEM = tmp0_addr_AMEM;
assign addr_BMEM = tmp1_addr_BMEM;
assign addr_CROM = (cnt > 0 && cnt < LCNT - 1) ? tmp1_addr_CROM : 0;
assign addr_OMEM = !(we_OMEM) ? {cnt_dly[0], cnt_dly[5], cnt_dly[4], cnt_dly[3], cnt_dly[2], cnt_dly[1]} 
							  : {cnt_out[5], cnt_out[4], cnt_out[3], cnt_out[2], cnt_out[1], cnt_out[0]};

endmodule