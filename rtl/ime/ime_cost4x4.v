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
//                calculate the cost of 4x4 block
//                
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_cost4x4(
        clk,
        rstn,        
        mv_cost_i,        
        sad4x4_v_i,
        sad4x4_i,        
        cost4x4_o
);

input                                 clk;
input                                 rstn;
input                                 sad4x4_v_i;
input  [`MV_COST_BITS-1:0]            mv_cost_i;
input  [`SAD4X4_NUM*`SAD4X4_LEN-1:0]  sad4x4_i;   //16x13
output [`SAD4X4_NUM*`COST4X4_LEN-1:0]  cost4x4_o;
reg    [`SAD4X4_NUM*`COST4X4_LEN-1:0]  cost4x4_o;
wire   [`SAD4X4_NUM*`COST4X4_LEN-1:0]  cost4x4_wire; //16x13 

always@(posedge clk or negedge rstn) begin
    if(!rstn) 
        cost4x4_o    <='b0;  
    else if(sad4x4_v_i)
        cost4x4_o    <= cost4x4_wire;
end

genvar i; 
generate 
    for(i = 0; i < `SAD4X4_NUM; i = i +1 ) begin : ime_cost4x4_n  //16  4x4_block cost 
    	assign cost4x4_wire[(i+1)*`COST4X4_LEN-1:i*`COST4X4_LEN] = sad4x4_i[(i+1)*`SAD4X4_LEN-1:i*`SAD4X4_LEN] + mv_cost_i;
    end
endgenerate

endmodule
