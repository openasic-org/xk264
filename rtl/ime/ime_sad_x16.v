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
//                calculate the SAD value of all other partitions inside one single MB
//                
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_sad_x16(

        clk,
        rstn,
        
        sadx8_v_i,
                
        sad8x8_i,
        
        sad8x16_o,
        sad16x8_o,
        sad16x16_o

);

input          clk;
input          rstn;

input          sadx8_v_i;

input   [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0]      sad8x8_i;

output  [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]      sad8x16_o;
output  [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]      sad16x8_o;
output  [`SAD16X16_NUM *`SAD16X16_LEN -1:0]      sad16x16_o;
                    

reg     [`SAD8X16_NUM  *`SAD8X16_LEN  -1:0]      sad8x16_o;
reg     [`SAD16X8_NUM  *`SAD16X8_LEN  -1:0]      sad16x8_o;
reg     [`SAD16X16_NUM *`SAD16X16_LEN -1:0]      sad16x16_o;
                                      
wire [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0] sad8x4_wire; 
wire [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0] sad8x8_wire;                                     


//calculate 8x16 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad8x16_o <= 'b0;
    else if (sadx8_v_i == 1'b1) begin
      sad8x16_o[1*`SAD8X16_LEN-1:0*`SAD8X16_LEN] <=     sad8x8_i[ 1*`SAD8X8_LEN-1: 0*`SAD8X8_LEN] + sad8x8_i[ 3*`SAD8X8_LEN-1: 2*`SAD8X8_LEN];
      sad8x16_o[2*`SAD8X16_LEN-1:1*`SAD8X16_LEN] <=     sad8x8_i[ 2*`SAD8X8_LEN-1: 1*`SAD8X8_LEN] + sad8x8_i[ 4*`SAD8X8_LEN-1: 3*`SAD8X8_LEN];
    end
end

//calculate 16x8 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad16x8_o <= 'b0;
    else if (sadx8_v_i == 1'b1) begin
      sad16x8_o[1*`SAD16X8_LEN-1:0*`SAD16X8_LEN] <=     sad8x8_i[ 1*`SAD8X8_LEN-1: 0*`SAD8X8_LEN] + sad8x8_i[ 2*`SAD8X8_LEN-1: 1*`SAD8X8_LEN];
      sad16x8_o[2*`SAD16X8_LEN-1:1*`SAD16X8_LEN] <=     sad8x8_i[ 3*`SAD8X8_LEN-1: 2*`SAD8X8_LEN] + sad8x8_i[ 4*`SAD8X8_LEN-1: 3*`SAD8X8_LEN];
    end
end

//calculate 16x16 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad16x16_o <= 'b0;
    else if (sadx8_v_i == 1'b1)begin
      sad16x16_o[1*`SAD16X16_LEN-1:0*`SAD8X16_LEN] <=   sad8x8_i[ 1*`SAD8X8_LEN-1: 0*`SAD8X8_LEN] + 
                                                        sad8x8_i[ 2*`SAD8X8_LEN-1: 1*`SAD8X8_LEN] +
                                                        sad8x8_i[ 3*`SAD8X8_LEN-1: 2*`SAD8X8_LEN] + 
                                                        sad8x8_i[ 4*`SAD8X8_LEN-1: 3*`SAD8X8_LEN] ;
    end
end


endmodule
