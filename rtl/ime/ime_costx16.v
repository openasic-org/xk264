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
// Filename       : ime_costx16.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                calculate the SAD value of all other partitions inside one single MB
//                apart from 4x4 blocks
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_costx16(

        clk,
        rstn,
        
        mv_cost_i,
        
        sadx16_v_i,
                
        sad8x16_i,
        sad16x8_i,
        sad16x16_i,
        
        cost8x16_o,
        cost16x8_o,
        cost16x16_o
);

input                        clk;
input                        rstn;
input                                 sadx16_v_i;

input  [`MV_COST_BITS-1:0]            mv_cost_i;  

input   [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]     sad8x16_i;
input   [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]     sad16x8_i;
input   [`SAD16X16_NUM *`SAD16X16_LEN -1:0]     sad16x16_i;
    
output  [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]     cost8x16_o;
output  [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]     cost16x8_o;
output  [`SAD16X16_NUM *`SAD16X16_LEN -1:0]     cost16x16_o;

reg      [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]    cost8x16_o;
reg      [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]    cost16x8_o;
reg      [`SAD16X16_NUM *`SAD16X16_LEN -1:0]    cost16x16_o;

wire     [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]    cost8x16_wire;
wire     [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]    cost16x8_wire;
wire     [`SAD16X16_NUM *`SAD16X16_LEN -1:0]    cost16x16_wire;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        cost8x16_o   <='b0; 
        cost16x8_o   <='b0; 
        cost16x16_o  <='b0; 
    end    
    else begin
        cost8x16_o   <= cost8x16_wire ; 
        cost16x8_o   <= cost16x8_wire ; 
        cost16x16_o  <= cost16x16_wire ; 
    end                          
                        
end

genvar i; 
generate 
    for(i = 0; i < `SAD8X16_NUM; i = i +1 ) begin : ime_cost8x16_n
    //ime_cost8x16 ime_cost8x16
    assign cost8x16_wire[(i+1)*`SAD8X16_LEN-1:i*`SAD8X16_LEN] = sad8x16_i[(i+1)*`SAD8X16_LEN-1:i*`SAD8X16_LEN] + mv_cost_i;
    end
    
    for(i = 0; i < `SAD16X8_NUM; i = i +1 ) begin : ime_cost16x8_n
    //ime_cost16x8 ime_cost16x8
    assign cost16x8_wire[(i+1)*`SAD16X8_LEN-1:i*`SAD16X8_LEN] = sad16x8_i[(i+1)*`SAD16X8_LEN-1:i*`SAD16X8_LEN] + mv_cost_i;
    end
    
    
    for(i = 0; i < `SAD16X16_NUM; i = i +1 ) begin : ime_cost16x16_n
    //ime_cost16x16 ime_cost16x16
    assign cost16x16_wire[(i+1)*`SAD16X16_LEN-1:i*`SAD16X16_LEN] = sad16x16_i[(i+1)*`SAD16X16_LEN-1:i*`SAD16X16_LEN] + mv_cost_i;
    end
    
endgenerate


endmodule
