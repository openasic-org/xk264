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
// Filename       : ime_sad4x4.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                  calculate the SAD value of 16 4x4 blocks inside one single MB
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_sad4x4(
    clk,
    rstn,    
    cmb_i,
    ref_i,
    enable_i,    
    sad4x4_o
);

input                                        clk;
input                                        rstn;
input                                        enable_i;

input   [`MB_SIZE*`BIT_DEPTH-1:0]            cmb_i;      //current MB
input   [`MB_SIZE*`BIT_DEPTH-1:0]            ref_i;      //ref     MB

output  [`SAD4X4_NUM*`SAD4X4_LEN-1:0 ]       sad4x4_o;     //all 16  sad value of 4x4 block ; 16x13 


reg [`SAD4X4_NUM*`B4X4_SIZE*`BIT_DEPTH-1:0] cmb;     //16x16 pixels 
reg [`SAD4X4_NUM*`B4X4_SIZE*`BIT_DEPTH-1:0] ref_temp;     //16x16 pixels 


//PE block for each 4x4 block, calculate the sad of 4x4 block
//16 4x4 PE for a MB, each one for a 4x4 block
genvar i,j,m; 
generate 
    for(i=0;i<`SAD8X8_NUM; i=i+1) begin: n_i   //4
      for(j=0;j<4;           j=j+1) begin: j_n
        for(m=0;m<`B4X4_SIZE;  m=m+1) begin: m_n  //16
          always @( * ) begin
            cmb[((i*4 + j)*`B4X4_SIZE + 1 + m)*`BIT_DEPTH-1:((i*4 + j)*`B4X4_SIZE + m)*`BIT_DEPTH] = 
              cmb_i[(((i/2)*8 + (j/2)*4 + (m/4))*`MB_WIDTH + (i%2)*8 + (j%2)*4 + (m%4) + 1)*`BIT_DEPTH-1:(((i/2)*8 + (j/2)*4 + (m/4))*`MB_WIDTH + (i%2)*8 + (j%2)*4 + (m%4))*`BIT_DEPTH];
            ref_temp[((i*4 + j)*`B4X4_SIZE + 1 + m)*`BIT_DEPTH-1:((i*4 + j)*`B4X4_SIZE + m)*`BIT_DEPTH] = 
              ref_i[(((i/2)*8 + (j/2)*4 + (m/4))*`MB_WIDTH + (i%2)*8 + (j%2)*4 + (m%4) + 1)*`BIT_DEPTH-1:(((i/2)*8 + (j/2)*4 + (m/4))*`MB_WIDTH + (i%2)*8 + (j%2)*4 + (m%4))*`BIT_DEPTH];
          end
        end
      end
    end
    
    for(i = 0; i < `SAD4X4_NUM; i = i +1 ) begin : ime_sad4x4_pe_n  // 16 
    ime_sad4x4_pe ime_sad4x4_pe(
        .clk              (clk),
        .rstn             (rstn),        
        .enable_i         (enable_i),
        .cmb4x4_i         (cmb[(i+1)*`B4X4_SIZE*`BIT_DEPTH-1:i*`B4X4_SIZE*`BIT_DEPTH]), // 16x8= 16pixels ; 4x4sub_block
        .ref4x4_i         (ref_temp[(i+1)*`B4X4_SIZE*`BIT_DEPTH-1:i*`B4X4_SIZE*`BIT_DEPTH]),        
        .sad4x4_o         (sad4x4_o[(i+1)*`SAD4X4_LEN-1:i*`SAD4X4_LEN])
    );
    end
endgenerate

endmodule
