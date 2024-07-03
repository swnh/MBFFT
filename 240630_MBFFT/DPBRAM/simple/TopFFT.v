module TopFFT(
    input clk, rstn, in_vld, out_rdy,
    input [31:0] ext_data_input,
    output in_rdy, out_vld,
    output [31:0] ext_data_output
); 

    reg  [31:0] REG_C;
    wire [31:0] out_REG_A, out_REG_B;
    wire [31:0] data_rd_BANK3, data_rd_BANK2;
    wire [31:0] data_rd_BANK1, data_rd_BANK0, data_rd_ROM;
    wire [31:0] data_wr_BANK1, data_wr_BANK0;
    wire [31:0] out_FFT1, out_FFT0;
    wire [2:0]  addr_in_BANK1, addr_in_BANK0;
    wire [2:0]  addr_out_BANK1, addr_out_BANK0;
    wire [2:0]  addr_out_BANK3, addr_out_BANK2;
    wire [2:0]  addr_out_ROM;
    wire [31:0] out_dout;

    wire en_REG_RD, en_REG_WR, en_REG_C;
    wire sel_rd_swap, sel_out_bank;
    wire sel_wr_swap, sel_wr_bank, sel_din;


    FFT FFT(
        .out_REG_A(out_REG_A),
        .out_REG_B(out_REG_B),
        .data_rd_ROM(data_rd_ROM),
        .out_FFT1(out_FFT1),
        .out_FFT0(out_FFT0)
    );

    RD RD(
        .clk(clk),
        .rstn(rstn),
        .data_rd_BANK1(data_rd_BANK1),
        .data_rd_BANK0(data_rd_BANK0),
        .en_REG_RD(en_REG_RD),
        .out_REG_A(out_REG_A),
        .out_REG_B(out_REG_B),
        .sel_rd_swap(sel_rd_swap)
    );

    WR WR(
        .clk(clk),
        .rstn(rstn),
        .ext_data_input(ext_data_input),
        .in_REG_D(out_FFT1),
        .in_REG_E(out_FFT0),
        .en_REG_WR(en_REG_WR),
        .data_wr_BANK1(data_wr_BANK1),
        .data_wr_BANK0(data_wr_BANK0),
        .sel_wr_swap(sel_wr_swap),
        .sel_wr_bank(sel_wr_bank),
        .sel_din(sel_din)
    );

    controller controller(
        .clk(clk),
        .rstn(rstn),
        .in_rdy(in_rdy),
        .in_vld(in_vld),
        .out_rdy(out_rdy),
        .out_vld(out_vld),
        // RD, WR, C REG EN 
        .en_REG_RD(en_REG_RD),
        .en_REG_WR(en_REG_WR),
        .en_REG_C(en_REG_C),
        // BANK WE
        .we_BANK1(we_BANK1),
        .we_BANK0(we_BANK0),
        .we_out_BANK(we_out_BANK),
        // RD, WR MUX
        .sel_rd_swap(sel_rd_swap),
        .sel_wr_swap(sel_wr_swap),
        .sel_din(sel_din),
        .sel_out_bank(sel_out_bank),
        .sel_wr_bank(sel_wr_bank),
        // MEM ADDR
        .addr_in_BANK1(addr_in_BANK1),
        .addr_in_BANK0(addr_in_BANK0),
        .addr_out_BANK3(addr_out_BANK3),
        .addr_out_BANK2(addr_out_BANK2),
        .addr_out_BANK1(addr_out_BANK1),
        .addr_out_BANK0(addr_out_BANK0),
        .addr_out_ROM(addr_out_ROM)
    );

    blk_mem_gen_0 BANK1(
        .clka(clk),
        .addra(addr_in_BANK1),
        .dina(data_wr_BANK1),
        .wea(we_BANK1),
        .clkb(clk),
        .addrb(addr_out_BANK1),
        .doutb(data_rd_BANK1)
    );
    
    blk_mem_gen_0 BANK0(
        .clka(clk),
        .addra(addr_in_BANK0),
        .dina(data_wr_BANK0),
        .wea(we_BANK0),
        .clkb(clk),
        .addrb(addr_out_BANK0),
        .doutb(data_rd_BANK0)
    );
    
    blk_mem_gen_1 ROM(
        .clka(clk),
        .addra(addr_out_ROM),
        .douta(data_rd_ROM)
    );

    blk_mem_gen_0 BANK3(
        .clka(clk),
        .addra(addr_in_BANK1),
        .dina(data_wr_BANK1),
        .wea(we_out_BANK),
        .clkb(clk),
        .addrb(addr_out_BANK3),
        .doutb(data_rd_BANK3)
    );
    
    blk_mem_gen_0 BANK2(
        .clka(clk),
        .addra(addr_in_BANK0),
        .dina(data_wr_BANK0),
        .wea(we_out_BANK),
        .clkb(clk),
        .addrb(addr_out_BANK2),
        .doutb(data_rd_BANK2)
    );

    assign out_dout = sel_out_bank ? data_rd_BANK3 : data_rd_BANK2;

    always @(posedge clk)
    begin
        if (!rstn) REG_C <= 0;
        else if (en_REG_C) REG_C <= out_dout;
        else REG_C <= REG_C;
    end

    assign ext_data_output = REG_C;

endmodule