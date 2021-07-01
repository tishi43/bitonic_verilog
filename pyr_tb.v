//--------------------------------------------------------------------------------------------------
// Copyright (C) 2021 tianqishi
// All rights reserved
// Design    : bitstream_p
// Author(s) : tianqishi
// Email     : tishi1@126.com
// QQ        : 2483210587
//-------------------------------------------------------------------------------------------------

`include "bitonic_defines.v"

`timescale 1ns / 1ns // timescale time_unit/time_presicion

module pyr_tb;
reg rst;
reg dec_clk;


initial begin

    rst <= 0;
    #100 rst <= 1;
    #100 rst <= 0;

end


always
begin
    #1 dec_clk = 0;
    #1 dec_clk = 1;
end

wire      [`PT_RAM_ADDR_BITS-1: 0]   pt_ram_addra;
wire      [`PT_RAM_ADDR_BITS-1: 0]   pt_ram_addrb;
wire      [`PT_RAM_DATA_WIDTH-1:0]   pt_ram_dia;
wire      [`PT_RAM_DATA_WIDTH-1:0]   pt_ram_dob;
wire                                 pt_ram_we;
wire                         [3:0]   stage;

ram_simple_dual #(`PT_RAM_ADDR_BITS, `PT_RAM_DATA_WIDTH) point_ram
(
    .clk(dec_clk),
    .en(1'b1),
    .we(pt_ram_we),
    .addra(pt_ram_addra),
    .addrb(pt_ram_addrb),
    .dia(pt_ram_dia),
    .dob(pt_ram_dob)
);

bitonic_sort sort_inst
(
    .clk(dec_clk),
    .rst(rst),
    .pt_ram_addra(pt_ram_addra),
    .pt_ram_addrb(pt_ram_addrb),
    .pt_ram_dia(pt_ram_dia),
    .pt_ram_dob(pt_ram_dob),
    .pt_ram_we(pt_ram_we),
    .stage(stage)

);

endmodule


