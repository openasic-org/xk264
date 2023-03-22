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
// Filename       : fme_fetch.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module fme_fetch(
       clk_i              ,
       rst_n_i            ,
                          
       start_wr_i         ,
                          
       mb_type_i          ,
       sub_mb_type_i      ,
       part_o             ,
                          
       cmb_x_i            ,
       cmb_y_i            ,
                          
       mv0_x_i            ,
       mv0_y_i            ,
       mv1_x_i            ,
       mv1_y_i            ,
       mv0_addr_o         ,    
                          
       full_i             ,     
       ft_go_ahead_i      ,
       wrdata_o           ,
       wren_o             ,
                          
       cmb_x_o            ,
       cmb_y_o            ,
       sw_pel_x_o         ,
       sw_pel_y_o         ,
       rden_cache_o       ,
       rddone_cache_o     ,
       ack_cache_i        ,
       rddata_cache_i
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                          clk_i           ;  //clock 
input                          rst_n_i         ;  //reset_n 
                                               
input                          start_wr_i      ;  //fetch_start of load ref_pixel from cache ; from fme_ctr
                                               
input  [2                  :0] mb_type_i       ;  //MB's type 
input  [2                  :0] sub_mb_type_i   ;  //sub MB''s type
output [1                  :0] part_o          ;  //part 
                                               
input  [7                  :0] cmb_x_i         ;  //x_coordinate of current MB's from sys_if   
input  [7                  :0] cmb_y_i         ;  //y_coordinate of current MB's from sys_if   
                                               
input  [`IMVD_LEN-1        :0] mv0_x_i         ;  //motion_vector 
input  [`IMVD_LEN-1        :0] mv1_x_i         ;  //motion_vector 
input  [`IMVD_LEN-1        :0] mv0_y_i         ;  //motion_vector 
input  [`IMVD_LEN-1        :0] mv1_y_i         ;  //motion_vector 
output [3                  :0] mv0_addr_o      ;  //一个地址可以读两个mv，两个挨着的MV，这样为了能够实现8-pixel共用

//Fme_ram_IF                                                
input                          full_i          ;  //from fifo if the fifo is not full, wr module can write the data to fifo.
input                          ft_go_ahead_i   ;  //fetch go ahead 
output [20*`BIT_DEPTH-1    :0] wrdata_o        ;  //write data 
output                         wren_o          ;  //write_enable 
                                               
//Fetch_IF                                                             
output [7                  :0] cmb_x_o         ;  //x_coordinate of current MB's to fetch    
output [7                  :0] cmb_y_o         ;  //y_coordinate of current MB's to fetch    
output [`SW_W_LEN          :0] sw_pel_x_o      ;  //search_window  x_coordinate to fetch 
output [`SW_H_LEN          :0] sw_pel_y_o      ;  //search_window  y_coordinate to fetch 
output                         rden_cache_o    ;  //read_enable  to fetch ; fetch_ld_en 
output                         rddone_cache_o  ;  //read_done   to fetch  ; fetch_lddone 
input                          ack_cache_i     ;  //ack  from fetch ; =fetch_valid_i 
input  [16*`BIT_DEPTH-1   :0]  rddata_cache_i  ;  //read_data from fetch 

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
//计算读地址
wire signed [`SW_W_LEN   :0] pixel_x           ;
wire signed [`SW_H_LEN   :0] pixel_y           ;
wire signed [4           :0] pixel_x_blk       ;
wire signed [4           :0] pixel_y_blk       ;
wire signed [`SW_W_LEN   :0] motionblk_x       ;
wire signed [`SW_H_LEN   :0] motionblk_y       ;
wire signed [`IMVD_LEN   :0] mv_x_pad, mv_y_pad;
wire                         wr_col_incr_en    ;
wire                         end_one_row       ;
wire                         end_one_blk       ;
wire                         end_one_mb        ;
wire                         end_one_part      ;

wire                         rden_cache        ;
wire                         ack_cache         ;
wire                         time_inc          ; 

wire [`IMVD_LEN-1        :0] mv_x, mv_y        ;

wire signed [4           :0] wr_col_cn_s       ;
wire signed [5           :0] wr_row_cn_s       ;
//rw_row_cn calculating
wire                         working_mode      ;

wire [2                  :0] limit             ;
wire [16*`BIT_DEPTH-1    :0] cache_data        ;
// ********************************************
//                                             
//    Reg  DECLARATION                         
//                                             
// ********************************************
reg [20*`BIT_DEPTH-1    :0] wrdata_o          ;
//global signal                               
reg                         blk4xn_switch     ;
reg                   state_wrf, nextstate_wrf;

//read sub mb type
reg [1                  :0] part_cn           ;
reg [1                  :0] subpart_cn        ;
reg [1                  :0] blk_cn            ;
                                              
reg [1                  :0] wr_blk            ;
reg [4                  :0] wr_row            ;
reg [1                  :0] wr_part           ;
reg [1                  :0] wr_subpart        ;

reg [4                  :0] wr_col_cn_r       ;
reg [4                  :0] wr_row_cn         ;
//  delay one cycle
//data rearrangement
reg  [`BIT_DEPTH-1      :0] data[19:0]        ;
reg                         cache_data_valid  ;
reg  [2                 :0] prev_state_rdc    ;
reg  [3                 :0] x_mod_16          ;
reg  [4                 :0] addr_data         ;
reg                         end_row_d         ;

reg                         data_valid        ;
reg            working_mode_d0,working_mode_d1;
//read mv
reg [3                  :0] mv_addr           ;

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter IDLE=1'b0, WRING=1'b1;

// ********************************************
//                                             
//    FSM  Logic                  
//                                             
// ********************************************

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    state_wrf <= IDLE;
  else
    state_wrf <= nextstate_wrf;
end

always @( * ) begin
  nextstate_wrf  = IDLE;
  case(state_wrf)
    IDLE:
      if(start_wr_i)
        nextstate_wrf = WRING;
      else
        nextstate_wrf = IDLE;
    WRING:
      if(end_one_mb)
        nextstate_wrf = IDLE;
      else
        nextstate_wrf = WRING;
    default:
      nextstate_wrf   = IDLE;
  endcase
end

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
assign ack_cache = ack_cache_i;

//read sub mb type
assign part_o = part_cn;


always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16:    begin
      wr_row     = 5'd21;
      wr_part    = 2'd1;
      wr_subpart = 2'd0;
    end
    `P_L0_L0_16x8:  begin
      wr_row     = 5'd13;
      wr_part    = 2'd3;
      wr_subpart = 2'd0;
    end
    `P_L0_L0_8x16:  begin
      wr_row     = 5'd21;
      wr_part    = 2'd1;
      wr_subpart = 2'd0;
    end
    `P_8x8:         begin
      wr_part    = 2'd3;
      case(sub_mb_type_i)
        `P_L0_8x8:  begin
          wr_row     = 5'd13;
          wr_subpart = 2'd0;
        end
        `P_L0_8x4:  begin
          wr_row     = 5'd9;
          wr_subpart = 2'd1;
        end
        `P_L0_4x8:   begin
          wr_row     = 5'd13;
          wr_subpart = 2'd0;
        end
        `P_L0_4x4:   begin
          wr_row     = 5'd9;
          wr_subpart = 2'd1;
        end
        default: begin
          wr_row     = 5'd0;
          wr_subpart = 2'd0;
        end
      endcase
    end
    default:    begin
      wr_row     = 5'd0;
      wr_part    = 2'd0;
      wr_subpart = 2'd0;
    end
  endcase
end

//block counter
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    subpart_cn <= 2'd0;
  else
    if(end_one_blk)
      if(subpart_cn == wr_subpart)
        subpart_cn <= 2'd0;
      else
        subpart_cn <= subpart_cn + 2'd1;
    else
      subpart_cn <= subpart_cn;
end

assign end_one_blk = (wr_row_cn == wr_row) & time_inc;

//partition counter
always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    part_cn <= 2'd0;
  else
    if(end_one_part)
      if(part_cn == wr_part)
        part_cn <= 2'd0;
      else
        part_cn <= part_cn + 2'd1;
    else
      part_cn <= part_cn;
end
assign end_one_part = (subpart_cn == wr_subpart)&(end_one_blk);
assign end_one_mb   = (part_cn == wr_part)&(end_one_part);

//rw_row_cn calculating

assign working_mode = (mb_type_i == `P_8x8) & (sub_mb_type_i == `P_L0_4x8)|(sub_mb_type_i == `P_L0_4x4);
//若是工作在4xn模式，第二个4xn结束后才能加1，所以设置blk4xn_swith用来计数用的。

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    blk4xn_switch <= 1'b0;
  else
    if(end_one_row & working_mode)
      blk4xn_switch <= blk4xn_switch + 1'b1;
end

assign time_inc = (working_mode)?(blk4xn_switch & end_one_row):end_one_row;


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    wr_row_cn <= 5'd0;
  else
    if( time_inc )
      if( wr_row_cn == wr_row )
        wr_row_cn <= 5'd0;
      else
        wr_row_cn <= wr_row_cn + 5'd1;
    else
      wr_row_cn <= wr_row_cn;
end

//assign limit = (working_mode)?3'd2:3'd6;//4xn:10-8; 8xn:14-8
assign limit = (working_mode)?3'd5:3'd1;//4xn:16-10; 8xn:16-14
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    wr_col_cn_r <= 5'd0;
  else
    if(wr_col_incr_en)
      if(pixel_x[3:0] < limit)
        wr_col_cn_r <= 'd0;
      else
        wr_col_cn_r <= wr_col_cn_r + {5'd16 - pixel_x[3:0]};
    else
      wr_col_cn_r <= wr_col_cn_r;
end
wire  [3 :0] wr_col_cn ; 
assign    wr_col_cn = wr_col_cn_r[3:0] ;
//increase address
assign wr_col_incr_en = rden_cache ;

assign {mv_x,mv_y} = (blk4xn_switch)?{mv1_x_i,mv1_y_i}:{mv0_x_i,mv0_y_i};

//assign pixel_x_16 = cmb_x_i << 4;
//assign pixel_y_16 = cmb_y_i << 4;

assign pixel_x_blk = {1'b0,{part_cn[0],   3'b000}|{blk4xn_switch,  2'b00}};
assign pixel_y_blk = {1'b0,{part_cn[1],   3'b000}|{subpart_cn[0],  2'b00}};

//assign mv_x_pad    = mv_x + ('d29<<2);//用clip操作会存在一个问题，因为你是连着读好几个的
//assign mv_y_pad    = mv_y + ('d29<<2);//别忘了减三
assign mv_x_pad      = {mv_x[`IMVD_LEN-1],mv_x} -2'd3 + 5'd`SR_HOR;
assign mv_y_pad      = {mv_y[`IMVD_LEN-1],mv_y} -2'd3 + 5'd`SR_VER + 2'd3; // + ('d3<<2);


assign motionblk_x    = pixel_x_blk + mv_x_pad;
assign motionblk_y    = pixel_y_blk + mv_y_pad;

assign wr_col_cn_s    = {1'b0, wr_col_cn};
assign wr_row_cn_s    = {1'b0, wr_row_cn};
assign pixel_x        = motionblk_x + wr_col_cn_s;
assign pixel_y        = motionblk_y + wr_row_cn_s;
assign sw_pel_x_o     = pixel_x;
assign sw_pel_y_o     = pixel_y;

assign cmb_x_o        = cmb_x_i;
assign cmb_y_o        = cmb_y_i;

assign end_one_row    = rden_cache & (pixel_x[3:0] < limit);
//当ram空间少于两个的时候，fetch应该停止读取
assign rden_cache     = (state_wrf == WRING)&(!full_i) & (ft_go_ahead_i);
assign rden_cache_o   = rden_cache;
assign rddone_cache_o = end_one_mb;


//=============================================================================================
//  delay one cycle
//=============================================================================================
//data rearrangement

always @( posedge clk_i or negedge rst_n_i ) begin
  if(!rst_n_i)
    x_mod_16 <= 'd0;
  else
    x_mod_16 <= pixel_x[3:0];
end


assign cache_data = rddata_cache_i;

always @( posedge clk_i or negedge rst_n_i ) begin
  if(!rst_n_i)
    addr_data <= 'd0;
  else
    addr_data <= wr_col_cn + ((blk4xn_switch)?4'd10:4'd0);
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin :i_n
  integer i;    
    for(i=0;i<20;i=i+1) begin
      data[i] <= 'b0;
    end
  end
  else
    if(ack_cache)
      case(x_mod_16[3:0])
        4'b0000:
          {data[addr_data + 15],
           data[addr_data + 14],
           data[addr_data + 13],
           data[addr_data + 12],
           data[addr_data + 11],
           data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data;
        4'b0001:
          {data[addr_data + 14],
           data[addr_data + 13],
           data[addr_data + 12],
           data[addr_data + 11],
           data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:1*`BIT_DEPTH];
        4'b0010:
          {data[addr_data + 13],
           data[addr_data + 12],
           data[addr_data + 11],
           data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:2*`BIT_DEPTH];
        4'b0011:
          {data[addr_data + 12],
           data[addr_data + 11],
           data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:3*`BIT_DEPTH];
        4'b0100:
          {data[addr_data + 11],
           data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:4*`BIT_DEPTH];
        4'b0101:
          {data[addr_data + 10],
           data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:5*`BIT_DEPTH];
        4'b0110:
          {data[addr_data + 9],
           data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:6*`BIT_DEPTH];
        4'b0111:
          {data[addr_data + 8],
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:7*`BIT_DEPTH];
         4'b1000:
          {
           data[addr_data + 7],
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:8*`BIT_DEPTH];
         4'b1001:
          {
           data[addr_data + 6],
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:9*`BIT_DEPTH];
         4'b1010:
          {
           data[addr_data + 5],
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:10*`BIT_DEPTH];
         4'b1011:
          {
           data[addr_data + 4],
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:11*`BIT_DEPTH];
         4'b1100:
          {
           data[addr_data + 3],
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:12*`BIT_DEPTH];
         4'b1101:
          {
           data[addr_data + 2],
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:13*`BIT_DEPTH];
         4'b1110:
          {
           data[addr_data + 1],
           data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:14*`BIT_DEPTH];
         4'b1111:
          {data[addr_data + 0]} <= cache_data[16*`BIT_DEPTH-1:15*`BIT_DEPTH];
        default:
          begin :n_default 
            integer i ; 
            for(i=0;i<20;i=i+1) begin
              data[i] <= data[i];
            end
          end
      endcase
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    end_row_d  <= 'd0;
    data_valid <= 'd0;
  end
  else begin
    end_row_d  <= time_inc;
    data_valid <= end_row_d;//(pixel_x[3:0] < limit) & ack_cache & (!working_mode | (working_mode & blk4xn_switch));
  end
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    working_mode_d0 <= 1'b0;
    working_mode_d1 <= 1'b0;
  end
  else begin
    working_mode_d0 <= working_mode;
    working_mode_d1 <= working_mode_d0;
  end
end

genvar j;
generate
  for(j=0;j<20;j=j+1) begin: wrdata_j
    always @( * ) begin
      if(working_mode_d1)
        wrdata_o[(j+1)*`BIT_DEPTH-1:j*`BIT_DEPTH] = data[j];
      else
        if(j<10)
           wrdata_o[(j+1)*`BIT_DEPTH-1:j*`BIT_DEPTH] = data[j];
        else
           wrdata_o[(j+1)*`BIT_DEPTH-1:j*`BIT_DEPTH] = data[j-6];  //??????
    end
  end
endgenerate
assign wren_o   = data_valid;

//read mv

always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16:
      mv_addr = 0;
    `P_L0_L0_16x8:
      mv_addr = {part_cn[1],3'b000};
    `P_L0_L0_8x16:
      mv_addr = {part_cn,2'b00};
    `P_8x8:
      case(sub_mb_type_i)
        `P_L0_8x8:
          mv_addr  = {part_cn,2'b00};
        `P_L0_8x4: 
          mv_addr  = {part_cn,2'b00} | {2'b00,subpart_cn[0],1'b0};
        `P_L0_4x8: 
          mv_addr  = {part_cn,2'b00};
        `P_L0_4x4: 
          mv_addr  = {part_cn,2'b00} | {2'b00,subpart_cn[0],1'b0};
        default:   
          mv_addr  = 0;
      endcase
    default:
      mv_addr  = 0;
  endcase
end

assign mv0_addr_o = mv_addr;

endmodule
