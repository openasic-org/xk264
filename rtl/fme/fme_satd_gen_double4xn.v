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
// Filename       : satd_gen_double4xn.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------  
`include "enc_defines.v"

module satd_gen_double4xn(
       clk_i                  ,
       rst_n_i                ,
       cmb_p0_i,cmb_p1_i      ,
       cmb_p2_i,cmb_p3_i      ,
       cmb_p4_i,cmb_p5_i      ,
       cmb_p6_i,cmb_p7_i      ,
       valid_i                ,
       ip0_sp0_i,ip0_sp1_i    ,
       ip0_sp2_i,ip0_sp3_i    ,
       ip1_sp0_i,ip1_sp1_i    ,
       ip1_sp2_i,ip1_sp3_i    ,
       hd0_satd_4xn_o         , 
       hd1_satd_4xn_o         ,
       satd_4x4_valid_o       , 
       satd_blk_valid_i 
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                        clk_i                                  ;
input                        rst_n_i                                ;
//CMB pels                                                          
input   [`BIT_DEPTH-1    :0] cmb_p0_i,cmb_p1_i,cmb_p2_i,cmb_p3_i    ;
input   [`BIT_DEPTH-1    :0] cmb_p4_i,cmb_p5_i,cmb_p6_i,cmb_p7_i    ;
//subpels                
input                        valid_i                                ;
input   [`BIT_DEPTH-1    :0] ip0_sp0_i,ip0_sp1_i,ip0_sp2_i,ip0_sp3_i;
input   [`BIT_DEPTH-1    :0] ip1_sp0_i,ip1_sp1_i,ip1_sp2_i,ip1_sp3_i;
//
output  [`SATD_BLK_BITS-2:0] hd0_satd_4xn_o                         ;
output  [`SATD_BLK_BITS-2:0] hd1_satd_4xn_o                         ;
output                       satd_4x4_valid_o                       ; //to controller for counting the number of acc
input                        satd_blk_valid_i                       ; //from controller inform the last acc and clear the satd_4xn accumulator

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 
wire [`SATD_4x4_BITS-1:0] hd0_satd_4x4,hd1_satd_4x4                  ;
wire hd0_satd_4x4_v                                                  ;

// ********************************************
//                                             
//    Reg DECLARATION                         
//                                             
// ******************************************** 
reg [`SATD_BLK_BITS-2:0] hd0_satd_4xn;//17bit
reg [`SATD_BLK_BITS-2:0] hd1_satd_4xn;//17bit

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ******************************************** 
satd_gen_4x4 satd_gen0(
       .clk_i             ( clk_i          ),
       .rst_n_i           ( rst_n_i        ),       
       .valid_i           ( valid_i        ),
       //CMB pels
       .cmb_p0_i          ( cmb_p0_i       ),
       .cmb_p1_i          ( cmb_p1_i       ),
       .cmb_p2_i          ( cmb_p2_i       ),
       .cmb_p3_i          ( cmb_p3_i       ),                                          
       //subpels                          
       .sp0_i             ( ip0_sp0_i      ),
       .sp1_i             ( ip0_sp1_i      ),
       .sp2_i             ( ip0_sp2_i      ),
       .sp3_i             ( ip0_sp3_i      ),
       //
       .satd_4x4_o        ( hd0_satd_4x4   ),
       .satd_4x4_valid_o  ( hd0_satd_4x4_v )
);

satd_gen_4x4 satd_gen1(
       .clk_i             ( clk_i          ),
       .rst_n_i           ( rst_n_i        ),       
       .valid_i           ( valid_i        ),
       //CMB pels
       .cmb_p0_i          ( cmb_p4_i       ),
       .cmb_p1_i          ( cmb_p5_i       ),
       .cmb_p2_i          ( cmb_p6_i       ),
       .cmb_p3_i          ( cmb_p7_i       ),                                           
       //subpels                           
       .sp0_i             ( ip1_sp0_i      ),
       .sp1_i             ( ip1_sp1_i      ),
       .sp2_i             ( ip1_sp2_i      ),
       .sp3_i             ( ip1_sp3_i      ),
       //
       .satd_4x4_o        ( hd1_satd_4x4   ),
       .satd_4x4_valid_o  (                )
);

assign satd_4x4_valid_o = hd0_satd_4x4_v;


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
      hd0_satd_4xn <= 0;
      hd1_satd_4xn <= 0;
  end
  else if(satd_blk_valid_i) begin//clear in time
      hd0_satd_4xn <= 0;
      hd1_satd_4xn <= 0;
  end
  else if(hd0_satd_4x4_v) begin
      hd0_satd_4xn <= hd0_satd_4xn + hd0_satd_4x4;
      hd1_satd_4xn <= hd1_satd_4xn + hd1_satd_4x4;
  end
end
assign hd0_satd_4xn_o = hd0_satd_4xn;
assign hd1_satd_4xn_o = hd1_satd_4xn;

endmodule
