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
// Filename       : fme_ram.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module fme_ram(
       clk_i                  ,
       rst_n_i                ,
                              
       clear_i                , 
                              
       data_i                 ,
       wren_i                 ,
       ft_go_ahead_o          ,
                              
       update_base_rd_i       , 
       the_last_line_i        , 
       rden_i                 ,
       data_o                 ,
                              
       empty_o                ,
       full_o                 ,
                              
       rden_mc_i              ,
       addr_mc_i              ,
       data_mc_o              ,
       ack_mc_o
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                     clk_i              ;  //clock 
input                     rst_n_i            ;  //reset_n 
                                             
input                     clear_i            ;  //clear是由controller模块发出的，是为了下一个MB做好准备； 
                                             
input [20*`BIT_DEPTH-1:0] data_i             ;  //luma_data from fme_fetch 
input                     wren_i             ;  //write_enable from fme_fetch 

output                    ft_go_ahead_o      ;  //fetch_go_ahead 
                                             
input                     update_base_rd_i   ;  //是由读模块发出的，为了更新base_rd 
input                     the_last_line_i    ;  //一个块中 
input                     rden_i             ;  //read_enable from fme_Load
output[20*`BIT_DEPTH-1:0] data_o             ;  //luma_data from fme_load 
                                             
output                    empty_o            ;  //ram_empty to fem_load 
output                    full_o             ;  //ram_full to fme_fetch 

input                     rden_mc_i          ;  //read enable from MC    
input [6              :0] addr_mc_i          ;  //address  from MC       
output[20*`BIT_DEPTH-1:0] data_mc_o          ;  //read_data(luma) to MC  
output                    ack_mc_o           ;  //read_ack signal to MC  

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 

wire                      fifo_empty         ;
wire                      fifo_full          ;

wire [6               :0] rd_addr            ;
wire [6               :0] wr_addr            ;

wire                      fme_wren           ;
wire [20*`BIT_DEPTH-1 :0] fme_wrdata         ;
wire [6               :0] addr_p0            ;

//tri  [20*`BIT_DEPTH-1 :0] data_p0            ;
//wire                      wren_p0            ;
wire                      ack_mc_o           ;

wire                      fme_wra_lt_mc_rda  ;
wire                      we_p0              ;
wire                      csn_0, csn_1       ;
//mc read address 
wire [7               :0] mc_rda_minus2      ;
wire [6               :0] fme_wra            ;

// ******************************************** 
//                                              
//    Reg DECLARATION                          
//                                              
// ******************************************** 
reg  [6               :0] base_rd, end_rd    ;  //The MSB is used for deciding the direction of FIFO.
reg  [6               :0] rd_ptr             ;
reg  [6               :0] wr_ptr             ;

// mc read address 
reg  [6               :0] mc_rda             ;

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    base_rd <= 7'd0;
  else
    if(clear_i)
      base_rd <= 7'd0;
    else begin
      if(update_base_rd_i)
        base_rd <= end_rd + 7'd1;
      else
        base_rd <= base_rd;
    end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    rd_ptr <= 0;
  else
    if(clear_i)
      rd_ptr <= 0;
    else
      if(rden_i)
        if(update_base_rd_i)
          rd_ptr <= end_rd + 7'd1;
        else
          if(the_last_line_i)
            rd_ptr <= base_rd;
          else
            rd_ptr <= rd_ptr + 7'd1;
      else
        rd_ptr <= rd_ptr;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_rd <= 7'd0;
  else
    if(clear_i)
      end_rd <= 7'd0;
    else if (the_last_line_i)
      end_rd <= rd_ptr;
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    wr_ptr <= 7'd0;
  else
    if(clear_i)
      wr_ptr <= 7'd0;
    else
      if(fme_wren&(~fifo_full))
        wr_ptr <= wr_ptr + 7'd1;
      else
        wr_ptr <= wr_ptr;
end

assign fifo_empty = (wr_ptr == rd_ptr);//现在定义成了80 depth所以wr_ptr最远也就指到80，wr_ptr的最终值为80
assign fifo_full  = 1'b0                 ;
assign empty_o    = fifo_empty        ;
assign full_o     = fifo_full         ;
                                      
assign rd_addr    = rd_ptr[6:0]       ;
assign wr_addr    = wr_ptr[6:0]       ;

//mc read address

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mc_rda <= 'b0;
  else
    if(clear_i)
      mc_rda <= 'b0;
    else
      if(ack_mc_o)
        mc_rda <= mc_rda + 1'b1;
      else
        mc_rda <= mc_rda;
end

assign fme_wra       = wr_ptr;
// 让fmefetch继续进行下一次读取，若是fme_wra < mc_rda，则会导致fetch读取的数据无法写入到ram中去
// rden_mc_i保证了，当mc不进行读的时候，通知给fetch可以继续，其实这个地方还是有个问题的，若是MC被阻塞了，一直没有运行，那么fetch会照常写入数据，由于MC被阻塞，因此数据在还没有被读的情况下阻塞
// fme连续输入的时候是mc_rda-2'b2，因为得需要两个空余空间。若不是，mc_rda-1'b1就可以。
assign mc_rda_minus2     = ({1'b0,mc_rda} + 8'b1111_1110)                          ;
assign fme_wra_lt_mc_rda = ((mc_rda_minus2[7] == 0)&(fme_wra < mc_rda_minus2[6:0]));
assign ft_go_ahead_o     = (fme_wra_lt_mc_rda) | (!rden_mc_i)                      ;

assign fme_wren          = ((fme_wra < mc_rda)|(!rden_mc_i)) & wren_i              ;
assign fme_wrdata        = data_i                                                  ;
assign addr_p0           = (fme_wren)?wr_addr:addr_mc_i                            ;
                                                                                   
assign we_p0             = (fme_wren)?1'b1:1'b0                                    ; //we_p0 = fme_wren ; 
                                                                                   
assign ack_mc_o          = !fme_wren & rden_mc_i                                   ;
                                                                                   
assign csn_0             = ~(we_p0 | rden_mc_i)                                    ; 
assign csn_1             = ~(rden_i)                                               ;

fme_ram_2p_160x128  u_fme_ram(
         .clk       ( clk_i                     ), // Clock Input
         .addr_a    ( addr_p0                   ), // address_0 Input
         .rdata_a   ( data_mc_o                 ), // data_0 bi-directional
         .wdata_a   ( fme_wrdata                ),
         .csn_a     ( csn_0                     ), // Chip Select
         .wen_a     ( !we_p0                    ), // Write Enable/Read Enable
         .addr_b    ( rd_addr                   ), // address_1 Input
         .rdata_b   ( data_o                    ), // data_1 bi-directional
         .wdata_b   ( {(20*`BIT_DEPTH){1'b0}}   ),
         .csn_b     ( csn_1                     ), // Chip Select
         .wen_b     ( 1'b1                      )  // Write Enable/Read Enable
); 
endmodule
