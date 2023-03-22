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
// Author         : Jialiang Liu
// Created        : 2011.5-2011.6
// Description    : 
//                  
//                  
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module mc_chroma_ip_2pel(
       clk_i,
       rst_n_i,
       
       end_oneblk_i,
       
       fracx_i,
       fracy_i,
       
       ref_valid_i,
       refuv_p0_i,
       refuv_p1_i,
       refuv_p2_i,
       
       fracuv_valid_o,
       fracuv_p0_o,
       fracuv_p1_o
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                   clk_i;
input                   rst_n_i;
input                   end_oneblk_i;
input  [2           :0] fracx_i;
input  [2           :0] fracy_i;
input                   ref_valid_i;
input  [`BIT_DEPTH-1:0] refuv_p0_i,refuv_p1_i,refuv_p2_i;
output                  fracuv_valid_o;
output [`BIT_DEPTH-1:0] fracuv_p0_o;
output [`BIT_DEPTH-1:0] fracuv_p1_o;


// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************
reg [`BIT_DEPTH-1   :0] refuv00, refuv01, refuv02;
reg [`BIT_DEPTH-1   :0] refuv10, refuv11, refuv12;
reg                     end_oneblk;
reg                     ref_valid;
reg [1              :0] counter;

wire                    in_valid  ;

// ********************************************
//                                             
//    Sequential Logic   Combinational Logic 
//                                             
// ********************************************
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    refuv00 <= 'b0;
    refuv01 <= 'b0;
    refuv02 <= 'b0;
    refuv10 <= 'b0;
    refuv11 <= 'b0;
    refuv12 <= 'b0;
  end
  else
    if(ref_valid_i) begin
      refuv10 <= refuv_p0_i;
      refuv11 <= refuv_p1_i;
      refuv12 <= refuv_p2_i;
      
      refuv00 <= refuv10;
      refuv01 <= refuv11;
      refuv02 <= refuv12;
    end
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_oneblk <= 1'b0;
  else
    end_oneblk <= end_oneblk_i;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    counter <= 2'b00;
  else
    if(end_oneblk)
      counter <= 2'b00;
    else
      if(ref_valid_i)
        if(counter == 2'b10)
          counter <= counter;
        else
          counter <= counter + 1'b1;
      else
        counter <= counter;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    ref_valid <= 'd0;
  else
    ref_valid <= ref_valid_i;
end
assign in_valid = (counter == 2'd2) & ref_valid;


mc_chroma_ip_1pel mc_uv_ip0_1pel(
    .clk_i         (  clk_i     ),
    .rst_n_i       (  rst_n_i   ),
    .fracx_i       ( fracx_i    ),
    .fracy_i       ( fracy_i    ),
    .ref_valid_i   ( in_valid   ),
    .A_i           ( refuv00    ),
    .B_i           ( refuv01    ),
    .C_i           ( refuv10    ),
    .D_i           ( refuv11    ),
    .fracuv_valid_o( fracuv_valid_o ),
    .fracuv_pel_o  ( fracuv_p0_o)
);

mc_chroma_ip_1pel mc_uv_ip1_1pel(
       .clk_i         (  clk_i   ),
       .rst_n_i       (  rst_n_i ),
       .fracx_i       ( fracx_i  ),
       .fracy_i       ( fracy_i  ),
       .ref_valid_i   ( in_valid ),
       .A_i           ( refuv01  ),
       .B_i           ( refuv02  ),
       .C_i           ( refuv11  ),
       .D_i           ( refuv12  ),
       .fracuv_valid_o(          ),
       .fracuv_pel_o  ( fracuv_p1_o)
);

endmodule



module mc_chroma_ip_1pel(
       clk_i,
       rst_n_i,
       
       fracx_i,
       fracy_i,
       
       ref_valid_i,
       A_i,
       B_i,
       C_i,
       D_i,
       
       fracuv_valid_o,
       fracuv_pel_o
);


// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                   clk_i;
input                   rst_n_i;
input                   ref_valid_i;
input  [`BIT_DEPTH-1:0] A_i,B_i,C_i,D_i;
input  [2           :0] fracx_i, fracy_i;
output                  fracuv_valid_o;
output [`BIT_DEPTH-1:0] fracuv_pel_o;



// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************
reg  [`BIT_DEPTH+3:0] E_r,F_r;
reg                   valid;
reg                   fracuv_valid_o;
reg  [`BIT_DEPTH+1:0] fracch_pel;



// ********************************************
//                                
//    Wire DECLARATION            
//                                      
// ********************************************
wire [`BIT_DEPTH+3:0] E_w,F_w;
wire [`BIT_DEPTH+6:0] G_w;
wire [`BIT_DEPTH+6:0] fracch_pel_tmp;


// ********************************************
//                                             
//    Sequential Logic   Combinational Logic 
//                                             
// ********************************************
cal_unit #(.INPUT_BITS(`BIT_DEPTH+1)) cu0(
       .in0  ({1'b0,A_i}),
       .in1  ({1'b0,B_i}),
       .frac (fracx_i),
       .out  (E_w)
);

cal_unit #(.INPUT_BITS(`BIT_DEPTH+1)) cu1(
       .in0  ({1'b0,C_i}),
       .in1  ({1'b0,D_i}),
       .frac (fracx_i),
       .out  (F_w)
);


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    E_r <= 'b0;
    F_r <= 'b0;
  end
  else
    if(ref_valid_i) begin
      E_r <= E_w;
      F_r <= F_w;
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    valid <= 'b0;
  else
    valid <= ref_valid_i;
end


cal_unit #(.INPUT_BITS(`BIT_DEPTH+4)) cu2(
       .in0  (E_r),
       .in1  (F_r),
       .frac (fracy_i),
       .out  (G_w)
);

assign fracch_pel_tmp = G_w + (6'd32);
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    fracch_pel <= 'b0;
  else
    if(valid)
      fracch_pel <=  fracch_pel_tmp[14:6]; // >> 6;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    fracuv_valid_o <= 'b0;
  else
    fracuv_valid_o <=  valid;
end

assign fracuv_pel_o = (fracch_pel[`BIT_DEPTH+1] == 1'b1)? 8'b0 :
                      (fracch_pel[`BIT_DEPTH]   == 1'b1)? 8'd255 : fracch_pel[`BIT_DEPTH-1:0];
					  
endmodule



module cal_unit(
       in0,
       in1,
       
       frac,
       
       out
);
parameter INPUT_BITS = `BIT_DEPTH+1;



input  signed [INPUT_BITS-1:0] in0,in1;
output signed [INPUT_BITS+2:0] out;
input  [2           :0] frac;



wire   signed [INPUT_BITS-1:0] sub;
wire   signed [INPUT_BITS+2:0] in0_mul_8;
wire   signed [INPUT_BITS  :0] sub_mul_2;
wire   signed [INPUT_BITS+1:0] sub_mul_4;
wire   signed [INPUT_BITS+2:0] sub_mul_8;
reg    signed [INPUT_BITS+2:0] sub_sel0, sub_sel1;
wire   signed [INPUT_BITS+2:0] factor;


assign sub = in1 - in0;
assign sub_mul_2 = sub<<1;
assign sub_mul_4 = sub<<2;
assign sub_mul_8 = sub<<3;
assign in0_mul_8 = in0<<3;

always @( * ) begin
  case(frac)
    3'd0: begin sub_sel0 = 0;          sub_sel1 = 0;        end
    3'd1: begin sub_sel0 = sub;        sub_sel1 = 0;        end
    3'd2: begin sub_sel0 = sub_mul_2;  sub_sel1 = 0;        end
    3'd3: begin sub_sel0 = sub_mul_2;  sub_sel1 = sub;      end
    3'd4: begin sub_sel0 = sub_mul_4;  sub_sel1 = 0;        end
    3'd5: begin sub_sel0 = sub_mul_4;  sub_sel1 = sub;      end
    3'd6: begin sub_sel0 = sub_mul_4;  sub_sel1 = sub_mul_2;end
    3'd7: begin sub_sel0 = sub_mul_8;  sub_sel1 = (~{{3{sub[INPUT_BITS-1]}},sub} + 1'b1); end
    default: begin sub_sel0 = 'b0; sub_sel1 = 'b0; end
  endcase
end

assign factor = sub_sel0 + sub_sel1;
assign out = in0_mul_8 + factor;

endmodule
