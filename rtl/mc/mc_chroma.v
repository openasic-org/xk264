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
// Filename       : fme_datapath.v
// Author         : Jialiang Liu
// Created        : 2011.5-2011.6
// Description    : 
//                  
//                  
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module mc_chroma(
          clk_i,
          rst_n_i,
          
          frac0_i,
          frac1_i,
          
          end_oneblk_rd_i,
          
          refuv_valid_i,
          refuv0_p0_i,
          refuv0_p1_i,
          refuv0_p2_i,
          refuv1_p0_i,
          refuv1_p1_i,
          refuv1_p2_i,
         
          end_oneblk_ip_o,
          fracuv_valid_o,
          fracuv_p0_o,
          fracuv_p1_o,
          fracuv_p2_o,
          fracuv_p3_o
);


// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                   clk_i;
input                   rst_n_i;
input  [5          :0]  frac0_i;
input  [5          :0]  frac1_i;
input                   end_oneblk_rd_i;
output                  end_oneblk_ip_o;
input                   refuv_valid_i;
input  [`BIT_DEPTH-1:0] refuv0_p0_i;
input  [`BIT_DEPTH-1:0] refuv0_p1_i;
input  [`BIT_DEPTH-1:0] refuv0_p2_i;
input  [`BIT_DEPTH-1:0] refuv1_p0_i;
input  [`BIT_DEPTH-1:0] refuv1_p1_i;
input  [`BIT_DEPTH-1:0] refuv1_p2_i;
output                  fracuv_valid_o;
output [`BIT_DEPTH-1:0] fracuv_p0_o;
output [`BIT_DEPTH-1:0] fracuv_p1_o;
output [`BIT_DEPTH-1:0] fracuv_p2_o;
output [`BIT_DEPTH-1:0] fracuv_p3_o;



// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************
reg [1:0] end_oneblk_d;



// ********************************************
//                                             
//    Sequential Logic   Combinational Logic 
//                                             
// ********************************************
mc_chroma_ip_2pel mc_chroma_ip0_2pel(
    .clk_i         ( clk_i           ),
    .rst_n_i       ( rst_n_i         ),
    .fracx_i       ( frac0_i[2:0]    ),
    .fracy_i       ( frac0_i[5:3]    ),
    .end_oneblk_i  ( end_oneblk_rd_i ),
    .ref_valid_i   ( refuv_valid_i   ),
    .refuv_p0_i    ( refuv0_p0_i     ),
    .refuv_p1_i    ( refuv0_p1_i     ),
    .refuv_p2_i    ( refuv0_p2_i     ),
    .fracuv_valid_o( fracuv_valid_o  ),
    .fracuv_p0_o   ( fracuv_p0_o     ),
    .fracuv_p1_o   ( fracuv_p1_o     )
);

mc_chroma_ip_2pel mc_chroma_ip1_2pel(
    .clk_i         ( clk_i           ),
    .rst_n_i       ( rst_n_i         ),
    .fracx_i       ( frac1_i[2:0]    ),
    .fracy_i       ( frac1_i[5:3]    ),
    .end_oneblk_i  ( end_oneblk_rd_i ),
    .ref_valid_i   ( refuv_valid_i   ),
    .refuv_p0_i    ( refuv1_p0_i     ),
    .refuv_p1_i    ( refuv1_p1_i     ),
    .refuv_p2_i    ( refuv1_p2_i     ),
    .fracuv_valid_o(                 ),
    .fracuv_p0_o   ( fracuv_p2_o     ),
    .fracuv_p1_o   ( fracuv_p3_o     )
);

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_oneblk_d <= 'd0;
  else
    end_oneblk_d <= {end_oneblk_d[0],end_oneblk_rd_i};
end

assign end_oneblk_ip_o = end_oneblk_d[1];

endmodule
