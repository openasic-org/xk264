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
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_abs(
    a_i,
    b_i,
    abs_o    
);

input [`BIT_DEPTH-1:0]  a_i;
input [`BIT_DEPTH-1:0]  b_i;
output [`BIT_DEPTH-1:0] abs_o;

wire [`BIT_DEPTH:0] diff;

assign  diff =  {1'b0,a_i} - {1'b0,b_i};
                                         
assign  abs_o =   (diff[`BIT_DEPTH] == 1'b0) ? diff[`BIT_DEPTH-1:0] : (~diff[`BIT_DEPTH-1:0] +1'b1) ;

endmodule
