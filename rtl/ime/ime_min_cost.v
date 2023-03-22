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
// Filename       : ime_min_cost.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                calculate the SAD value of all other partitions inside one single MB
//                apart from 4x4 blocks
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_min_cost(
        clk,
        rstn,
        cost4x4_i,
        cost4x8_i,
        cost8x4_i,
        cost8x8_i,
        cost8x16_i,
        cost16x8_i,
        cost16x16_i,        
        mb_type_o,
        sub_mb_type_o
);

input   clk;
input   rstn;   

input   [`SAD4X4_NUM  *`COST4X4_LEN   -1:0]  cost4x4_i;
input   [`SAD4X8_NUM  *`COST4X8_LEN   -1:0]  cost4x8_i;
input   [`SAD8X4_NUM  *`COST8X4_LEN   -1:0]  cost8x4_i;
input   [`SAD8X8_NUM  *`COST8X8_LEN   -1:0]  cost8x8_i;
input   [`SAD8X16_NUM *`COST8X16_LEN  -1:0]  cost8x16_i;
input   [`SAD16X8_NUM *`COST16X8_LEN  -1:0]  cost16x8_i;
input   [`SAD16X16_NUM*`COST16X16_LEN -1:0]  cost16x16_i;

output  [`MB_TYPE_LEN-1                 :0]  mb_type_o;
output  [`SAD8X8_NUM*`SUB_MB_TYPE_LEN-1 :0]  sub_mb_type_o;


wire    [`SAD8X8_NUM   *`COST8X8_LEN  -1:0]  cost4x4_w;  //4x15
wire    [`SAD8X8_NUM   *`COST8X8_LEN  -1:0]  cost4x8_w;  //4x15
wire    [`SAD8X8_NUM   *`COST8X8_LEN  -1:0]  cost8x4_w;  //4x15 

reg     [`SAD8X8_NUM   *`COST8X8_LEN  -1:0]  cost8x8_min_w;
reg     [`SAD8X8_NUM   *`COST8X8_LEN  -1:0]  cost8x8_min_r;

wire    [`COST16X16_LEN  -1             :0]  cost8x8_w;   //17
wire    [`COST16X16_LEN  -1             :0]  cost8x16_w;
wire    [`COST16X16_LEN  -1             :0]  cost16x8_w;
wire    [`COST16X16_LEN  -1             :0]  cost16x16_w;

reg     [`SAD8X8_NUM*`SUB_MB_TYPE_LEN-1 :0]  sub_mb_type0_st, sub_mb_type1_st;  //4x3
reg     [`SAD8X8_NUM*`COST8X8_LEN-1     :0]  cost8x8_min0_st, cost8x8_min1_st;  //4x15
                                        
reg     [`SAD16X16_NUM*`COST16X16_LEN-1 :0]  cost16x16_min0_st, cost16x16_min1_st; //1x17
reg     [`MB_TYPE_LEN-1                 :0]  mb_type0_st, mb_type1_st;         //3

reg     [`MB_TYPE_LEN-1                 :0]  mb_type_w;              //3
reg     [`MB_TYPE_LEN-1                 :0]  mb_type_r;              //3

reg     [`SAD8X8_NUM*`SUB_MB_TYPE_LEN-1 :0]  sub_mb_type_w;         //4x3
reg     [`SAD8X8_NUM*`SUB_MB_TYPE_LEN-1 :0]  sub_mb_type_r;         //4x3 

//4x4 cost of each sub-part
assign cost4x4_w[1*`COST8X8_LEN-1: 0*`COST8X8_LEN] =   cost4x4_i[ 1*`COST4X4_LEN-1 : 0*`COST4X4_LEN] +
                                                       cost4x4_i[ 2*`COST4X4_LEN-1 : 1*`COST4X4_LEN] +
                                                       cost4x4_i[ 3*`COST4X4_LEN-1 : 2*`COST4X4_LEN] +
                                                       cost4x4_i[ 4*`COST4X4_LEN-1 : 3*`COST4X4_LEN] ;
assign cost4x4_w[2*`COST8X8_LEN-1: 1*`COST8X8_LEN] =   cost4x4_i[ 5*`COST4X4_LEN-1 : 4*`COST4X4_LEN] +
                                                       cost4x4_i[ 6*`COST4X4_LEN-1 : 5*`COST4X4_LEN] +
                                                       cost4x4_i[ 7*`COST4X4_LEN-1 : 6*`COST4X4_LEN] +
                                                       cost4x4_i[ 8*`COST4X4_LEN-1 : 7*`COST4X4_LEN] ;
assign cost4x4_w[3*`COST8X8_LEN-1: 2*`COST8X8_LEN] =   cost4x4_i[ 9*`COST4X4_LEN-1 : 8*`COST4X4_LEN] +
                                                       cost4x4_i[ 10*`COST4X4_LEN-1 : 9*`COST4X4_LEN] +
                                                       cost4x4_i[ 11*`COST4X4_LEN-1 : 10*`COST4X4_LEN] +
                                                       cost4x4_i[ 12*`COST4X4_LEN-1 : 11*`COST4X4_LEN] ;                                                        
assign cost4x4_w[4*`COST8X8_LEN-1: 3*`COST8X8_LEN] =   cost4x4_i[ 13*`COST4X4_LEN-1 : 12*`COST4X4_LEN] +
                                                       cost4x4_i[ 14*`COST4X4_LEN-1 : 13*`COST4X4_LEN] +
                                                       cost4x4_i[ 15*`COST4X4_LEN-1 : 14*`COST4X4_LEN] +
                                                       cost4x4_i[ 16*`COST4X4_LEN-1 : 15*`COST4X4_LEN] ;  


//4x8 cost of each sub-part
assign cost4x8_w[1*`COST8X8_LEN-1: 0*`COST8X8_LEN] =   cost4x8_i[ 1*`COST4X8_LEN-1 : 0*`COST4X8_LEN] +
                                                       cost4x8_i[ 2*`COST4X8_LEN-1 : 1*`COST4X8_LEN] ;
assign cost4x8_w[2*`COST8X8_LEN-1: 1*`COST8X8_LEN] =   cost4x8_i[ 3*`COST4X8_LEN-1 : 2*`COST4X8_LEN] +
                                                       cost4x8_i[ 4*`COST4X8_LEN-1 : 3*`COST4X8_LEN] ;
assign cost4x8_w[3*`COST8X8_LEN-1: 2*`COST8X8_LEN] =   cost4x8_i[ 5*`COST4X8_LEN-1 : 4*`COST4X8_LEN] +
                                                       cost4x8_i[ 6*`COST4X8_LEN-1 : 5*`COST4X8_LEN] ;
assign cost4x8_w[4*`COST8X8_LEN-1: 3*`COST8X8_LEN] =   cost4x8_i[ 7*`COST4X8_LEN-1 : 6*`COST4X8_LEN] +
                                                       cost4x8_i[ 8*`COST4X8_LEN-1 : 7*`COST4X8_LEN] ;

//8x4 cost of each sub-part
assign cost8x4_w[1*`COST8X8_LEN-1: 0*`COST8X8_LEN] =   cost8x4_i[ 1*`COST8X4_LEN-1 : 0*`COST8X4_LEN] +
                                                       cost8x4_i[ 2*`COST8X4_LEN-1 : 1*`COST8X4_LEN] ;
assign cost8x4_w[2*`COST8X8_LEN-1: 1*`COST8X8_LEN] =   cost8x4_i[ 3*`COST8X4_LEN-1 : 2*`COST8X4_LEN] +
                                                       cost8x4_i[ 4*`COST8X4_LEN-1 : 3*`COST8X4_LEN] ;
assign cost8x4_w[3*`COST8X8_LEN-1: 2*`COST8X8_LEN] =   cost8x4_i[ 5*`COST8X4_LEN-1 : 4*`COST8X4_LEN] +
                                                       cost8x4_i[ 6*`COST8X4_LEN-1 : 5*`COST8X4_LEN] ;
assign cost8x4_w[4*`COST8X8_LEN-1: 3*`COST8X8_LEN] =   cost8x4_i[ 7*`COST8X4_LEN-1 : 6*`COST8X4_LEN] +
                                                       cost8x4_i[ 8*`COST8X4_LEN-1 : 7*`COST8X4_LEN] ;

assign cost8x8_w  = cost8x8_min_r[ 1*`COST8X8_LEN-1 : 0*`COST8X8_LEN] +
                    cost8x8_min_r[ 2*`COST8X8_LEN-1 : 1*`COST8X8_LEN] +
                    cost8x8_min_r[ 3*`COST8X8_LEN-1 : 2*`COST8X8_LEN] +
                    cost8x8_min_r[ 4*`COST8X8_LEN-1 : 3*`COST8X8_LEN] ;


assign cost8x16_w = cost8x16_i[1*`COST8X16_LEN-1 : 0*`COST8X16_LEN] +
                    cost8x16_i[2*`COST8X16_LEN-1 : 1*`COST8X16_LEN] ;
                 

assign cost16x8_w = cost16x8_i[1*`COST16X8_LEN-1 : 0*`COST16X8_LEN] +
                    cost16x8_i[2*`COST16X8_LEN-1 : 1*`COST16X8_LEN] ;

assign cost16x16_w = cost16x16_i;
                       
//sub_block compare 
genvar i;

generate
   for(i=0; i<`SAD8X8_NUM;i=i+1)  //4
   begin: sub_block_cmp_n
     always @( * ) begin
       if( cost4x4_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN] < cost4x8_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]) begin
         cost8x8_min0_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost4x4_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
         sub_mb_type0_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = `SUBPART4X4;
       end
       else begin
         cost8x8_min0_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost4x8_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
         sub_mb_type0_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = `SUBPART4X8;
       end
     end   // compare the 4x4 and 4x8 who is minimun (min_1)
     
     always @( * ) begin
       if( cost8x4_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN] < cost8x8_i[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]) begin
         cost8x8_min1_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost8x4_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
         sub_mb_type1_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = `SUBPART8X4;
       end
       else begin
         cost8x8_min1_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost8x8_i[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
         sub_mb_type1_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = `SUBPART8X8;
       end
     end  //compare the 8x4 and 8x8 who is minimum  (min_2)
     
     always @( * ) begin
       if(cost8x8_min0_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN] < cost8x8_min1_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]) begin
         cost8x8_min_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost8x8_min0_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
         sub_mb_type_w[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = sub_mb_type0_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN];
       end
       else
         begin
           cost8x8_min_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN]         = cost8x8_min1_st[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN];
           sub_mb_type_w[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN] = sub_mb_type1_st[(i+1)*`SUB_MB_TYPE_LEN-1:i*`SUB_MB_TYPE_LEN];
         end
     end
   end  //compare the min_1 and the min_2 who is minimum 
endgenerate

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
      cost8x8_min_r <= 'b0;
      sub_mb_type_r <= 'b0;
    end    
    else begin
      cost8x8_min_r <=  cost8x8_min_w;
      sub_mb_type_r <=  sub_mb_type_w;
    end
end



//final mode decision for whole MB
always@( * )begin
    if ( (cost8x16_w <= cost8x8_w) )
    begin
      cost16x16_min0_st = cost8x16_w;
      mb_type0_st       = `PART8X16;
    end
    else begin
      cost16x16_min0_st = cost8x8_w;
      mb_type0_st       = `PART8X8;
    end
end
always @( * ) begin
  if( (cost16x16_w <= cost16x8_w) )
  begin
    cost16x16_min1_st = cost16x16_w; 
    mb_type1_st       = `PART16X16;
  end
  else begin
    cost16x16_min1_st = cost16x8_w;
    mb_type1_st       = `PART16X8;
  end
end

always @( * ) begin
  if( (cost16x16_min1_st <= cost16x16_min0_st) )
  begin
    mb_type_w       = mb_type1_st;
  end
  else begin
    mb_type_w       = mb_type0_st;
  end
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    mb_type_r <= `PART16X16;
  else
    mb_type_r <= mb_type_w;
end

assign mb_type_o     = mb_type_r;
assign sub_mb_type_o = sub_mb_type_r;
   
endmodule
