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
// Filename       : fme_load.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module fme_load(
       clk_i                     ,
       rst_n_i                   ,
                                 
       start_rd_i                ,
       rd_row_i                  ,
       rd_blk_i                  ,
       end_rd_o                  ,
                                 
       empty_i                   ,
       rddata_i                  ,
       rden_o                    ,
       
       //fme interpolator
       refdata_o                 ,
       refdata_valid_o           ,
       area_co_locate_o          ,        
       end_one_blk_rd_o        
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                      clk_i               ;   //clock 
input                      rst_n_i             ;   //reset_n 

//fme_ctr_IF                                                 
input  [4              :0] rd_row_i            ;   //read_row from fme_ctr
input                      rd_blk_i            ;   //read  from fme_ctr 
                                                
input                      start_rd_i          ;   //start read from fme_ctr 
output                     end_rd_o            ;   //表示已经读完所交给的任务
//fme_ram_IF                                                  
input                      empty_i             ;   //empty_ram 
input  [20*`BIT_DEPTH-1:0] rddata_i            ;   //read_data 
output                     rden_o              ;   //read_enable  to fme_ram 
                                               
output [20*`BIT_DEPTH-1:0] refdata_o           ;
output                     refdata_valid_o     ;
output                     area_co_locate_o    ;  //to datapath interpolator for get the sub pels valid siganl  
output                     end_one_blk_rd_o    ;  //to datapath interpolator for get the down shift signal   

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 
wire                       end_one_blk         ;
wire                       end_one_subpart_rd  ;
wire                       rden                ;


// ********************************************
//                                             
//    Reg  DECLARATION                         
//                                             
// ******************************************** 
reg [4                 :0] rd_row              ;
reg                        rd_blk              ;
reg                        state, nextstate    ;

reg [4                 :0] row_cn              ;
reg [1                 :0] blk_cn              ;

// read operation need to delay one cycle 
reg                        refdata_valid       ;
reg                        area_co_locate      ;
reg                        end_one_blk_rd      ;

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter RD_IDLE=1'b0,
          RD_RUN =1'b1;
// ********************************************
//                                             
//    FSM  Logic                  
//                                             
// ********************************************        
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    state <= RD_IDLE;
  end
  else
    state <= nextstate;
end

always @( * ) begin
  nextstate = RD_IDLE;
  case(state)
    RD_IDLE: begin
      if(start_rd_i)
        nextstate = RD_RUN;
      else
        nextstate = RD_IDLE;
    end
    RD_RUN:  begin
      if(end_one_subpart_rd)    //要注意对subpart的理解，其实就是针对一个被处理的blk
        if(start_rd_i)
          nextstate = RD_RUN;
        else
          nextstate = RD_IDLE;
      else
        nextstate = RD_RUN;
    end
    default: begin
      nextstate = RD_IDLE;
    end
  endcase
end

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
always @(posedge clk_i, negedge rst_n_i) begin
  if(!rst_n_i) begin
    rd_row <= 0;
    rd_blk <= 0;
  end
  else if(start_rd_i) begin
    rd_row <= rd_row_i;
    rd_blk <= rd_blk_i;
  end
end

assign rden   = (state == RD_RUN)&(!empty_i);
assign rden_o = rden                        ;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    row_cn <= 5'd0;
  else if(rden)
    if(row_cn == rd_row)
      row_cn <= 5'd0;
    else
      row_cn <= row_cn + 5'd1;
  else
    row_cn <= row_cn;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    blk_cn <= 2'd0;
  else if(end_one_blk)
    if(blk_cn == rd_blk)
      blk_cn <= 2'd0;
    else
      blk_cn <= blk_cn + 2'd1;
  else
    blk_cn <= blk_cn;
end

assign end_one_blk          = (row_cn == rd_row)&(rden)      ;
assign end_one_subpart_rd   = (end_one_blk)&(blk_cn==rd_blk) ;
assign end_rd_o             = end_one_subpart_rd             ;

//读入要延迟一个周期

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    refdata_valid <= 1'b0;
  else
    refdata_valid <= rden;
end

always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    area_co_locate <= 0;
  else if(rden)
    area_co_locate <= (row_cn >= 3)&&(row_cn <= (rd_row-3)); // ?????? 
  else
    area_co_locate <= 0;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_one_blk_rd <= 0;
  else 
    end_one_blk_rd <= end_one_blk;
end

assign refdata_o        = rddata_i        ;
assign refdata_valid_o  = refdata_valid   ; 
assign area_co_locate_o = area_co_locate  ;
assign end_one_blk_rd_o = end_one_blk_rd  ;

endmodule
