//----------------------------------------------------------------------------//
//                                                                            //
//  COPYRIGHT (C) 2011, VIPcore Group, Fudan University                       //
//                                                                            //
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE                //
//  EXPRESSED WRITTEN CONSENT OF VIPcore Group                                //
//                                                                            //
//  VIPcore                   http://10.133.20.18                             //
//  Fudan University          me.fudan.edu.cn                                 //
//----------------------------------------------------------------------------//
// Filename       : coding_style_datapath.v                                   //
// Author         : HuailuRen                                                //
// Email          : hlren.pub@gmail.com                                       //
// Created        : 16:07 2011/5/22                                        //
//----------------------------------------------------------------------------//
// Description    :                                                           //
//                                                                            //
// $Id$                                                                       //
//----------------------------------------------------------------------------//
`include "enc_defines.v"

module tq_div6_c( qp_i, div_o);
  input  [5:0] qp_i ;
  output [3:0] div_o;
  reg [3:0] div_o;
  always @(qp_i) begin
    case (qp_i)
       0, 1, 2, 3, 4, 5 : div_o = 4'b0000;
       6, 7, 8, 9,10,11 : div_o = 4'b0001;
      12,13,14,15,16,17 : div_o = 4'b0010;
      18,19,20,21,22,23 : div_o = 4'b0011;
      24,25,26,27,28,29,30 : div_o = 4'b0100;
      31,32,33,34,35,36,37,38,39 : div_o = 4'b0101;
      40,41,42,43,44,45,46,47,48,49,50,51 : div_o = 4'b0110;
      default           : div_o = 4'b0000;
    endcase
  end
endmodule