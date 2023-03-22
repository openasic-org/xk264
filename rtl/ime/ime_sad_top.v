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
// Filename       : ime_sad_top.v
// Author         : Shen Sha
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module ime_sad_top(
    				clk,
    				rstn,    
    				end_ld_i,         
    				end_ime_o,         
    				mvd_i,               
    				data_v_i,
    				cmb_i,         
    				ref_i,         
    				lambda_i,    
    				mb_type_o,
    				sub_mb_type_o,
    				mvd_o
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input  clk;
input  rstn;
//systolic_array_IF 
input                                     end_ld_i;   //end_onesw_ime;  end of load reference pixels   
input   [2*`IMVD_LEN-1          :0]       mvd_i;      //motion_ime; the mv shift of the current reference pixels 
input                                     data_v_i;   //data valid 
input   [`REF_SIZE* `BIT_DEPTH -1:0]      ref_i;      //part of search window ;total of systolic array data ; 16*(16+3)*8
output                                    end_ime_o;  //end of ime  

input   [`MB_SIZE * `BIT_DEPTH -1:0]      cmb_i;      //current MB
input   [8:0]                             lambda_i;                          
output  [`MB_TYPE_LEN-1          :0]      mb_type_o;  //3 
output  [`SAD8X8_NUM*`SUB_MB_TYPE_LEN-1:0]sub_mb_type_o;  // 4x3 
output  [`SAD4X4_NUM*2*`IMVD_LEN-1:0]     mvd_o;      //best MV for current MB  16x2x6

// ********************************************
//                                             
//    Signal DECLARATION                        
//                                             
// ********************************************
reg     [`SAD4X4_NUM*2*`IMVD_LEN-1:0]     mvd_o_r;
genvar i;
genvar j;

//=====================================================================================================
//stage 1: sad4x4, 
reg                                          data_v_d;

wire    [`PE_NUM*`IMVD_LEN-1              :0] mvd_x_tmp; //4x6 
wire    [`PE_NUM*`SAD4X4_NUM*`SAD4X4_LEN-1:0] sad4x4_w;  //4x16x13
reg                                           sad4x4_v;
wire    [`PE_NUM*`MV_COST_BITS-1          :0] mv_cost_w1; //4x12 
reg     [`PE_NUM*`MV_COST_BITS-1          :0] mv_cost_r1; //4x12 

wire    [`IMVD_LEN-1                      :0] mvd_x;  // 6 
wire    [`IMVD_LEN-1                      :0] mvd_y;

reg     [`IMVD_LEN-1                      :0] mvd_x_d;
reg     [`IMVD_LEN-1                      :0] mvd_y_d;
reg     [`IMVD_LEN-1                      :0] mvd_x_r1;
reg     [`IMVD_LEN-1                      :0] mvd_y_r1;

reg                                           end_ld_d0, end_ld_d1;

assign mvd_x = mvd_i[1*`IMVD_LEN-1:0];
assign mvd_y = mvd_i[2*`IMVD_LEN-1:1*`IMVD_LEN];

reg     [`PE_NUM*`MB_SIZE*`BIT_DEPTH-1:0] ref_temp;  //4x256x8 

generate 
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : ime_sad4x4_n
        for(j = 0; j< `MB_WIDTH; j = j+ 1 ) begin : j_n
          always @(*) begin
            ref_temp[((i*`MB_SIZE) + (j + 1)*`MB_WIDTH)*`BIT_DEPTH-1:((i*`MB_SIZE) + j*`MB_WIDTH)*`BIT_DEPTH] = 
              ref_i[(j*`REF_WIDTH + i + `MB_WIDTH)*`BIT_DEPTH-1:(j*`REF_WIDTH + i)*`BIT_DEPTH];  //16+4-1       // ??? +i??
          end
        end
        
        ime_sad4x4 ime_sad4x4(
             .clk        (clk),
             .rstn       (rstn),             
             .enable_i   (data_v_i),        
             .cmb_i      (cmb_i),             
             //veritically inputs:ref_i[`MB_WIDTH*`BIT_DEPTH-1:0] is the first column.
             .ref_i      (ref_temp[(i+1)*`MB_SIZE*`BIT_DEPTH-1 : i*`MB_SIZE*`BIT_DEPTH]),             
             .sad4x4_o   (sad4x4_w[(i+1)*`SAD4X4_NUM*`SAD4X4_LEN -1: i*`SAD4X4_NUM*`SAD4X4_LEN])
        );
    end
endgenerate
  

//mv cost generate
generate
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : ime_mv_cost_n
       assign mvd_x_tmp[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN] = mvd_x + i;
       ime_mv_cost ime_mv_cost(
           .clk       (clk),
           .rstn      (rstn),           
           .mvd_x_i   (mvd_x_tmp[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
           .mvd_y_i   (mvd_y),           
           .lambda_i  (lambda_i),           
           .mv_cost_o (mv_cost_w1[(i+1)*`MV_COST_BITS-1:i*`MV_COST_BITS])
       );
    end
endgenerate

always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    data_v_d <= 1'b0;
    sad4x4_v <= 1'b0;
  end
  else begin
    data_v_d <= data_v_i;
    sad4x4_v <= data_v_d;
  end
end

always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    mvd_x_d  <= 0;
    mvd_y_d  <= 0;
    mvd_x_r1 <= 0;
    mvd_y_r1 <= 0;
  end
  else begin
    mvd_x_d  <= mvd_x;
    mvd_y_d  <= mvd_y;
    mvd_x_r1 <= mvd_x_d;
    mvd_y_r1 <= mvd_y_d;
  end
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    mv_cost_r1 <= 0;
  else
    mv_cost_r1 <= mv_cost_w1;
end

always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    end_ld_d0 <= 0;
    end_ld_d1 <= 0;
  end
  else begin
    end_ld_d0 <= end_ld_i;
    end_ld_d1 <= end_ld_d0;
  end
end

// end of stage 1
//=====================================================================================================


//=====================================================================================================
// stage 2: calculate SAD of 8x8 and 8x4 and 4x8 based on sad4x4
//          get the cost of 4x4 blocks
// reg for stage 2
wire  [`PE_NUM*`SAD4X4_NUM*`COST4X4_LEN-1 :0]             cost4x4_w;  //4x16x(8+4+1)
wire                                                      cost4x4_v;  
reg   [`PE_NUM*`MV_COST_BITS-1:0]                         mv_cost_r2; //4x16x12
reg                                                       sadx8_v;
wire  [`PE_NUM*`SAD4X8_NUM*`SAD4X8_LEN-1:0]               sad4x8_w;   //4x8x14
wire  [`PE_NUM*`SAD8X4_NUM*`SAD8X4_LEN-1:0]               sad8x4_w;   //4x8x14
wire  [`PE_NUM*`SAD8X8_NUM*`SAD8X8_LEN-1:0]               sad8x8_w;   //4x4x15
        
reg   [`IMVD_LEN-1                      :0]               mvd_x_r2;   //6
reg   [`IMVD_LEN-1                      :0]               mvd_y_r2;

reg                                                       end_ld_d2;

//calcaltion the sads of the 4x8, 8x4 and 8x8 partition
generate 
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : ime_sad_x8_n
    ime_sad_x8 ime_sad_x8(
        .clk       (clk),
        .rstn      (rstn),                
        .sad4x4_v_i(sad4x4_v),
        .sad4x4_i  (sad4x4_w  [(i+1)*`SAD4X4_NUM*`SAD4X4_LEN-1 : i*`SAD4X4_NUM*`SAD4X4_LEN]),                                                               
        .sad4x8_o  (sad4x8_w  [(i+1)*`SAD4X8_NUM*`SAD4X8_LEN-1 : i*`SAD4X8_NUM*`SAD4X8_LEN]),
        .sad8x4_o  (sad8x4_w  [(i+1)*`SAD8X4_NUM*`SAD8X4_LEN-1 : i*`SAD8X4_NUM*`SAD8X4_LEN]),
        .sad8x8_o  (sad8x8_w  [(i+1)*`SAD8X8_NUM*`SAD8X8_LEN-1 : i*`SAD8X8_NUM*`SAD8X8_LEN])
    );
    end
endgenerate

//get the cost of 4x4block
generate
    for(i=0; i<`PE_NUM; i=i+1) begin: ime_cost4x4_n
      ime_cost4x4 ime_cost4x4(
        .clk       (clk),
        .rstn      (rstn),        
        .mv_cost_i (mv_cost_r1[(i+1)*`MV_COST_BITS-1:i*`MV_COST_BITS]),        
        .sad4x4_v_i(sad4x4_v),
        .sad4x4_i  (sad4x4_w[(i+1)*`SAD4X4_NUM*`SAD4X4_LEN-1: i*`SAD4X4_NUM*`SAD4X4_LEN]),        
        .cost4x4_o (cost4x4_w[(i+1)*`SAD4X4_NUM*`COST4X4_LEN-1: i*`SAD4X4_NUM*`COST4X4_LEN])
      );
    end
endgenerate

//reg buffer for stage 2
always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
      mv_cost_r2 <= 0;
    end    
    else if(sad4x4_v) begin
      mv_cost_r2 <= mv_cost_r1;
    end
end
always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    mvd_x_r2 <= 0;
    mvd_y_r2 <= 0;
  end
  else begin
    mvd_x_r2 <= mvd_x_r1;
    mvd_y_r2 <= mvd_y_r1;
  end
end

always @(posedge clk or negedge rstn)
begin
    if(!rstn)
      sadx8_v <= 1'b0;
    else
      sadx8_v <= sad4x4_v;
end
assign cost4x4_v = sadx8_v;

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    end_ld_d2 <= 0;
  else
    end_ld_d2 <= end_ld_d1;
end

// end of stage 2
//=====================================================================================================


//=====================================================================================================
//stage 3: calculation the sad of 16x8 and 8x16 and 16x16 partitions.
//         get the cost of the 8x8, 8x4 and 4x8 partitions
wire  [`PE_NUM*`SAD4X8_NUM*`COST4X8_LEN-1   :0]cost4x8_w;  //4x8x14
wire  [`PE_NUM*`SAD8X4_NUM*`COST8X4_LEN-1   :0]cost8x4_w;
wire  [`PE_NUM*`SAD8X8_NUM*`COST8X8_LEN-1   :0]cost8x8_w;  //4x4x15
wire                                           costx8_v;

wire  [`PE_NUM*`SAD16X8_NUM*`SAD16X8_LEN-1  :0]sad16x8_w;
wire  [`PE_NUM*`SAD8X16_NUM*`SAD8X16_LEN-1  :0]sad8x16_w;
wire  [`PE_NUM*`SAD16X16_NUM*`SAD16X16_LEN-1:0]sad16x16_w;

reg   [`PE_NUM*`MV_COST_BITS-1              :0]mv_cost_r3;
reg                                            sadx16_v;
reg   [`IMVD_LEN-1                          :0]mvd_x_r3;
reg   [`IMVD_LEN-1                          :0]mvd_y_r3;

reg   [`PE_NUM*`SAD4X4_NUM*`COST4X4_LEN  -1 :0]cost4x4_part;
wire  [`SAD4X4_NUM*`COST4X4_LEN          -1 :0]mcost4x4_w;
wire  [`SAD4X4_NUM*`IMVD_LEN             -1 :0]mvd_x_4x4_w;
wire  [`SAD4X4_NUM*`IMVD_LEN             -1 :0]mvd_y_4x4_w;

reg                                            end_ld_d3;

//calculate the sads of the 
generate 
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : ime_sad_x16_n
    ime_sad_x16 ime_sad_x16(
        .clk       (clk),
        .rstn      (rstn),                
        .sadx8_v_i (sadx8_v),
        .sad8x8_i  (sad8x8_w  [(i+1)*`SAD8X8_NUM*`SAD8X8_LEN-1 : i*`SAD8X8_NUM*`SAD8X8_LEN]),        
        .sad8x16_o (sad8x16_w  [(i+1)*`SAD8X16_NUM*`SAD8X16_LEN-1  : i*`SAD8X16_NUM*`SAD8X16_LEN]),
        .sad16x8_o (sad16x8_w  [(i+1)*`SAD16X8_NUM*`SAD16X8_LEN-1  : i*`SAD16X8_NUM*`SAD16X8_LEN]),
        .sad16x16_o(sad16x16_w [(i+1)*`SAD16X16_NUM*`SAD16X16_LEN-1: i*`SAD16X16_NUM*`SAD16X16_LEN])
    );
    end
endgenerate

//get the cost of 8x8 ,4x8 and 8x4 partitions
generate
    for(i=0; i<`PE_NUM; i=i+1) begin: ime_costx8_n
      ime_costx8 ime_costx8(
        .clk       (clk),
        .rstn      (rstn),        
        .mv_cost_i (mv_cost_r2[(i+1)*`MV_COST_BITS-1:i*`MV_COST_BITS]),        
        .sadx8_v_i (sadx8_v),        
        .sad4x8_i  (sad4x8_w[(i+1)*`SAD4X8_NUM*`SAD4X8_LEN-1: i*`SAD4X8_NUM*`SAD4X8_LEN]),
        .sad8x4_i  (sad8x4_w[(i+1)*`SAD8X4_NUM*`SAD8X4_LEN-1: i*`SAD8X4_NUM*`SAD8X4_LEN]),
        .sad8x8_i  (sad8x8_w[(i+1)*`SAD8X8_NUM*`SAD8X8_LEN-1: i*`SAD8X8_NUM*`SAD8X8_LEN]),        
        .cost4x8_o (cost4x8_w[(i+1)*`SAD4X8_NUM*`COST4X8_LEN-1: i*`SAD4X8_NUM*`COST4X8_LEN]),
        .cost8x4_o (cost8x4_w[(i+1)*`SAD8X4_NUM*`COST8X4_LEN-1: i*`SAD8X4_NUM*`COST8X4_LEN]),
        .cost8x8_o (cost8x8_w[(i+1)*`SAD8X8_NUM*`COST8X8_LEN-1: i*`SAD8X8_NUM*`COST8X8_LEN])
      );
    end
endgenerate

//select the minimum cost of 4x4 blocks among the PEs
generate
    for(i=0; i<`PE_NUM; i=i+1) begin : pe_num_4x4_n   //4
       for(j=0; j<`SAD4X4_NUM; j=j+1)begin : sad_num_4x4_n   //16
          always@(*)begin
             cost4x4_part[(j*`PE_NUM+i+1)*`COST4X4_LEN-1:(j*`PE_NUM+i)*`COST4X4_LEN]
             = cost4x4_w[(i*`SAD4X4_NUM + j+1)*`SAD4X4_LEN-1:(i*`SAD4X4_NUM + j)*`COST4X4_LEN]; //COST4X4_LEN = 13
          end
       end
    end

    for(i=0; i<`SAD4X4_NUM;i=i+1) begin: ime_mux4x4_n //16 
        ime_mux #(.COST_LEN(`COST4X4_LEN)) ime_mux4x4(   
          .clk      (clk),
          .rstn     (rstn),        
          .rst_mux_i(end_ime_o),        
          .cost_v_i (cost4x4_v),
          .cost_i   (cost4x4_part[(i+1)*`PE_NUM*`COST4X4_LEN-1:i*`PE_NUM*`COST4X4_LEN]),
          .mvd_x_i  (mvd_x_r2),
          .mvd_y_i  (mvd_y_r2),          
          .mvd_x_o  (mvd_x_4x4_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
          .mvd_y_o  (mvd_y_4x4_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
          .cost_o   (mcost4x4_w[(i+1)*`COST4X4_LEN-1:i*`COST4X4_LEN])   //16x13
        );
    end
endgenerate

//reg buffer for stage 3
always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
      mv_cost_r3  <= 'b0;
    end    
    else begin
      mv_cost_r3  <= mv_cost_r2;
    end
end
always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    mvd_x_r3 <= 0;
    mvd_y_r3 <= 0;
  end
  else begin
    mvd_x_r3 <= mvd_x_r2;
    mvd_y_r3 <= mvd_y_r2;
  end
end

always @(posedge clk or negedge rstn)
begin
  if(!rstn)
    sadx16_v <= 1'b0;
  else
    sadx16_v <= sadx8_v;
end

assign costx8_v = sadx16_v;

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    end_ld_d3 <= 1'b0;
  else
    end_ld_d3 <= end_ld_d2;
end

// end of stage 3
//=====================================================================================================


//=====================================================================================================
//stage 4: get the cost of 16x16, 8x16 and 16x8 partitions
//compare with the previous costs of 8x8, 8x4 and 4x8 blocks

wire  [`PE_NUM*`SAD8X16_NUM*`COST8X16_LEN-1:0]    cost8x16_w;
wire  [`PE_NUM*`SAD16X8_NUM*`COST8X16_LEN-1:0]    cost16x8_w;
wire  [`PE_NUM*`SAD16X16_NUM*`COST16X16_LEN-1:0]  cost16x16_w;
reg                                               costx16_v;

reg   [`PE_NUM*`SAD4X8_NUM*`COST4X8_LEN-1   :0]   cost4x8_part;
reg   [`PE_NUM*`SAD8X4_NUM*`COST8X4_LEN-1   :0]   cost8x4_part;
reg   [`PE_NUM*`SAD8X8_NUM*`COST8X8_LEN-1   :0]   cost8x8_part;

wire  [`SAD4X8_NUM*`COST4X8_LEN-1           :0]   mcost4x8_w;
wire  [`SAD8X4_NUM*`COST8X4_LEN-1           :0]   mcost8x4_w;
wire  [`SAD8X8_NUM*`COST8X8_LEN-1           :0]   mcost8x8_w;

wire  [`SAD4X8_NUM*`IMVD_LEN-1              :0]   mvd_x_4x8_w,mvd_y_4x8_w;
wire  [`SAD8X4_NUM*`IMVD_LEN-1              :0]   mvd_x_8x4_w,mvd_y_8x4_w;
wire  [`SAD8X8_NUM*`IMVD_LEN-1              :0]   mvd_x_8x8_w,mvd_y_8x8_w;

reg   [`IMVD_LEN-1                          :0]   mvd_x_r4,mvd_y_r4;

reg                                               end_ld_d4;

//get the cost of 16x16 ,8x16 and 16x8 partitions
generate
    for(i=0; i<`PE_NUM; i=i+1) begin: ime_costx16_n
      ime_costx16 ime_costx16(
        .clk        (clk),
        .rstn       (rstn),        
        .mv_cost_i  (mv_cost_r3[(i+1)*`MV_COST_BITS-1:i*`MV_COST_BITS]),        
        .sadx16_v_i (sadx16_v),        
        .sad8x16_i  (sad8x16_w [(i+1)*`SAD8X16_NUM*`SAD8X16_LEN-1  : i*`SAD8X16_NUM*`SAD8X16_LEN]),
        .sad16x8_i  (sad16x8_w [(i+1)*`SAD16X8_NUM*`SAD16X8_LEN-1  : i*`SAD16X8_NUM*`SAD16X8_LEN]),
        .sad16x16_i (sad16x16_w[(i+1)*`SAD16X16_NUM*`SAD16X16_LEN-1: i*`SAD16X16_NUM*`SAD16X16_LEN]),        
        .cost8x16_o (cost8x16_w [(i+1)*`SAD8X16_NUM*`COST8X16_LEN-1  : i*`SAD8X16_NUM*`COST8X16_LEN]),
        .cost16x8_o (cost16x8_w [(i+1)*`SAD16X8_NUM*`COST16X8_LEN-1  : i*`SAD16X8_NUM*`COST16X8_LEN]),
        .cost16x16_o(cost16x16_w[(i+1)*`SAD16X16_NUM*`COST16X16_LEN-1: i*`SAD16X16_NUM*`COST16X16_LEN])
      );
    end
endgenerate

//select the minimum costs of 8x8,8x4 and 4x8 blocks
generate
    ////////////////////////////////////////////////////////////////////////
    //4x8 mux
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_4x8_n //4
      for(j=0; j< `SAD4X8_NUM; j=j+1)begin : sad_num_4x8_n  //8
        always@(*)begin
            cost4x8_part[(j*`PE_NUM+i+1)*`COST4X8_LEN-1:(j*`PE_NUM+i)*`COST4X8_LEN]  //14
            = cost4x8_w[(i*`SAD4X8_NUM + j+1)*`COST4X8_LEN-1:(i*`SAD4X8_NUM + j)*`COST4X8_LEN];  //4x8x14 
        end
      end
    end
    
    for(i = 0; i < `SAD4X8_NUM; i = i +1 ) begin : ime_mux_4x8_n 
        ime_mux #(`COST4X8_LEN) ime_mux_4x8(
            .clk      (clk),
            .rstn     (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i (costx8_v),
            .cost_i   (cost4x8_part[(i+1)*`PE_NUM*`COST4X8_LEN -1: i*`PE_NUM*`COST4X8_LEN]),
            .mvd_x_i  (mvd_x_r3),
            .mvd_x_o  (mvd_x_4x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i  (mvd_y_r3),
            .mvd_y_o  (mvd_y_4x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),            
            .cost_o   (mcost4x8_w[(i+1)*`COST4X8_LEN-1:i*`COST4X8_LEN])
        );
    end
    //end of 4x8 mux
    ////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////
    //8x4 mux
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_8x4_n
      for(j=0; j< `SAD8X4_NUM; j=j+1)begin : sad_num_8x4_n
        always@(*)begin
            cost8x4_part[(j*`PE_NUM+i+1)*`SAD8X4_LEN-1:(j*`PE_NUM+i)*`SAD8X4_LEN]
            = cost8x4_w[(i*`SAD8X4_NUM + j+1)*`SAD8X4_LEN-1:(i*`SAD8X4_NUM + j)*`SAD8X4_LEN];
        end
      end
    end
    
    for(i = 0; i < `SAD8X4_NUM; i = i +1 ) begin : ime_mux_8x4_n 
        ime_mux #(`COST8X4_LEN) ime_mux_8x4(
            .clk    (clk),
            .rstn   (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i(costx8_v),
            .cost_i (cost8x4_part[(i+1)*`PE_NUM*`COST8X4_LEN -1: i*`PE_NUM*`COST8X4_LEN]),
            .mvd_x_i(mvd_x_r3),
            .mvd_x_o(mvd_x_8x4_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i(mvd_y_r3),
            .mvd_y_o(mvd_y_8x4_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),            
            .cost_o (mcost8x4_w[(i+1)*`COST8X4_LEN-1:i*`COST8X4_LEN])
        );
    
    end
    //end of 8x4 mux
    ///////////////////////////////////////////////////////////////    
    
    ///////////////////////////////////////////////////////////////
    //8x8 mux
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_8x8_n
      for(j=0; j< `SAD8X8_NUM; j=j+1)begin : sad_num_8x8_n  //4 
        always@(*)begin
            cost8x8_part[(j*`PE_NUM+i+1)*`SAD8X8_LEN-1:(j*`PE_NUM+i)*`SAD8X8_LEN]
            = cost8x8_w[(i*`SAD8X8_NUM + j+1)*`SAD8X8_LEN-1:(i*`SAD8X8_NUM + j)*`SAD8X8_LEN];
        end
      end
    end
    
    for(i = 0; i < `SAD8X8_NUM; i = i +1 ) begin : ime_mux_8x8_n 
        ime_mux #(`COST8X8_LEN) ime_mux_8x8(
            .clk      (clk),
            .rstn     (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i (costx8_v),
            .cost_i   (cost8x8_part[(i+1)*`PE_NUM*`COST8X8_LEN -1: i*`PE_NUM*`COST8X8_LEN]),
            .mvd_x_i  (mvd_x_r3),
            .mvd_x_o  (mvd_x_8x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i  (mvd_y_r3),
            .mvd_y_o  (mvd_y_8x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),            
            .cost_o   (mcost8x8_w[(i+1)*`COST8X8_LEN-1:i*`COST8X8_LEN])
        );
    end
    //end of 8x8 mux
    ///////////////////////////////////////////////////////////////
endgenerate

always @(posedge clk or negedge rstn) begin
  if(!rstn) begin
    mvd_x_r4 <= 0;
    mvd_y_r4 <= 0;
  end
  else begin
    mvd_x_r4 <= mvd_x_r3;
    mvd_y_r4 <= mvd_y_r3;
  end
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    costx16_v <= 1'b0;
  else
    costx16_v <= sadx16_v;
end

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    end_ld_d4 <= 1'b0;
  else
    end_ld_d4 <= end_ld_d3;
end

//end of stage 4
//=====================================================================================================


//=====================================================================================================
//stage 5: select minimum cost among the 16x8, 8x16 and 16x16 partitions

wire [`PE_NUM*`SAD8X8_NUM *5-1:0]                          sub_mb_part_wire4;  //4x4x5
wire [`PE_NUM*5-1:0]                                       mb_part_wire4;      //4x5
wire [`PE_NUM*5-1:0]                                       mb_type_wire4;
wire [`PE_NUM*`SAD16X16_LEN  -1:0]                         min_cost_wire4;     //4x17

reg  [`PE_NUM*`SAD8X16_NUM  * `SAD8X16_LEN  -1:0]          cost8x16_part;      //4x2x16
reg  [`PE_NUM*`SAD16X8_NUM  * `SAD16X8_LEN  -1:0]          cost16x8_part;      
reg  [`PE_NUM*`SAD16X16_NUM * `SAD16X16_LEN -1:0]          cost16x16_part;     //4x1x17

wire [`SAD8X16_NUM*`COST8X16_LEN-1            :0]          mcost8x16_w;       //2x16
wire [`SAD16X8_NUM*`COST16X8_LEN-1            :0]          mcost16x8_w;       //2x16
wire [`SAD16X16_NUM*`COST16X16_LEN-1          :0]          mcost16x16_w;      //1x17


wire [`SAD8X16_NUM   *`IMVD_LEN-1:0 ]                      mvd_x_8x16_w;      //2x6 
wire [`SAD16X8_NUM   *`IMVD_LEN-1:0 ]                      mvd_x_16x8_w; 
wire [`SAD16X16_NUM  *`IMVD_LEN-1:0 ]                      mvd_x_16x16_w;
                                                           
wire [`SAD8X16_NUM   *`IMVD_LEN-1:0 ]                      mvd_y_8x16_w; 
wire [`SAD16X8_NUM   *`IMVD_LEN-1:0 ]                      mvd_y_16x8_w; 
wire [`SAD16X16_NUM  *`IMVD_LEN-1:0 ]                      mvd_y_16x16_w;

reg                                                        end_ld_d5;

generate
    ///////////////////////////////////////////////////////////////
    //8x16 mux
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_8x16_n
      for(j=0; j< `SAD8X16_NUM; j=j+1)begin : sad_num_8x16_n   //2
        always@(*)begin
            cost8x16_part[(j*`PE_NUM+i+1)*`COST8X16_LEN-1:(j*`PE_NUM+i)*`COST8X16_LEN]
            = cost8x16_w[(i*`SAD8X16_NUM + j+1)*`COST8X16_LEN-1:(i*`SAD8X16_NUM + j)*`COST8X16_LEN];
        end
      end
    end
    
    for(i = 0; i < `SAD8X16_NUM; i = i +1 ) begin : ime_mux_8x16_n 
        ime_mux #(`COST8X16_LEN) ime_mux_8x16(
            .clk     (clk),
            .rstn    (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i(costx16_v),
            .cost_i  (cost8x16_part[(i+1)*`PE_NUM*`COST8X16_LEN -1: i*`PE_NUM*`COST8X16_LEN]),
            .mvd_x_i (mvd_x_r4),
            .mvd_x_o (mvd_x_8x16_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i (mvd_y_r4),
            .mvd_y_o (mvd_y_8x16_w[(i+1)*`IMVD_LEN - 1:i*`IMVD_LEN]),                     
            .cost_o  (mcost8x16_w[(i+1)*`COST8X16_LEN-1:i*`COST8X16_LEN])
        );
    end
    //end of 8x16 mux
    ///////////////////////////////////////////////////////////////    
    
    ///////////////////////////////////////////////////////////////
    //16x8 mux
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_16x8_n
      for(j=0; j< `SAD16X8_NUM; j=j+1)begin : sad_num_16x8_n
        always@(*)begin
            cost16x8_part[(j*`PE_NUM+i+1)*`COST16X8_LEN-1:(j*`PE_NUM+i)*`COST16X8_LEN]
            = cost16x8_w[(i*`SAD16X8_NUM + j+1)*`COST16X8_LEN-1:(i*`SAD16X8_NUM + j)*`COST16X8_LEN];
        end
      end
    end
    
    for(i = 0; i < `SAD16X8_NUM; i = i +1 ) begin : ime_mux_16x8_n 
        ime_mux #(`COST16X8_LEN) ime_mux_16x8(
            .clk     (clk),
            .rstn    (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i(costx16_v),
            .cost_i  (cost16x8_part[(i+1)*`PE_NUM*`COST16X8_LEN -1: i*`PE_NUM*`COST16X8_LEN]),
            .mvd_x_i (mvd_x_r4),
            .mvd_x_o (mvd_x_16x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i (mvd_y_r4),
            .mvd_y_o (mvd_y_16x8_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),                     
            .cost_o  (mcost16x8_w[(i+1)*`COST16X8_LEN-1:i*`COST16X8_LEN])
        );
    end
    //end of 16x8 mux
    ///////////////////////////////////////////////////////////////    

    ///////////////////////////////////////////////////////////////
    //16x16 mux 
    for(i = 0; i < `PE_NUM; i = i +1 ) begin : pe_num_16x16_n
      for(j=0; j< `SAD16X16_NUM; j=j+1)begin : sad_num_16x16_n  //1
        always@(*)begin
            cost16x16_part[(j*`PE_NUM+i+1)*`COST16X16_LEN-1:(j*`PE_NUM+i)*`COST16X16_LEN]
            = cost16x16_w[(i*`SAD16X16_NUM + j+1)*`COST16X16_LEN-1:(i*`SAD16X16_NUM + j)*`COST16X16_LEN];
        end
      end
    end
    
    for(i = 0; i < `SAD16X16_NUM; i = i +1 ) begin : ime_mux_16x16_n 
        ime_mux #(`COST16X16_LEN) ime_mux_16x16(
            .clk     (clk),
            .rstn    (rstn),            
            .rst_mux_i(end_ime_o),            
            .cost_v_i(costx16_v),
            .cost_i  (cost16x16_part[(i+1)*`PE_NUM*`COST16X16_LEN -1: i*`PE_NUM*`COST16X16_LEN]),
            .mvd_x_i (mvd_x_r4),
            .mvd_x_o (mvd_x_16x16_w[(i+1)*`IMVD_LEN-1:i*`IMVD_LEN]),
            .mvd_y_i (mvd_y_r4),
            .mvd_y_o (mvd_y_16x16_w[`IMVD_LEN + i*`IMVD_LEN - 1:i*`IMVD_LEN]),            
            .cost_o  (mcost16x16_w[(i+1)*`COST16X16_LEN-1:i*`COST16X16_LEN])
        );
    end
    //end of 16x16 mux
    ///////////////////////////////////////////////////////////////        
endgenerate

always @(posedge clk or negedge rstn) begin
  if(!rstn)
    end_ld_d5 <= 1'b0;
  else
    end_ld_d5 <= end_ld_d4;
end

// end of stage 5
//=====================================================================================================


//=====================================================================================================
//stage 6,7: mode decision
//mode decsion for final decision

wire [`MB_TYPE_LEN-1:      0] mb_type_final;
wire [4*`SUB_MB_TYPE_LEN-1:0] sub_mb_type_final;

reg                           end_ld_d6, end_ld_d7;

    ime_min_cost ime_min_cost(
        .clk           (clk),
        .rstn          (rstn),         
        .cost4x4_i     (mcost4x4_w   ),
        .cost4x8_i     (mcost4x8_w   ),
        .cost8x4_i     (mcost8x4_w   ),
        .cost8x8_i     (mcost8x8_w   ),
        .cost8x16_i    (mcost8x16_w  ),
        .cost16x8_i    (mcost16x8_w  ),
        .cost16x16_i   (mcost16x16_w ), 
        .mb_type_o     (mb_type_final),
        .sub_mb_type_o (sub_mb_type_final)
    );
//end stage 7
//=====================================================================================================

//end of ime
reg [7:0] delay;//delay 8 cycles
always @(posedge clk or negedge rstn) begin
  if(!rstn)
    {end_ld_d7,end_ld_d6} <= 2'b00;
  else
    {end_ld_d7,end_ld_d6} <= {end_ld_d6, end_ld_d5};
end
assign end_ime_o = end_ld_d7;

assign     mb_type_o = mb_type_final;
assign sub_mb_type_o = sub_mb_type_final;

//////////////////////////////////////////////////////////////////////////////////////////////////////
//MV OUTPUT
always @(posedge clk or negedge rstn)begin
  if(!rstn)
    mvd_o_r <= 'd0 ; 
  else if(end_ime_o) begin
    case(mb_type_o)
      `PART16X16:
        mvd_o_r  <= {16{mvd_y_16x16_w,mvd_x_16x16_w}};
      `PART16X8:
        mvd_o_r  <= {{8{mvd_y_16x8_w[2*`IMVD_LEN-1:`IMVD_LEN],mvd_x_16x8_w[2*`IMVD_LEN-1:`IMVD_LEN]}},
                  {8{mvd_y_16x8_w[1*`IMVD_LEN-1:        0],mvd_x_16x8_w[1*`IMVD_LEN-1:        0]}}};
      `PART8X16:
        mvd_o_r  <= {{4{mvd_y_8x16_w[2*`IMVD_LEN-1:`IMVD_LEN],mvd_x_8x16_w[2*`IMVD_LEN-1:`IMVD_LEN]}},
                  {4{mvd_y_8x16_w[1*`IMVD_LEN-1:        0],mvd_x_8x16_w[1*`IMVD_LEN-1:        0]}},
                  {4{mvd_y_8x16_w[2*`IMVD_LEN-1:`IMVD_LEN],mvd_x_8x16_w[2*`IMVD_LEN-1:`IMVD_LEN]}},
                  {4{mvd_y_8x16_w[1*`IMVD_LEN-1:        0],mvd_x_8x16_w[1*`IMVD_LEN-1:        0]}}};
      `PART8X8: begin
         case(sub_mb_type_o[1*`SUB_MB_TYPE_LEN-1:0])
           `SUBPART8X8:
              mvd_o_r[4*2*`IMVD_LEN-1 :0*2*`IMVD_LEN] 
                    <= {4{mvd_y_8x8_w[1*`IMVD_LEN-1:0*`IMVD_LEN],mvd_x_8x8_w[1*`IMVD_LEN-1:0*`IMVD_LEN]}};
           `SUBPART8X4:
              mvd_o_r[4*2*`IMVD_LEN-1 :0*2*`IMVD_LEN]
                    <= {{2{mvd_y_8x4_w[2*`IMVD_LEN-1:1*`IMVD_LEN],mvd_x_8x4_w[2*`IMVD_LEN-1:1*`IMVD_LEN]}},
                       {2{mvd_y_8x4_w[1*`IMVD_LEN-1:0*`IMVD_LEN],mvd_x_8x4_w[1*`IMVD_LEN-1:0*`IMVD_LEN]}}};
           `SUBPART4X8:
              mvd_o_r[4*2*`IMVD_LEN-1 :0*2*`IMVD_LEN]
                    <= {{mvd_y_4x8_w[2*`IMVD_LEN-1:1*`IMVD_LEN],mvd_x_4x8_w[2*`IMVD_LEN-1 :1*`IMVD_LEN]},
                       {mvd_y_4x8_w[1*`IMVD_LEN-1:0*`IMVD_LEN],mvd_x_4x8_w[1*`IMVD_LEN-1 :0*`IMVD_LEN]},
                       {mvd_y_4x8_w[2*`IMVD_LEN-1:1*`IMVD_LEN],mvd_x_4x8_w[2*`IMVD_LEN-1 :1*`IMVD_LEN]},
                       {mvd_y_4x8_w[1*`IMVD_LEN-1:0*`IMVD_LEN],mvd_x_4x8_w[1*`IMVD_LEN-1 :0*`IMVD_LEN]}};
           `SUBPART4X4:
              mvd_o_r[4*2*`IMVD_LEN-1 :0*2*`IMVD_LEN]
                    <= {{mvd_y_4x4_w[4*`IMVD_LEN-1:3*`IMVD_LEN],mvd_x_4x4_w[4*`IMVD_LEN-1:3*`IMVD_LEN]},
                       {mvd_y_4x4_w[3*`IMVD_LEN-1:2*`IMVD_LEN],mvd_x_4x4_w[3*`IMVD_LEN-1:2*`IMVD_LEN]},
                       {mvd_y_4x4_w[2*`IMVD_LEN-1:1*`IMVD_LEN],mvd_x_4x4_w[2*`IMVD_LEN-1:1*`IMVD_LEN]},
                       {mvd_y_4x4_w[1*`IMVD_LEN-1:0*`IMVD_LEN],mvd_x_4x4_w[1*`IMVD_LEN-1:0*`IMVD_LEN]}};
         endcase
         case(sub_mb_type_o[2*`SUB_MB_TYPE_LEN-1:`SUB_MB_TYPE_LEN])
           `SUBPART8X8:
              mvd_o_r[8*2*`IMVD_LEN-1 :4*2*`IMVD_LEN] 
                    <= {4{mvd_y_8x8_w[2*`IMVD_LEN-1:1*`IMVD_LEN],mvd_x_8x8_w[2*`IMVD_LEN-1:1*`IMVD_LEN]}};
           `SUBPART8X4:
              mvd_o_r[8*2*`IMVD_LEN-1 :4*2*`IMVD_LEN]
                    <= {{2{mvd_y_8x4_w[4*`IMVD_LEN-1:3*`IMVD_LEN],mvd_x_8x4_w[4*`IMVD_LEN-1:3*`IMVD_LEN]}},
                       {2{mvd_y_8x4_w[3*`IMVD_LEN-1:2*`IMVD_LEN],mvd_x_8x4_w[3*`IMVD_LEN-1:2*`IMVD_LEN]}}};
           `SUBPART4X8:
              mvd_o_r[8*2*`IMVD_LEN-1 :4*2*`IMVD_LEN]
                    <= {{mvd_y_4x8_w[4*`IMVD_LEN-1:3*`IMVD_LEN],mvd_x_4x8_w[4*`IMVD_LEN-1 :3*`IMVD_LEN]},
                       {mvd_y_4x8_w[3*`IMVD_LEN-1:2*`IMVD_LEN],mvd_x_4x8_w[3*`IMVD_LEN-1 :2*`IMVD_LEN]},
                       {mvd_y_4x8_w[4*`IMVD_LEN-1:3*`IMVD_LEN],mvd_x_4x8_w[4*`IMVD_LEN-1 :3*`IMVD_LEN]},
                       {mvd_y_4x8_w[3*`IMVD_LEN-1:2*`IMVD_LEN],mvd_x_4x8_w[3*`IMVD_LEN-1 :2*`IMVD_LEN]}};
           `SUBPART4X4:
              mvd_o_r[8*2*`IMVD_LEN-1 :4*2*`IMVD_LEN]
                    <= {{mvd_y_4x4_w[8*`IMVD_LEN-1:7*`IMVD_LEN],mvd_x_4x4_w[8*`IMVD_LEN-1:7*`IMVD_LEN]},
                       {mvd_y_4x4_w[7*`IMVD_LEN-1:6*`IMVD_LEN],mvd_x_4x4_w[7*`IMVD_LEN-1:6*`IMVD_LEN]},
                       {mvd_y_4x4_w[6*`IMVD_LEN-1:5*`IMVD_LEN],mvd_x_4x4_w[6*`IMVD_LEN-1:5*`IMVD_LEN]},
                       {mvd_y_4x4_w[5*`IMVD_LEN-1:4*`IMVD_LEN],mvd_x_4x4_w[5*`IMVD_LEN-1:4*`IMVD_LEN]}};
         endcase
         case(sub_mb_type_o[3*`SUB_MB_TYPE_LEN-1:2*`SUB_MB_TYPE_LEN])
           `SUBPART8X8:
              mvd_o_r[12*2*`IMVD_LEN-1 :8*2*`IMVD_LEN] 
                    <= {4{mvd_y_8x8_w[3*`IMVD_LEN-1:2*`IMVD_LEN],mvd_x_8x8_w[3*`IMVD_LEN-1:2*`IMVD_LEN]}};
           `SUBPART8X4:
              mvd_o_r[12*2*`IMVD_LEN-1 :8*2*`IMVD_LEN]
                    <= {{2{mvd_y_8x4_w[6*`IMVD_LEN-1:5*`IMVD_LEN],mvd_x_8x4_w[6*`IMVD_LEN-1:5*`IMVD_LEN]}},
                       {2{mvd_y_8x4_w[5*`IMVD_LEN-1:4*`IMVD_LEN],mvd_x_8x4_w[5*`IMVD_LEN-1:4*`IMVD_LEN]}}};
           `SUBPART4X8:
              mvd_o_r[12*2*`IMVD_LEN-1 :8*2*`IMVD_LEN]
                    <= {{mvd_y_4x8_w[6*`IMVD_LEN-1:5*`IMVD_LEN],mvd_x_4x8_w[6*`IMVD_LEN-1 :5*`IMVD_LEN]},
                       {mvd_y_4x8_w[5*`IMVD_LEN-1:4*`IMVD_LEN],mvd_x_4x8_w[5*`IMVD_LEN-1 :4*`IMVD_LEN]},
                       {mvd_y_4x8_w[6*`IMVD_LEN-1:5*`IMVD_LEN],mvd_x_4x8_w[6*`IMVD_LEN-1 :5*`IMVD_LEN]},
                       {mvd_y_4x8_w[5*`IMVD_LEN-1:4*`IMVD_LEN],mvd_x_4x8_w[5*`IMVD_LEN-1 :4*`IMVD_LEN]}};
           `SUBPART4X4:
              mvd_o_r[12*2*`IMVD_LEN-1 :8*2*`IMVD_LEN]
                    <= {{mvd_y_4x4_w[12*`IMVD_LEN-1:11*`IMVD_LEN],mvd_x_4x4_w[12*`IMVD_LEN-1:11*`IMVD_LEN]},
                       {mvd_y_4x4_w[11*`IMVD_LEN-1:10*`IMVD_LEN],mvd_x_4x4_w[11*`IMVD_LEN-1:10*`IMVD_LEN]},
                       {mvd_y_4x4_w[10*`IMVD_LEN-1: 9*`IMVD_LEN],mvd_x_4x4_w[10*`IMVD_LEN-1: 9*`IMVD_LEN]},
                       {mvd_y_4x4_w[ 9*`IMVD_LEN-1: 8*`IMVD_LEN],mvd_x_4x4_w[ 9*`IMVD_LEN-1: 8*`IMVD_LEN]}};
         endcase
         case(sub_mb_type_o[4*`SUB_MB_TYPE_LEN-1:3*`SUB_MB_TYPE_LEN])
           `SUBPART8X8:
              mvd_o_r[16*2*`IMVD_LEN-1 :12*2*`IMVD_LEN] 
                    <= {4{mvd_y_8x8_w[4*`IMVD_LEN-1:3*`IMVD_LEN],mvd_x_8x8_w[4*`IMVD_LEN-1:3*`IMVD_LEN]}};
           `SUBPART8X4:
              mvd_o_r[16*2*`IMVD_LEN-1 :12*2*`IMVD_LEN]
                    <= {{2{mvd_y_8x4_w[8*`IMVD_LEN-1:7*`IMVD_LEN],mvd_x_8x4_w[8*`IMVD_LEN-1:7*`IMVD_LEN]}},
                       {2{mvd_y_8x4_w[7*`IMVD_LEN-1:6*`IMVD_LEN],mvd_x_8x4_w[7*`IMVD_LEN-1:6*`IMVD_LEN]}}};
           `SUBPART4X8:
              mvd_o_r[16*2*`IMVD_LEN-1 :12*2*`IMVD_LEN]
                    <= {{mvd_y_4x8_w[8*`IMVD_LEN-1:7*`IMVD_LEN],mvd_x_4x8_w[8*`IMVD_LEN-1 :7*`IMVD_LEN]},
                       {mvd_y_4x8_w[7*`IMVD_LEN-1:6*`IMVD_LEN],mvd_x_4x8_w[7*`IMVD_LEN-1 :6*`IMVD_LEN]},
                       {mvd_y_4x8_w[8*`IMVD_LEN-1:7*`IMVD_LEN],mvd_x_4x8_w[8*`IMVD_LEN-1 :7*`IMVD_LEN]},
                       {mvd_y_4x8_w[7*`IMVD_LEN-1:6*`IMVD_LEN],mvd_x_4x8_w[7*`IMVD_LEN-1 :6*`IMVD_LEN]}};
           `SUBPART4X4:
              mvd_o_r[16*2*`IMVD_LEN-1 :12*2*`IMVD_LEN]
                    <= {{mvd_y_4x4_w[16*`IMVD_LEN-1:15*`IMVD_LEN],mvd_x_4x4_w[16*`IMVD_LEN-1:15*`IMVD_LEN]},
                       {mvd_y_4x4_w[15*`IMVD_LEN-1:14*`IMVD_LEN],mvd_x_4x4_w[15*`IMVD_LEN-1:14*`IMVD_LEN]},
                       {mvd_y_4x4_w[14*`IMVD_LEN-1:13*`IMVD_LEN],mvd_x_4x4_w[14*`IMVD_LEN-1:13*`IMVD_LEN]},
                       {mvd_y_4x4_w[13*`IMVD_LEN-1:12*`IMVD_LEN],mvd_x_4x4_w[13*`IMVD_LEN-1:12*`IMVD_LEN]}};
         endcase
       end
    endcase   
  end
end

assign  mvd_o = mvd_o_r ;

endmodule 

