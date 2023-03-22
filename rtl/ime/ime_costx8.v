//-------------------------------------------------------------------
//                                                                 
//  COPYRIGHT (C) 2011, VIPcore Group, Fudan University
//                                                                  
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE      
//  EXPRESSED WRITTEN CONSENT OF VIPcore Group
//                                                                  
//  VIPcore       : http://soc.fudan.edu.cn/vip    
//  IP Owner 	  : Yibo FAN
//  Contact       : fanyibo@fudan.edu.cn             
//-------------------------------------------------------------------
// Filename       : fme_top.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                calculate the SAD value of 8x8, 4x8 and 8x4 partitions inside one single MB
//                
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_costx8(

        clk,
        rstn,
        
        mv_cost_i,
        sadx8_v_i,
        
        sad4x8_i,
        sad8x4_i,
        sad8x8_i,
        
        cost4x8_o,
        cost8x4_o,
        cost8x8_o
);

input  clk;
input  rstn;

input                                 sadx8_v_i;

input   [`MV_COST_BITS-1:0]           mv_cost_i;  

input   [`SAD4X8_NUM   *`SAD4X8_LEN   -1:0]     sad4x8_i;
input   [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0]     sad8x4_i;
input   [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0]     sad8x8_i;

output  [`SAD4X8_NUM   *`COST4X8_LEN   -1:0]    cost4x8_o;
output  [`SAD8X4_NUM   *`COST8X4_LEN   -1:0]    cost8x4_o;
output  [`SAD8X8_NUM   *`COST8X8_LEN   -1:0]    cost8x8_o;

reg      [`SAD4X8_NUM   *`COST4X8_LEN   -1:0]    cost4x8_o;
reg      [`SAD8X4_NUM   *`COST8X4_LEN   -1:0]    cost8x4_o;
reg      [`SAD8X8_NUM   *`COST8X8_LEN   -1:0]    cost8x8_o;

wire     [`SAD4X8_NUM   *`COST4X8_LEN   -1:0]    cost4x8_wire;
wire     [`SAD8X4_NUM   *`COST8X4_LEN   -1:0]    cost8x4_wire;
wire     [`SAD8X8_NUM   *`COST8X8_LEN   -1:0]    cost8x8_wire;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cost4x8_o    <='b0; 
        cost8x4_o    <='b0; 
        cost8x8_o    <='b0; 
    end    
    else begin
        cost4x8_o    <= cost4x8_wire ; 
        cost8x4_o    <= cost8x4_wire ; 
        cost8x8_o    <= cost8x8_wire ; 
    end                          
                        
end

genvar i; 
generate 
    for(i = 0; i < `SAD4X8_NUM; i = i +1 ) begin : ime_cost4x8_n
    //ime_cost4x8 ime_cost4x8
    assign cost4x8_wire[(i+1)*`COST4X8_LEN-1:i*`COST4X8_LEN] = sad4x8_i[(i+1)*`SAD4X8_LEN-1:i*`SAD4X8_LEN] + mv_cost_i;
    end
    
    for(i = 0; i < `SAD8X4_NUM; i = i +1 ) begin : ime_cost8x4_n
    //ime_cost8x4 ime_cost8x4
    assign cost8x4_wire[(i+1)*`COST8X4_LEN-1:i*`COST8X4_LEN] = sad8x4_i[(i+1)*`SAD8X4_LEN-1:i*`SAD8X4_LEN] + mv_cost_i;
    end
    
    for(i = 0; i < `SAD8X8_NUM; i = i +1 ) begin : ime_cost8x8_n
    //ime_cost8x8 ime_cost8x8
    assign cost8x8_wire[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN] = sad8x8_i[(i+1)*`SAD8X8_LEN-1:i*`SAD8X8_LEN] + mv_cost_i;
    end
endgenerate


endmodule
