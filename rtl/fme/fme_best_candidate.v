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
// Filename       : best_candidate.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module best_candidate
#(parameter SATD_BITS = `BIT_DEPTH + 10)
(
        clk_i                    ,
        rst_n_i                  ,                         
        qp_i                     ,
                                 
        mv_x_i                   ,
        mv_y_i                   ,
        mvp_x_i                  ,
        mvp_y_i                  ,
                                 
        half_i                   ,                        
        satd_valid_i             ,
        satd0_i, satd1_i, satd2_i,
        satd3_i, satd4_i, satd5_i,
        satd6_i, satd7_i, satd8_i,
        
        bcost_o                  ,
        bcand_x_o                ,
        bcand_y_o                ,
        cost_valid_o
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************   
input clk_i                                     ;
input rst_n_i                                   ;                                    
input [5:0] qp_i                                ;
                                                
input signed [`FMVD_LEN-1 :0]  mv_x_i           ;
input signed [`FMVD_LEN-1 :0]  mv_y_i           ;
input signed [`FMVD_LEN-1 :0]  mvp_x_i          ;
input signed [`FMVD_LEN-1 :0]  mvp_y_i          ;
                                                
input                 half_i                    ;
input                 satd_valid_i              ;
input [SATD_BITS-1:0] satd0_i, satd1_i, satd2_i ;
input [SATD_BITS-1:0] satd3_i, satd4_i, satd5_i ;
input [SATD_BITS-1:0] satd6_i, satd7_i, satd8_i ;

output reg   [SATD_BITS  :0] bcost_o            ;
output reg   [1          :0] bcand_x_o,bcand_y_o;
output reg                   cost_valid_o       ;
// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
wire signed [`FMVD_LEN-1:0] mvd0_x, mvd1_x, mvd2_x          ;
wire signed [`FMVD_LEN-1:0] mvd0_y, mvd1_y, mvd2_y          ;
                                                            
wire signed [`FMVD_LEN-1:0] mvd0_x_w, mvd1_x_w, mvd2_x_w    ;
wire signed [`FMVD_LEN-1:0] mvd0_y_w, mvd1_y_w, mvd2_y_w    ;

wire signed [`FMVD_LEN-1:0] mv0_x_w, mv1_x_w, mv2_x_w       ;
wire signed [`FMVD_LEN-1:0] mv0_y_w, mv1_y_w, mv2_y_w       ;
wire [`FMVD_LEN :        0] codenum_mvd0_x_plus1, codenum_mvd1_x_plus1, codenum_mvd2_x_plus1;
wire [`FMVD_LEN :        0] codenum_mvd0_y_plus1, codenum_mvd1_y_plus1, codenum_mvd2_y_plus1;   
wire [6                 :0] lambda                                      ;                         

wire [`MV_CODE_BITS-1   :0] bitsnum_mvd0_x,bitsnum_mvd1_x,bitsnum_mvd2_x;
wire [`MV_CODE_BITS-1   :0] bitsnum_mvd0_y,bitsnum_mvd1_y,bitsnum_mvd2_y;

wire [SATD_BITS:0] best_cost0_1s, best_cost1_1s, best_cost2_1s, best_cost3_1s;
wire [SATD_BITS:0] best_cost0_2s, best_cost1_2s                      ;
wire [SATD_BITS:0] best_cost0_3s                                     ;
wire [SATD_BITS:0] best_cost_4s                                      ;

wire [1        :0] bcand0_x_1s, bcand1_x_1s, bcand2_x_1s, bcand3_x_1s;
wire [1        :0] bcand0_y_1s, bcand1_y_1s, bcand2_y_1s, bcand3_y_1s;
wire [1        :0] bcand0_x_2s, bcand1_x_2s                          ;
wire [1        :0] bcand0_y_2s, bcand1_y_2s                          ;
wire [1        :0] bcand0_x_3s                                       ;
wire [1        :0] bcand0_y_3s                                       ;
wire [1        :0] bcand_x_4s                                        ;
wire [1        :0] bcand_y_4s                                        ;
// ********************************************
//                                             
//    Reg  DECLARATION                         
//                                             
// ********************************************

reg [`MV_CODE_BITS    :0] bitsnum_mvd00,bitsnum_mvd01, bitsnum_mvd02;
reg [`MV_CODE_BITS    :0] bitsnum_mvd10,bitsnum_mvd11, bitsnum_mvd12;
reg [`MV_CODE_BITS    :0] bitsnum_mvd20,bitsnum_mvd21, bitsnum_mvd22;
reg [`MV_CODE_BITS + 7:0] cost_mv00, cost_mv01, cost_mv02           ;
reg [`MV_CODE_BITS + 7:0] cost_mv10, cost_mv11, cost_mv12           ;
reg [`MV_CODE_BITS + 7:0] cost_mv20, cost_mv21, cost_mv22           ;
reg                                  cost_valid                     ;
reg [SATD_BITS       :0] cost00, cost01, cost02                     ;
reg [SATD_BITS       :0] cost10, cost11, cost12                     ;
reg [SATD_BITS       :0] cost20, cost21, cost22                     ;

reg                      satd_v                                     ;
reg [SATD_BITS-1     :0] satd0, satd1, satd2                        ;
reg [SATD_BITS-1     :0] satd3, satd4, satd5                        ;
reg [SATD_BITS-1     :0] satd6, satd7, satd8                        ;
// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    satd0 <= 0; satd1 <= 0; satd2 <= 0;
    satd3 <= 0; satd4 <= 0; satd5 <= 0;
    satd6 <= 0; satd7 <= 0; satd8 <= 0;
  end
  else if(satd_valid_i) begin
    satd0  <= satd0_i;
    satd1  <= satd1_i;
    satd2  <= satd2_i;
    satd3  <= satd3_i;
    satd4  <= satd4_i;
    satd5  <= satd5_i;
    satd6  <= satd6_i;
    satd7  <= satd7_i;
    satd8  <= satd8_i;
  end
end
always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    satd_v <= 1'b0;
  else
    satd_v <= satd_valid_i;
end
  
lambda_tab lambda_tab(.qp_i(qp_i),.lambda_o(lambda));
 
assign mv0_x_w = (half_i)?(mv_x_i - 2'd2):(mv_x_i - 2'd1);
assign mv1_x_w = (half_i)?(mv_x_i       ):(mv_x_i       );
assign mv2_x_w = (half_i)?(mv_x_i + 2'd2):(mv_x_i + 2'd1);
assign mv0_y_w = (half_i)?(mv_y_i - 2'd2):(mv_y_i - 2'd1);
assign mv1_y_w = (half_i)?(mv_y_i       ):(mv_y_i       );
assign mv2_y_w = (half_i)?(mv_y_i + 2'd2):(mv_y_i + 2'd1); 

assign mvd0_x_w = mv0_x_w - mvp_x_i;
assign mvd1_x_w = mv1_x_w - mvp_x_i;
assign mvd2_x_w = mv2_x_w - mvp_x_i;
assign mvd0_y_w = mv0_y_w - mvp_y_i;
assign mvd1_y_w = mv1_y_w - mvp_y_i;
assign mvd2_y_w = mv2_y_w - mvp_y_i;


assign mvd0_x   = mvd0_x_w[`FMVD_LEN-1:0];//Only
assign mvd1_x   = mvd1_x_w[`FMVD_LEN-1:0];
assign mvd2_x   = mvd2_x_w[`FMVD_LEN-1:0];
assign mvd0_y   = mvd0_y_w[`FMVD_LEN-1:0];
assign mvd1_y   = mvd1_y_w[`FMVD_LEN-1:0];
assign mvd2_y   = mvd2_y_w[`FMVD_LEN-1:0];


assign codenum_mvd0_x_plus1 = (mvd0_x[`FMVD_LEN-1])?({1'b0,~mvd0_x[`FMVD_LEN-2:0],1'b0} + 9'd3)://???1
                                  ((|mvd0_x[`FMVD_LEN-2:0])?({1'b0, mvd0_x[`FMVD_LEN-2:0],1'b0}):9'd1);
assign codenum_mvd1_x_plus1 = (mvd1_x[`FMVD_LEN-1])?({1'b0,~mvd1_x[`FMVD_LEN-2:0],1'b0} + 9'd3):
                              ((|mvd1_x[`FMVD_LEN-2:0])?({1'b0, mvd1_x[`FMVD_LEN-2:0],1'b0}):9'd1);
assign codenum_mvd2_x_plus1 = (mvd2_x[`FMVD_LEN-1])?({1'b0,~mvd2_x[`FMVD_LEN-2:0],1'b0} + 9'd3):
                              ((|mvd2_x[`FMVD_LEN-2:0])?({1'b0, mvd2_x[`FMVD_LEN-2:0],1'b0}):9'd1);                                                   
assign codenum_mvd0_y_plus1 = (mvd0_y[`FMVD_LEN-1])?({1'b0,~mvd0_y[`FMVD_LEN-2:0],1'b0} + 9'd3):
                              ((|mvd0_y[`FMVD_LEN-2:0])?({1'b0, mvd0_y[`FMVD_LEN-2:0],1'b0}):9'd1);
assign codenum_mvd1_y_plus1 = (mvd1_y[`FMVD_LEN-1])?({1'b0,~mvd1_y[`FMVD_LEN-2:0],1'b0} + 9'd3):
                              ((|mvd1_y[`FMVD_LEN-2:0])?({1'b0, mvd1_y[`FMVD_LEN-2:0],1'b0}):9'd1);
assign codenum_mvd2_y_plus1 = (mvd2_y[`FMVD_LEN-1])?({1'b0,~mvd2_y[`FMVD_LEN-2:0],1'b0} + 9'd3):
                              ((|mvd2_y[`FMVD_LEN-2:0])?({1'b0, mvd2_y[`FMVD_LEN-2:0],1'b0}):9'd1);

bits_num bn_x0(.codenum_i(codenum_mvd0_x_plus1),.bitsnum_o(bitsnum_mvd0_x));
bits_num bn_x1(.codenum_i(codenum_mvd1_x_plus1),.bitsnum_o(bitsnum_mvd1_x));
bits_num bn_x2(.codenum_i(codenum_mvd2_x_plus1),.bitsnum_o(bitsnum_mvd2_x));
bits_num bn_y0(.codenum_i(codenum_mvd0_y_plus1),.bitsnum_o(bitsnum_mvd0_y));
bits_num bn_y1(.codenum_i(codenum_mvd1_y_plus1),.bitsnum_o(bitsnum_mvd1_y));
bits_num bn_y2(.codenum_i(codenum_mvd2_y_plus1),.bitsnum_o(bitsnum_mvd2_y));

//²åÈëÒ»²ã¼Ä´æÆ÷
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    bitsnum_mvd00 <= 0;
    bitsnum_mvd01 <= 0;
    bitsnum_mvd02 <= 0;
    bitsnum_mvd10 <= 0;
    bitsnum_mvd11 <= 0;
    bitsnum_mvd12 <= 0;
    bitsnum_mvd20 <= 0;
    bitsnum_mvd21 <= 0;
    bitsnum_mvd22 <= 0;
  end
  else begin
    bitsnum_mvd00 <= bitsnum_mvd0_x + bitsnum_mvd0_y;
    bitsnum_mvd01 <= bitsnum_mvd1_x + bitsnum_mvd0_y;
    bitsnum_mvd02 <= bitsnum_mvd2_x + bitsnum_mvd0_y;
    bitsnum_mvd10 <= bitsnum_mvd0_x + bitsnum_mvd1_y;
    bitsnum_mvd11 <= bitsnum_mvd1_x + bitsnum_mvd1_y;
    bitsnum_mvd12 <= bitsnum_mvd2_x + bitsnum_mvd1_y;
    bitsnum_mvd20 <= bitsnum_mvd0_x + bitsnum_mvd2_y;
    bitsnum_mvd21 <= bitsnum_mvd1_x + bitsnum_mvd2_y;
    bitsnum_mvd22 <= bitsnum_mvd2_x + bitsnum_mvd2_y;
  end
end


always @( * ) begin
   cost_mv00 = lambda * bitsnum_mvd00;
   cost_mv01 = lambda * bitsnum_mvd01;
   cost_mv02 = lambda * bitsnum_mvd02;
   
   cost_mv10 = lambda * bitsnum_mvd10;
   cost_mv11 = lambda * bitsnum_mvd11;
   cost_mv12 = lambda * bitsnum_mvd12;
   
   cost_mv20 = lambda * bitsnum_mvd20;
   cost_mv21 = lambda * bitsnum_mvd21;
   cost_mv22 = lambda * bitsnum_mvd22;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    cost00 <= 0; cost01 <= 0; cost02 <= 0;
    cost10 <= 0; cost11 <= 0; cost12 <= 0;
    cost20 <= 0; cost21 <= 0; cost22 <= 0;
  end
  else if(satd_v) begin
    cost00 <= satd0 + cost_mv00;
    cost01 <= satd1 + cost_mv01;
    cost02 <= satd2 + cost_mv02;
    
    cost10 <= satd3 + cost_mv10;
    cost11 <= satd4 + cost_mv11;
    cost12 <= satd5 + cost_mv12;
    
    cost20 <= satd6 + cost_mv20;
    cost21 <= satd7 + cost_mv21;
    cost22 <= satd8 + cost_mv22;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    cost_valid <= 1'b0;
  else
    cost_valid <= satd_v;
end

assign {bcand0_y_1s,bcand0_x_1s,best_cost0_1s} = (cost00 < cost01)? {2'b11,2'b11,cost00}:{2'b11,2'b00,cost01};
assign {bcand1_y_1s,bcand1_x_1s,best_cost1_1s} = (cost02 < cost12)? {2'b11,2'b01,cost02}:{2'b00,2'b01,cost12};
assign {bcand2_y_1s,bcand2_x_1s,best_cost2_1s} = (cost10 < cost11)? {2'b00,2'b11,cost10}:{2'b00,2'b00,cost11};
assign {bcand3_y_1s,bcand3_x_1s,best_cost3_1s} = (cost20 < cost21)? {2'b01,2'b11,cost20}:{2'b01,2'b00,cost21};

assign {bcand0_y_2s,bcand0_x_2s,best_cost0_2s} = (best_cost0_1s < best_cost2_1s)? 
                                                 {bcand0_y_1s,bcand0_x_1s,best_cost0_1s}:{bcand2_y_1s,bcand2_x_1s,best_cost2_1s};
assign {bcand1_y_2s,bcand1_x_2s,best_cost1_2s} = (best_cost1_1s < best_cost3_1s)? 
                                                 {bcand1_y_1s,bcand1_x_1s,best_cost1_1s}:{bcand3_y_1s,bcand3_x_1s,best_cost3_1s};

assign {bcand0_y_3s,bcand0_x_3s,best_cost0_3s} = (best_cost1_2s < best_cost0_2s)? 
                          {bcand1_y_2s,bcand1_x_2s,best_cost1_2s}:{bcand0_y_2s,bcand0_x_2s,best_cost0_2s};

assign {bcand_y_4s,bcand_x_4s,best_cost_4s} = (cost22 < best_cost0_3s)? {2'b01,2'b01,cost22}:{bcand0_y_3s,bcand0_x_3s,best_cost0_3s};

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    bcand_x_o <= 'd0;
    bcand_y_o <= 'd0;
  end
  else if(cost_valid) begin
    bcand_x_o <= bcand_x_4s;
    bcand_y_o <= bcand_y_4s;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    bcost_o <= 'd0;
  end
  else
    if( cost_valid ) begin
      bcost_o <= best_cost_4s;
    end
end

always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i) begin
    cost_valid_o <= 'd0;
  end
  else
    cost_valid_o <= cost_valid;
end

endmodule

`define CODENUM_BITS 9 //`FMVD_LEN+1
module bits_num(
       codenum_i,
       bitsnum_o
);
input  [`FMVD_LEN      :0] codenum_i;
output [`MV_CODE_BITS-1:0] bitsnum_o;

reg [`MV_CODE_BITS-1:0] bitsnum_o;
always @(codenum_i)
  casex(codenum_i)
    `CODENUM_BITS'b0_0000_0001: bitsnum_o = 1;
    `CODENUM_BITS'b0_0000_001x: bitsnum_o = 3;
    `CODENUM_BITS'b0_0000_01xx: bitsnum_o = 5;
    `CODENUM_BITS'b0_0000_1xxx: bitsnum_o = 7;
    `CODENUM_BITS'b0_0001_xxxx: bitsnum_o = 9;
    `CODENUM_BITS'b0_001x_xxxx: bitsnum_o = 11;
    `CODENUM_BITS'b0_01xx_xxxx: bitsnum_o = 13;
    `CODENUM_BITS'b0_1xxx_xxxx: bitsnum_o = 15;
    `CODENUM_BITS'b1_xxxx_xxxx: bitsnum_o = 17;
    default:                    bitsnum_o = 0;
  endcase
endmodule

module lambda_tab(
    qp_i,
    lambda_o
);
input  [5:0] qp_i;
output [6:0] lambda_o;
reg    [6:0] lambda_o;
    
always @(qp_i)
  case(qp_i)
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15: 
      lambda_o = 1;
    16,17,18,19:
      lambda_o = 2;
    20,21,22:
      lambda_o = 3;
    23,24,25:
      lambda_o = 4;
    26:
      lambda_o = 5;
    27,28:
      lambda_o = 6;
    29:
      lambda_o = 7;
    30:
      lambda_o = 8;
    31:
      lambda_o = 9;
    32:
      lambda_o = 10;
    33:
      lambda_o = 11;
    34:
      lambda_o = 13;
    35:
      lambda_o = 14;
    36:
      lambda_o = 16;
    37:
      lambda_o = 18;
    38:
      lambda_o = 20;
    39:
      lambda_o = 23;
    40:
      lambda_o = 25;
    41:
      lambda_o = 29;
    42:
      lambda_o = 32;
    43:
      lambda_o = 36;
    44:
      lambda_o = 40;
    45:
      lambda_o = 45;
    46:
      lambda_o = 51;
    47:
      lambda_o = 57;
    48:
      lambda_o = 64;
    49:
      lambda_o = 72;
    50:
      lambda_o = 81;
    51:
      lambda_o = 91;
    default:
      lambda_o = 0;
  endcase
endmodule
        
