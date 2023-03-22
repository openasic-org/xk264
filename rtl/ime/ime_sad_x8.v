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
// Filename       : .v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                calculate the SAD value of 8x8, 8x4 and 4x8 inside one single MB
//                
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_sad_x8(
        clk,
        rstn,
        
        sad4x4_v_i,
                
        sad4x4_i,
        
        sad4x8_o,
        sad8x4_o,
        sad8x8_o
);

input          clk;
input          rstn;

input                                            sad4x4_v_i;

input   [`SAD4X4_NUM*`SAD4X4_LEN-1:0]            sad4x4_i;  ////16x13 ; 13 means sad_4x4_block output 

output  [`SAD4X8_NUM   *`SAD4X8_LEN   -1:0]      sad4x8_o;  //8x14
output  [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0]      sad8x4_o;  //8x14
output  [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0]      sad8x8_o;  //4x15
                    

reg     [`SAD4X8_NUM   *`SAD4X8_LEN   -1:0]      sad4x8_o;
reg     [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0]      sad8x4_o;
reg     [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0]      sad8x8_o;
                                      
wire [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0] sad8x4_wire; 
wire [`SAD8X8_NUM   *`SAD8X8_LEN   -1:0] sad8x8_wire;                                     

//calculate 4x8 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad4x8_o <= 'b0;
    else  if(sad4x4_v_i == 1'b1) begin
      sad4x8_o[1*`SAD4X8_LEN-1:0*`SAD4X8_LEN] <=     sad4x4_i[ 1*`SAD4X4_LEN-1: 0*`SAD4X4_LEN] + sad4x4_i[ 3*`SAD4X4_LEN-1: 2*`SAD4X4_LEN];
      sad4x8_o[2*`SAD4X8_LEN-1:1*`SAD4X8_LEN] <=     sad4x4_i[ 2*`SAD4X4_LEN-1: 1*`SAD4X4_LEN] + sad4x4_i[ 4*`SAD4X4_LEN-1: 3*`SAD4X4_LEN];
      sad4x8_o[3*`SAD4X8_LEN-1:2*`SAD4X8_LEN] <=     sad4x4_i[ 5*`SAD4X4_LEN-1: 4*`SAD4X4_LEN] + sad4x4_i[ 7*`SAD4X4_LEN-1: 6*`SAD4X4_LEN];
      sad4x8_o[4*`SAD4X8_LEN-1:3*`SAD4X8_LEN] <=     sad4x4_i[ 6*`SAD4X4_LEN-1: 5*`SAD4X4_LEN] + sad4x4_i[ 8*`SAD4X4_LEN-1: 7*`SAD4X4_LEN];
      sad4x8_o[5*`SAD4X8_LEN-1:4*`SAD4X8_LEN] <=     sad4x4_i[ 9*`SAD4X4_LEN-1: 8*`SAD4X4_LEN] + sad4x4_i[11*`SAD4X4_LEN-1:10*`SAD4X4_LEN];
      sad4x8_o[6*`SAD4X8_LEN-1:5*`SAD4X8_LEN] <=     sad4x4_i[10*`SAD4X4_LEN-1: 9*`SAD4X4_LEN] + sad4x4_i[12*`SAD4X4_LEN-1:11*`SAD4X4_LEN];
      sad4x8_o[7*`SAD4X8_LEN-1:6*`SAD4X8_LEN] <=     sad4x4_i[13*`SAD4X4_LEN-1:12*`SAD4X4_LEN] + sad4x4_i[15*`SAD4X4_LEN-1:14*`SAD4X4_LEN];
      sad4x8_o[8*`SAD4X8_LEN-1:7*`SAD4X8_LEN] <=     sad4x4_i[14*`SAD4X4_LEN-1:13*`SAD4X4_LEN] + sad4x4_i[16*`SAD4X4_LEN-1:15*`SAD4X4_LEN];
    end
end

//wire [`SAD8X4_NUM   *`SAD8X4_LEN   -1:0] sad8x4_wire;
 
assign sad8x4_wire[1*`SAD8X4_LEN-1:0*`SAD8X4_LEN]  =     sad4x4_i[ 1*`SAD4X4_LEN-1: 0*`SAD4X4_LEN] + sad4x4_i[ 2*`SAD4X4_LEN-1:1*`SAD4X4_LEN];
assign sad8x4_wire[2*`SAD8X4_LEN-1:1*`SAD8X4_LEN]  =     sad4x4_i[ 3*`SAD4X4_LEN-1: 2*`SAD4X4_LEN] + sad4x4_i[ 4*`SAD4X4_LEN-1:3*`SAD4X4_LEN];
assign sad8x4_wire[3*`SAD8X4_LEN-1:2*`SAD8X4_LEN]  =     sad4x4_i[ 5*`SAD4X4_LEN-1: 4*`SAD4X4_LEN] + sad4x4_i[ 6*`SAD4X4_LEN-1:5*`SAD4X4_LEN];
assign sad8x4_wire[4*`SAD8X4_LEN-1:3*`SAD8X4_LEN]  =     sad4x4_i[ 7*`SAD4X4_LEN-1: 6*`SAD4X4_LEN] + sad4x4_i[ 8*`SAD4X4_LEN-1:7*`SAD4X4_LEN];
assign sad8x4_wire[5*`SAD8X4_LEN-1:4*`SAD8X4_LEN]  =     sad4x4_i[ 9*`SAD4X4_LEN-1: 8*`SAD4X4_LEN] + sad4x4_i[10*`SAD4X4_LEN-1:9*`SAD4X4_LEN];
assign sad8x4_wire[6*`SAD8X4_LEN-1:5*`SAD8X4_LEN]  =     sad4x4_i[11*`SAD4X4_LEN-1:10*`SAD4X4_LEN] + sad4x4_i[12*`SAD4X4_LEN-1:11*`SAD4X4_LEN];
assign sad8x4_wire[7*`SAD8X4_LEN-1:6*`SAD8X4_LEN]  =     sad4x4_i[13*`SAD4X4_LEN-1:12*`SAD4X4_LEN] + sad4x4_i[14*`SAD4X4_LEN-1:13*`SAD4X4_LEN];
assign sad8x4_wire[8*`SAD8X4_LEN-1:7*`SAD8X4_LEN]  =     sad4x4_i[15*`SAD4X4_LEN-1:14*`SAD4X4_LEN] + sad4x4_i[16*`SAD4X4_LEN-1:15*`SAD4X4_LEN];

//calculate 8x4 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad8x4_o <= 'b0;
    else if(sad4x4_v_i == 1'b1) begin
          sad8x4_o <=     sad8x4_wire;
    end
end
    

assign sad8x8_wire[1*`SAD8X8_LEN-1:0*`SAD8X8_LEN] =     sad8x4_wire[ 1*`SAD8X4_LEN-1: 0*`SAD8X4_LEN] + sad8x4_wire[ 2*`SAD8X4_LEN-1:1*`SAD8X4_LEN];
assign sad8x8_wire[2*`SAD8X8_LEN-1:1*`SAD8X8_LEN] =     sad8x4_wire[ 3*`SAD8X4_LEN-1: 2*`SAD8X4_LEN] + sad8x4_wire[ 4*`SAD8X4_LEN-1:3*`SAD8X4_LEN];
assign sad8x8_wire[3*`SAD8X8_LEN-1:2*`SAD8X8_LEN] =     sad8x4_wire[ 5*`SAD8X4_LEN-1: 4*`SAD8X4_LEN] + sad8x4_wire[ 6*`SAD8X4_LEN-1:5*`SAD8X4_LEN];
assign sad8x8_wire[4*`SAD8X8_LEN-1:3*`SAD8X8_LEN] =     sad8x4_wire[ 7*`SAD8X4_LEN-1: 6*`SAD8X4_LEN] + sad8x4_wire[ 8*`SAD8X4_LEN-1:7*`SAD8X4_LEN];
         
//calculate 8x8 sad
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad8x8_o <= 'b0;
    else if (sad4x4_v_i == 1'b1) begin
      sad8x8_o <= sad8x8_wire;
    end
end

endmodule
