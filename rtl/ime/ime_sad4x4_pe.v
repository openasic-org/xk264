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
// Filename       : ime_sad4x4_pe.v
// Author         : Yibo FAN
// Created        : 2012-04-06
// Description    : IME Defines
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_sad4x4_pe(
    clk,
    rstn,    
    cmb4x4_i,
    ref4x4_i,
    enable_i,    
    sad4x4_o    
);

input clk;
input rstn;
input enable_i;
input   [`B4X4_SIZE*`BIT_DEPTH-1:0]      cmb4x4_i;          //current MB ; 4x4_sub_block 
input   [`B4X4_SIZE*`BIT_DEPTH-1:0]      ref4x4_i;          //ref     MB ; 4x4_sub_block 
output    [`SAD4X4_LEN -1:0 ]    sad4x4_o;                //sad value for one 4x4 block  8+4+1 


wire    [`BIT_DEPTH*`B4X4_SIZE -1:0 ]    abs4x4_o;  //16 abs value for each pixels in 4x4block ; 16x8 
reg     [`SAD4X4_LEN -1:0 ]    sad4x4_o;   //13 

reg [`SAD2X2_LEN-1:0] sad2x2_reg0;     //8+2+1 
reg [`SAD2X2_LEN-1:0] sad2x2_reg1;
reg [`SAD2X2_LEN-1:0] sad2x2_reg2;
reg [`SAD2X2_LEN-1:0] sad2x2_reg3;

//16 pixels in 4x4 block, 16 abs operation for 4x4 block
genvar i; 
generate 
    for(i = 0; i < `B4X4_SIZE; i = i +1 ) begin : ime_abs_n   //16 
    ime_abs ime_abs
               ( .a_i(cmb4x4_i[(i+1)*`BIT_DEPTH-1:i*`BIT_DEPTH]),
                 .b_i(ref4x4_i[(i+1)*`BIT_DEPTH-1:i*`BIT_DEPTH]),                 
                 .abs_o(abs4x4_o[(i+1)*`BIT_DEPTH-1:i*`BIT_DEPTH])
                );
    end
endgenerate


always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad4x4_o <= 'b0;
    else begin 
        sad4x4_o <=    
             sad2x2_reg0 + 
             sad2x2_reg1 + 
             sad2x2_reg2 + 
             sad2x2_reg3 ;
    end        
end




always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad2x2_reg0 <= 'b0;
    else if (enable_i == 1'b0)
        sad2x2_reg0 <= 'b0;
    else begin
        sad2x2_reg0 <=     
            abs4x4_o[(0+1)*`BIT_DEPTH-1:0*`BIT_DEPTH] + 
            abs4x4_o[(1+1)*`BIT_DEPTH-1:1*`BIT_DEPTH] +
            abs4x4_o[(2+1)*`BIT_DEPTH-1:2*`BIT_DEPTH] +
            abs4x4_o[(3+1)*`BIT_DEPTH-1:3*`BIT_DEPTH] ;
    end     
end

always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad2x2_reg1 <= 'b0;
    else if (enable_i == 1'b0)
        sad2x2_reg1 <= 'b0;
    else begin
        sad2x2_reg1 <=     
            abs4x4_o[(4+1)*`BIT_DEPTH-1:4*`BIT_DEPTH] + 
            abs4x4_o[(5+1)*`BIT_DEPTH-1:5*`BIT_DEPTH] +
            abs4x4_o[(6+1)*`BIT_DEPTH-1:6*`BIT_DEPTH] +
            abs4x4_o[(7+1)*`BIT_DEPTH-1:7*`BIT_DEPTH] ;
    end     
end

always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad2x2_reg2 <= 'b0;
    else if (enable_i == 1'b0)
        sad2x2_reg2 <= 'b0;
    else begin
        sad2x2_reg2 <=     
            abs4x4_o[( 8+1)*`BIT_DEPTH-1: 8*`BIT_DEPTH] + 
            abs4x4_o[( 9+1)*`BIT_DEPTH-1: 9*`BIT_DEPTH] +
            abs4x4_o[(10+1)*`BIT_DEPTH-1:10*`BIT_DEPTH] +
            abs4x4_o[(11+1)*`BIT_DEPTH-1:11*`BIT_DEPTH] ;
    end     
end

always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        sad2x2_reg3 <= 'b0;
    else if (enable_i == 1'b0)
        sad2x2_reg3 <= 'b0;
    else begin
        sad2x2_reg3 <=     
            abs4x4_o[(12+1)*`BIT_DEPTH-1:12*`BIT_DEPTH] + 
            abs4x4_o[(13+1)*`BIT_DEPTH-1:13*`BIT_DEPTH] +
            abs4x4_o[(14+1)*`BIT_DEPTH-1:14*`BIT_DEPTH] +
            abs4x4_o[(15+1)*`BIT_DEPTH-1:15*`BIT_DEPTH] ;
    end     
end

endmodule
