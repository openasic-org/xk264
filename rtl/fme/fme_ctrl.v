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
// Filename       : fme_ctrl.v
// Author         : Jialiang Liu
// Created        : 2011.5-2011.6
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module fme_ctrl(
       clk_i                             ,
       rst_n_i                           ,
                                         
       start_fme_i                       ,
                                         
       mb_type_rd_i                      ,
       sub_mb_type_rd_i                  ,
       part_cn_rd_o                      ,
                                         
       mb_type_ip_i                      ,
       sub_mb_type_ip_i                  ,
       part_cn_ip_o                      , 
                                         
       mb_type_satd_i                    ,
       sub_mb_type_satd_i                ,
       part_cn_satd_o                    ,
                                         
       mb_type_bcs_i                     ,
       sub_mb_type_bcs_i                 ,
       part_cn_bcs_o                     ,
       subpart_cn_bcs_o                  ,
                                            
       start_rd_o                        ,        
       end_onemb_rd_o                    ,
       updata_base_rd_o                  ,  
       rd_row_rd_o                       ,  
       rd_blk_rd_o                       ,  
       end_rd_i                          ,  
                                                     
       start_ft_o                        ,
                                              
       end_oneblk_ip_i                   ,
       half_flag_ip_o                    ,
       half_flag_bcs_o                   ,
       working_mode_satd_o               ,
       working_mode_bcs_o                ,
                                                             
       candi_valid_i                     ,
       cmb_p_addr_o                      ,
                                                  
       satd_4x4_valid_i                  ,
       satd_blk_valid_o                  ,
                                                     
       imv_addr_o                        ,
       best_candi_i                      ,
              
       end_fme_o
);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                          clk_i               ;
input                          rst_n_i             ;
                                                   
input                          start_fme_i         ;  
                                                   
input  [`MB_TYPE_LEN-1     :0] mb_type_rd_i        ;  //MB's type 
input  [`SUB_MB_TYPE_LEN-1 :0] sub_mb_type_rd_i    ;  //sub_MB's type 
output [1                  :0] part_cn_rd_o        ;
                                                   
input  [`MB_TYPE_LEN-1     :0] mb_type_ip_i        ;  //datapath
input  [`SUB_MB_TYPE_LEN-1 :0] sub_mb_type_ip_i    ;
output [1                  :0] part_cn_ip_o        ;
                                                   
input  [`MB_TYPE_LEN-1     :0] mb_type_satd_i      ;  //datapath
input  [`SUB_MB_TYPE_LEN-1 :0] sub_mb_type_satd_i  ;
output [1                  :0] part_cn_satd_o      ;

input  [`MB_TYPE_LEN-1     :0] mb_type_bcs_i       ;  //datapath
input  [`SUB_MB_TYPE_LEN-1 :0] sub_mb_type_bcs_i   ;
output [1                  :0] part_cn_bcs_o       ;
output [1                  :0] subpart_cn_bcs_o    ;

//read refpels from fme_fifo   
output                         start_rd_o          ;  //read reference data
output                         end_onemb_rd_o      ;
output                         updata_base_rd_o    ;  //mc 结束后其实就是一个块的结束，对于16x8来说，有2个part每个part有0个subpart
output [4                  :0] rd_row_rd_o         ;  //告诉load需要加载多少行/每个blk                                    
output                         rd_blk_rd_o         ;  //告诉load需要加载多少个blk                                         
input                          end_rd_i            ;  //结束读一个块，这个快可以是16x16，完整的块                      

//load refpels from cache   
output                         start_ft_o          ;  //start_fetch        
                                                                                    
output                         half_flag_ip_o      ;                                
output                         half_flag_bcs_o     ;                                
output                         working_mode_satd_o ;  //4xn or 8xn                    
output                         working_mode_bcs_o  ;  //4xn or 8xn   
//to datapath                                                         
input                          end_oneblk_ip_i     ;

//from interpolator                                                    
input                          candi_valid_i       ;
output [4                  :0] cmb_p_addr_o        ;

//from and to best candidate select
//from and to SATD accumulation 
input                          satd_4x4_valid_i    ;
output                         satd_blk_valid_o    ;

//to best candidate select   
output [3                  :0] imv_addr_o          ;
input                          best_candi_i        ;

//control outputting                                                   
output                         end_fme_o           ;

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 
wire [`MB_TYPE_LEN-1     :0]  mb_type_rd           ;
wire [`SUB_MB_TYPE_LEN-1 :0]  sub_mb_type_rd       ;
                                                   
//ip stage                                         
wire  [`MB_TYPE_LEN-1    :0] mb_type_ip            ;

wire  [`MB_TYPE_LEN-1    :0] mb_type_satd          ;
wire  [`SUB_MB_TYPE_LEN-1:0] sub_mb_type_satd      ;
                                                   
wire  [`MB_TYPE_LEN-1    :0] mb_type_bcs           ;
wire  [`SUB_MB_TYPE_LEN-1:0] sub_mb_type_bcs       ;

//loader control  fme require the loader loading the data

wire                         start_quar            ;
wire                         start_mc              ;
wire                         end_onesubpart        ;
wire                         end_onepart           ;
wire                         end_onemb             ;
wire                         half_flag_rd          ;

wire                         type_8x16             ;

wire                         satd_4x4_valid        ;

// ********************************************
//                                             
//    Reg  DECLARATION                         
//                                             
// ******************************************** 
//ip stage 
reg   [1                 :0] part_ip               ;  //ip: datapath
reg   [1                 :0] subpart_ip            ;
reg                          half_flag_ip          ;
//satd stage
reg   [4                 :0] cmb_p_addr_o          ;
reg   [1                 :0] part_satd             ;//satd: datapath
reg   [1                 :0] subpart_satd          ;
reg                          half_flag_satd        ;
//bcs stage                                        
reg   [1                 :0] part_bcs              ;//bcs: best candidate select
reg   [1                 :0] subpart_bcs           ;
reg                          half_flag_bcs         ;

//state setting
reg                          start_rd              ;
reg   [1                 :0] part_rd               ;
reg   [1                 :0] subpart_rd            ;
reg   [4                 :0] rd_row_rd             ;
reg                          rd_blk_rd             ;
reg   [2                 :0] wr_fmv                ;
reg   [1                 :0] part_cn_rd            ;
reg   [1                 :0] subpart_cn_rd         ;

reg   [1                 :0] state, nextstate      ;

reg   [4                 :0] cmb_pixel,base_cmb_pixel;
reg                          end_rd_d              ;
// satd stage
reg   [2                 :0] satd_acc              ;
// satd gen
reg   [2                 :0] satd_4x4_cn           ;
reg                          satd_blk_valid        ;
// mv read                                         
reg   [3                 :0] mv_addr               ;
reg                          end_fme               ;

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter FME_IDLE    = 2'b00, FME_HALF_RD = 2'b01,
          FME_QUAR_RD = 2'b11;//, FME_MC_RD   = 2'b10;

// ********************************************
//                                             
//    FSM  Logic                  
//                                             
// ******************************************** 
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    state <= FME_IDLE;
  else
    state <= nextstate;
end

always @( * ) begin
  nextstate  = FME_IDLE;
  case(state)
    FME_IDLE:
      if(start_fme_i)
        nextstate = FME_HALF_RD;
      else
        nextstate = FME_IDLE;
    FME_HALF_RD:
      if(start_quar)
        nextstate = FME_QUAR_RD;
      else
        nextstate = FME_HALF_RD;
    FME_QUAR_RD:
      if(end_onesubpart)//结束其中一个块，一个partition或者一个sub-partition
       if(end_onemb)
         nextstate = FME_IDLE;
       else
         nextstate = FME_HALF_RD;
      else
        nextstate = FME_QUAR_RD;
    default:
      nextstate = FME_IDLE;
  endcase
end

// ******************************************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ******************************************************************

assign mb_type_rd       = mb_type_rd_i             ;
assign sub_mb_type_rd   = sub_mb_type_rd_i         ;
                                                   
assign mb_type_ip       = mb_type_ip_i             ;
                                                   
assign mb_type_satd     = mb_type_satd_i           ;
assign sub_mb_type_satd = sub_mb_type_satd_i       ;
                                                   
assign mb_type_bcs      = mb_type_bcs_i            ;
assign sub_mb_type_bcs  = sub_mb_type_bcs_i        ;


//******************************************************************
//
//  fetch controller
//
//******************************************************************
assign start_ft_o = start_fme_i;

//******************************************************************
//
//  state setting 
//
//******************************************************************

always @( * ) begin
  case(mb_type_rd)
    `P_L0_16x16: begin
      part_rd     = 2'd0;
      subpart_rd  = 2'd0;
      rd_row_rd   = 5'd21;
      rd_blk_rd   = 1'd1;
    end
    `P_L0_L0_16x8: begin
      part_rd     = 2'd1;
      subpart_rd  = 2'd0;
      rd_row_rd   = 5'd13;
      rd_blk_rd   = 1'd1;
    end
    `P_L0_L0_8x16: begin
      part_rd     = 2'd1;
      subpart_rd  = 2'd0;
      rd_row_rd   = 5'd21;
      rd_blk_rd   = 1'd0;
    end
    `P_8x8:  begin
      part_rd     = 2'd3;
      rd_blk_rd   = 1'd0;
      case(sub_mb_type_rd)
        `P_L0_8x8: begin
          subpart_rd = 2'd0;
          rd_row_rd  = 5'd13;
        end
        `P_L0_8x4: begin
          subpart_rd = 2'd1;
          rd_row_rd  = 5'd9;
        end
        `P_L0_4x8: begin
          subpart_rd = 2'd0;
          rd_row_rd  = 5'd13;
        end
        `P_L0_4x4: begin
          subpart_rd = 2'd1;
          rd_row_rd  = 5'd9;
        end
        default: begin
          subpart_rd = 2'd0;
          rd_row_rd  = 5'd0;
        end
      endcase
    end
    default:   begin
      part_rd    = 2'd0;
      subpart_rd = 2'd0;
      rd_row_rd  = 5'd0;
      rd_blk_rd  = 1'd0;
    end
  endcase
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    part_cn_rd <= 0;
  else
    if(end_onepart)
      if(part_cn_rd == part_rd)
        part_cn_rd <= 2'd0;
      else
        part_cn_rd <= part_cn_rd + 2'd1;
    else
      part_cn_rd   <= part_cn_rd;
end
assign part_cn_rd_o = part_cn_rd;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    subpart_cn_rd <= 0;
  else
    if(end_onesubpart)                //end_one_subpart每当做完一个MC之后，就应当是一个subpart结束的时候
      if(subpart_cn_rd == subpart_rd)
        subpart_cn_rd <= 2'd0;
      else
        subpart_cn_rd <= subpart_cn_rd + 2'd1;
    else
      subpart_cn_rd <= subpart_cn_rd;
end

assign end_onesubpart  = (state == FME_QUAR_RD) & end_rd_i               ;//
assign end_onepart     = end_onesubpart & (subpart_cn_rd == subpart_rd)  ;
assign end_onemb       = end_onepart & (part_cn_rd == part_rd)           ;
assign end_onemb_rd_o  = end_onemb                                       ;
assign updata_base_rd_o= end_onesubpart                                  ;

assign half_flag_rd    = (state == FME_HALF_RD);
assign start_quar      = (best_candi_i)&(half_flag_bcs);//
//|--HALF--|--QUART--|--HALF--|--QUART--|   --- half_flag_rd
//  |-HALF-|---QUART--|-HALF--|             --- half_flag_ip

always @( posedge clk_i or negedge rst_n_i ) begin
  if(!rst_n_i)
    start_rd <= 'b0;
  else
    start_rd <= start_fme_i | start_quar  | end_onesubpart &(!end_onemb);
end

assign start_rd_o  = start_rd            ;
assign rd_row_rd_o = rd_row_rd           ;
assign rd_blk_rd_o = rd_blk_rd           ;

//end loader control


//**********************************************************
//
//  datapath
// 
//**********************************************************

//IP stage
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    part_ip        <= 'b0;
    subpart_ip     <= 'b0;
  end
  else
    if(start_fme_i) begin
      part_ip       <= part_cn_rd;
      subpart_ip    <= subpart_cn_rd;
    end
    else
      if(end_oneblk_ip_i & (!half_flag_ip))
      begin
        part_ip      <= part_cn_rd;
        subpart_ip   <= subpart_cn_rd;
      end
end
assign part_cn_ip_o   = part_ip;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    half_flag_ip <= 1'b0;
  else
    if(start_fme_i & state == FME_IDLE)
      half_flag_ip <= 1'b1;
    else
      if(start_quar)
        half_flag_ip <= 1'b0;
      else
        if(end_oneblk_ip_i & (!half_flag_ip))
          half_flag_ip <= half_flag_rd;
        else
          half_flag_ip <= half_flag_ip;
end

assign half_flag_ip_o = half_flag_ip;

//**********************************************************
//                                                          
//  read cmb pixel
//                                                          
//**********************************************************

always @( posedge clk_i or negedge rst_n_i ) begin
  if(!rst_n_i) begin
    end_rd_d <= 1'b0;
  end
  else
    if(end_rd_i)
      end_rd_d <= 1'b1;
    else
      if(end_oneblk_ip_i)
        end_rd_d <= 1'b0;
end

assign    type_8x16 = (mb_type_ip == `P_L0_16x16 || mb_type_ip == `P_L0_L0_8x16);

always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    base_cmb_pixel <= 'b0;
  else
    if(end_oneblk_ip_i & !half_flag_ip)
      base_cmb_pixel <= cmb_pixel + 1'b1;
    else
      base_cmb_pixel <= base_cmb_pixel;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    cmb_pixel <= 'b0;
  end
  else
    if( candi_valid_i )
      if( half_flag_ip & end_oneblk_ip_i & end_rd_d)
        cmb_pixel <= base_cmb_pixel;
      else
        cmb_pixel <= cmb_pixel + 1'b1;
    else
      cmb_pixel <= cmb_pixel;
end

always @( * ) begin
  if(type_8x16)
    case(cmb_pixel[4:3])
      2'b01:
        cmb_p_addr_o = {2'b10,cmb_pixel[2:0]};
      2'b10:
        cmb_p_addr_o = {2'b01,cmb_pixel[2:0]};
      default:
        cmb_p_addr_o = cmb_pixel;
    endcase
  else
    cmb_p_addr_o = cmb_pixel;
end

//**********************************************************
//
//    satd stage
//                                                          
//**********************************************************

always @( * ) begin
  case(mb_type_satd)
    `P_L0_16x16: begin
      satd_acc = 3'd7;
    end
    `P_L0_L0_16x8: begin
      satd_acc = 3'd3;
    end
    `P_L0_L0_8x16: begin
      satd_acc = 3'd3;
    end
    `P_8x8:  begin
      case(sub_mb_type_satd)
        `P_L0_8x8: begin
          satd_acc = 3'd1;
        end
        `P_L0_8x4: begin
          satd_acc = 3'd0;
        end
        `P_L0_4x8: begin
          satd_acc = 3'd1;
        end
        `P_L0_4x4: begin
          satd_acc = 3'd0;
        end
        default: begin
          satd_acc = 3'd0;
        end
      endcase
    end
    default:   begin
      satd_acc = 3'd0;
    end
  endcase
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    half_flag_satd <= 1'b0;
  end
  else
    if(start_fme_i)
      half_flag_satd <= 1'b1;
    else
      if(start_quar)
        half_flag_satd <= 1'b0;
      else
        if(satd_blk_valid_o & !half_flag_satd)
          half_flag_satd <= half_flag_ip;
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    part_satd        <= 'b0;
    subpart_satd     <= 'b0;
  end
  else
    if(start_fme_i) begin
      part_satd       <= part_cn_rd;
      subpart_satd    <= subpart_cn_rd;
    end
    else
      if(satd_blk_valid_o & (!half_flag_satd))
      begin
        part_satd        <= part_ip;
        subpart_satd     <= subpart_ip;
      end
end
assign part_cn_satd_o   = part_satd;

assign working_mode_satd_o = !((mb_type_satd == `P_8x8) && ((sub_mb_type_satd == `P_L0_4x4)||(sub_mb_type_satd == `P_L0_4x8)));


//**********************************************************
//
//  satd gen
//                                                          
//**********************************************************
assign    satd_4x4_valid = satd_4x4_valid_i;
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    satd_4x4_cn <= 0;
  else
    if(satd_4x4_valid)
      if(satd_4x4_cn == satd_acc)
        satd_4x4_cn <= 0;
      else
        satd_4x4_cn <= satd_4x4_cn + 1'b1;
    else
      satd_4x4_cn <= satd_4x4_cn;
end
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    satd_blk_valid <= 1'b0;
  else
    satd_blk_valid <= satd_4x4_valid & (satd_4x4_cn == satd_acc);
end
assign satd_blk_valid_o = satd_blk_valid;

//**********************************************************
//
// best candidate select
//
//**********************************************************

always @(posedge clk_i or negedge rst_n_i) begin
   if(!rst_n_i)
     half_flag_bcs <= 'b0;
   else
     if(start_fme_i)
       half_flag_bcs <= 'b1;
     else
       if(start_quar)
         half_flag_bcs <= 'b0;
       else
         if(best_candi_i & (!half_flag_bcs))
           half_flag_bcs <= half_flag_satd;
end
assign half_flag_bcs_o = half_flag_bcs;


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    part_bcs        <= 'b0;
    subpart_bcs     <= 'b0;
  end
  else
    if(start_fme_i) begin
      part_bcs       <= part_cn_rd;
      subpart_bcs    <= subpart_cn_rd;
    end
    else
      if(best_candi_i & (!half_flag_bcs))
      begin
        part_bcs        <= part_satd;
        subpart_bcs     <= subpart_satd;
      end
end

assign part_cn_bcs_o     = part_bcs;
assign subpart_cn_bcs_o = subpart_bcs;

assign working_mode_bcs_o = !((mb_type_bcs == `P_8x8) && ((sub_mb_type_bcs == `P_L0_4x4)||(sub_mb_type_bcs == `P_L0_4x8)));

//imv read

always @( * ) begin
  case(mb_type_bcs)
    `P_L0_16x16:
      mv_addr = 0;
    `P_L0_L0_16x8:
      mv_addr = {part_bcs[0],3'b000};
    `P_L0_L0_8x16:
      mv_addr = {part_bcs,2'b00};
    `P_8x8:
      case(sub_mb_type_bcs)
        `P_L0_8x8:
          mv_addr = {part_bcs,2'b00};
        `P_L0_8x4:
          mv_addr = {part_bcs,2'b00} | {2'b00,subpart_bcs[0],1'b0};
        `P_L0_4x8:
          mv_addr = {part_bcs,2'b00};
        `P_L0_4x4:
          mv_addr = {part_bcs,2'b00} | {2'b00,subpart_bcs[0],1'b0};
        default:
          mv_addr = 0;
      endcase
    default:
      mv_addr = 0;
  endcase
end
assign imv_addr_o = mv_addr;

//**********************************************************
//
//   output
//
//**********************************************************

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_fme <= 1'b0;
  else
    end_fme <= best_candi_i & (state == FME_IDLE);//
end
assign end_fme_o = end_fme;

endmodule
