`timescale 1ns / 1ns // timescale time_unit/time_presicion

`default_nettype none


`define WIDTH_BITS       11      //2047, max 1280
`define HEIGHT_BITS      11

`define MAX_PTS          2048    //2048
`define PT_RAM_ADDR_BITS 10      //每项存2点
`define PT_RAM_DATA_WIDTH 100       //19bit x+frac_x,19bit y+frac_y,1bit flag,11bit 在原始点数组中的index

//`define RANDOM_INIT

