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
// Filename       : coding_style_top.v
// Author         : fan yibo
// Created        : 2011-06-09
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//
// $Id$
//-------------------------------------------------------------------
`include "enc_defines.v"

module mc_top(
       clk_i,
       rst_n_i,
       sysif_start_mc_i,
       sysif_done_mc_o,
       sysif_cmb_luma_i,
       sysif_cmb_cb_i,
       sysif_cmb_cr_i,
       sysif_cmb_x_i,
       sysif_cmb_y_i,
       sysif_qp_i,
       sysif_transform8x8_mode_i,
       fmeif_mb_type_info_i,
       fmeif_fmv_i,
       fmeif_imv_i,
       fmeif_luma_rden_mc_o,
       fmeif_luma_addr_mc_o,
       fmeif_luma_data_mc_i,
       fmeif_luma_rdack_mc_i,
       fetchif_chroma_rden_mc_o  ,
       fetchif_chroma_rddone_mc_o,
       fetchif_chroma_rdcrcb_mc_o,
       fetchif_chroma_rdack_mc_i ,
       fetchif_chroma_rdmb_x_mc_o,
       fetchif_chroma_rdmb_y_mc_o,
       fetchif_chroma_rdsw_x_mc_o,
       fetchif_chroma_rdsw_y_mc_o,
       fetchif_chroma_rddata_mc_i,
       ecif_mb_type_info_o,
       ecif_sub_partition_o,
       tq_p16x16_en_o,
       tq_p16x16_num_o,
       tq_p16x16_val_i,
       tq_p16x16_num_i,
       tq_chroma_en_o,
       tq_chroma_num_o,
       tq_cb_val_i,
       tq_cb_num_i,
       tq_cr_val_i,
       tq_cr_num_i,

       pre00, pre01, pre02, pre03,
       pre10, pre11, pre12, pre13,
       pre20, pre21, pre22, pre23,
       pre30, pre31, pre32, pre33,
       res00, res01, res02, res03,
       res10, res11, res12, res13,
       res20, res21, res22, res23,
       res30, res31, res32, res33
);

// ********************************************
//
//    INPUT / OUTPUT DECLARATION
//
// ********************************************
input                                    clk_i;
input                                    rst_n_i;
// sys_if
input                                    sysif_start_mc_i;
output									 sysif_done_mc_o;
input  [256*`BIT_DEPTH-1:0]              sysif_cmb_luma_i;
input  [64 *`BIT_DEPTH-1:0]              sysif_cmb_cb_i;
input  [64 *`BIT_DEPTH-1:0]              sysif_cmb_cr_i;
input  [`PIC_W_MB_LEN-1 :0]              sysif_cmb_x_i;
input  [`PIC_H_MB_LEN-1 :0]              sysif_cmb_y_i;
input  [5               :0]              sysif_qp_i;
input                                    sysif_transform8x8_mode_i;
// fme_if
input  [`MB_TYPE_LEN+`BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] fmeif_mb_type_info_i;
input  [`BLK4X4_NUM*2*`FMVD_LEN-1:0]     fmeif_fmv_i;
input  [`BLK4X4_NUM*2*`IMVD_LEN-1:0]     fmeif_imv_i;
output                                   fmeif_luma_rden_mc_o;
output [6               :0]              fmeif_luma_addr_mc_o;
input  [20*`BIT_DEPTH-1 :0]              fmeif_luma_data_mc_i;
input                                    fmeif_luma_rdack_mc_i;
// fetch_if
output                                   fetchif_chroma_rden_mc_o  ;
output                                   fetchif_chroma_rddone_mc_o;
output                                   fetchif_chroma_rdcrcb_mc_o;
input                                    fetchif_chroma_rdack_mc_i ;
output [`PIC_W_MB_LEN-1:0]               fetchif_chroma_rdmb_x_mc_o;
output [`PIC_H_MB_LEN-1:0]               fetchif_chroma_rdmb_y_mc_o;
output [`SW_W_LEN-1    :0]               fetchif_chroma_rdsw_x_mc_o;
output [`SW_H_LEN-1    :0]               fetchif_chroma_rdsw_y_mc_o;
input [`BIT_DEPTH*8-1:0]                 fetchif_chroma_rddata_mc_i;
// ec if
output [1:0]    						 ecif_mb_type_info_o ;
output [7:0]    						 ecif_sub_partition_o;
// intra_tq if
output 									 tq_p16x16_en_o;
output [3:0] 							 tq_p16x16_num_o;
input 									 tq_p16x16_val_i;
input [3:0] 							 tq_p16x16_num_i;
output 									 tq_chroma_en_o;
output [2:0] 							 tq_chroma_num_o;
input 									 tq_cb_val_i;
input [3:0] 							 tq_cb_num_i;
input 									 tq_cr_val_i;
input [3:0] 							 tq_cr_num_i;

output [`BIT_DEPTH-1:0]					 pre00, pre01, pre02, pre03,
										 pre10, pre11, pre12, pre13,
										 pre20, pre21, pre22, pre23,
										 pre30, pre31, pre32, pre33;
output [`BIT_DEPTH:0]					 res00, res01, res02, res03,
										 res10, res11, res12, res13,
										 res20, res21, res22, res23,
										 res30, res31, res32, res33;

// ********************************************
//
//    Parameter DECLARATION
//
// ********************************************
//FSM
parameter	MC_IDLE     = 1'b0,
		   	MC_CORE_RUN = 1'b1;

// ********************************************
//
//    Register DECLARATION
//
// ********************************************
reg [14:0]  				mb_type_info;
reg [4:0]					mc_cnt_r	, tq_cnt_r	    ;
reg							/*mc_p16x16_en,*/ tq_p16x16_en_o;
reg 						/*mc_chroma_en,*/ tq_chroma_en_o;
reg [16*(`BIT_DEPTH+1)-1:0] res_r;
reg							mc_done_r;
reg							mc_run_r;

reg             mc_en_r;

// ********************************************
//
//    Wire DECLARATION
//
// ********************************************
reg  [`PIC_W_MB_LEN-1    :0]  cmb_x;
reg  [`PIC_H_MB_LEN-1    :0]  cmb_y;
reg  [`BIT_DEPTH*32-1    :0]  cmb_pixel[11:0];
reg  [8*32*`BIT_DEPTH-1  :0]  cmb_luma;
//reg  [32*`BIT_DEPTH-1    :0]  mc_pred[11:0];
reg  [32*`BIT_DEPTH-1    :0]  mc_pred;
reg  [16*(`BIT_DEPTH+1)-1:0]  res;

wire                          start_mc_core, done_mc_core;
wire [32*`BIT_DEPTH-1   :0]   cmb_pixel_32, pred_pixel_32, pred_pixel_32_rec;
wire [16*`BIT_DEPTH-1   :0]   cmb_pixel_16, pred_pixel_16, pred_pixel_16_rec;



wire [32*`BIT_DEPTH-1   :0]   mc_pred_data_w;
wire [3                 :0]   mc_pred_addr_w;
wire                          mc_pred_rdy_w;
// ********************************************
//
//     Logic  Definition
//
// ********************************************
//----------------------------------------------------------
//                         Output
//----------------------------------------------------------
assign start_mc_core   = sysif_start_mc_i;
assign sysif_done_mc_o = mc_done_r;


// TQ IF
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        mc_run_r <= 1'b0;
    else if (mc_done_r)
        mc_run_r <= 1'b0;
    else if (sysif_start_mc_i)
        mc_run_r <= 'b1;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
        mc_done_r <= 1'b0;
    else if (mc_done_r)
        mc_done_r <= 1'b0;
    else if (tq_cr_val_i && (tq_cr_num_i==3'd3) && mc_run_r)
        mc_done_r <= 'b1;
end

always @(posedge clk_i or negedge rst_n_i) begin
    if(!rst_n_i)
        res_r <= 'd0;
    else
        res_r <= res;
end

assign  {pre00, pre01, pre02, pre03,
     pre10, pre11, pre12, pre13,
     pre20, pre21, pre22, pre23,
     pre30, pre31, pre32, pre33} = pred_pixel_16_rec;
assign  {res00, res01, res02, res03,
         res10, res11, res12, res13,
         res20, res21, res22, res23,
         res30, res31, res32, res33} = res_r;


always @(posedge clk_i or negedge rst_n_i) begin
  if (!rst_n_i)
    mc_cnt_r <= 'b0;
  else if (mc_pred_rdy_w)
    mc_cnt_r <= mc_pred_addr_w <<1;
  else if (mc_cnt_r == 'd23)
    mc_cnt_r <= 'd0;
  else if (mc_en_r)
    mc_cnt_r <= mc_cnt_r + 1'b1;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if (!rst_n_i)
    mc_en_r <= 'b0;
  else if (mc_pred_rdy_w)
    mc_en_r <= 1'b1;
  else if (mc_cnt_r[0])
    mc_en_r <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    tq_cnt_r        <= 'd0;
    tq_p16x16_en_o  <= 1'b0;
    tq_chroma_en_o  <= 1'b0;
  end
  else begin
    tq_cnt_r        <= mc_cnt_r; // delay 1 cycle
    tq_p16x16_en_o  <= mc_en_r & (mc_cnt_r <  'd16);// delay 1 cycle
    tq_chroma_en_o  <= mc_en_r & (mc_cnt_r >= 'd16);// delay 1 cycle
  end
end

assign tq_p16x16_num_o = tq_cnt_r[3:0];
assign tq_chroma_num_o = tq_cnt_r[2:0];

//----------------------------------------------------------
//                  INPUT Pixel Assignment
//----------------------------------------------------------
//cmb xy
always @( * ) begin
    cmb_x = sysif_cmb_x_i;
    cmb_y = sysif_cmb_y_i;
end

//cmb
genvar x,y,z,i;
generate
  for(x=0; x<8; x=x+1) begin: x_n
    for(i=0; i<4; i=i+1) begin: i_n
      always @( * ) begin
        cmb_luma[(x*32*`BIT_DEPTH) + ((i+1)*8*`BIT_DEPTH)-1:(x*32*`BIT_DEPTH) + (i*8*`BIT_DEPTH)] =
        sysif_cmb_luma_i[((((x/4)*8+(x%2)*4+i)*16) + ((x/2)%2)*8 + 8)*`BIT_DEPTH-1:
                         ((((x/4)*8+(x%2)*4+i)*16) + ((x/2)%2)*8    )*`BIT_DEPTH ];
      end
    end

    always @( * ) begin
        cmb_pixel[x] = cmb_luma[(x+1)*32*`BIT_DEPTH-1:x*32*`BIT_DEPTH];
    end
  end
endgenerate


generate
  for(y=0; y<2; y=y+1) begin: y_n
    always @(*) begin
        cmb_pixel[y+8]  = sysif_cmb_cb_i[(y+1)*32*`BIT_DEPTH-1:y*32*`BIT_DEPTH];
        cmb_pixel[y+10] = sysif_cmb_cr_i[(y+1)*32*`BIT_DEPTH-1:y*32*`BIT_DEPTH];
    end
  end
endgenerate


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mb_type_info <= 0;
  else if(sysif_start_mc_i)
    mb_type_info <= fmeif_mb_type_info_i;
end

assign ecif_mb_type_info_o  =  mb_type_info[1:0];
assign ecif_sub_partition_o = {mb_type_info[13:12],
							   mb_type_info[10:9] ,
							   mb_type_info[7:6]  ,
							   mb_type_info[4:3] };

//----------------------------------------------------------
//                  u_mc_core
//----------------------------------------------------------
assign fetchif_chroma_rdmb_x_mc_o = cmb_x;
assign fetchif_chroma_rdmb_y_mc_o = cmb_y;

mc_core u_mc_core(
       .clk_i             ( clk_i                   ),
       .rst_n_i           ( rst_n_i                 ),
       .start_mc_i        ( start_mc_core           ),
       .done_mc_o         ( done_mc_core            ),
       .mb_type_info_i    ( mb_type_info            ),
       .fmv_i             ( fmeif_fmv_i             ),
       .imv_i             ( fmeif_imv_i             ),

       .luma_rden_mc_o    ( fmeif_luma_rden_mc_o    ),
       .luma_addr_mc_o    ( fmeif_luma_addr_mc_o    ),
       .luma_data_mc_i    ( fmeif_luma_data_mc_i    ),
       .luma_rdack_mc_i   ( fmeif_luma_rdack_mc_i   ),

       .chroma_rden_mc_o  ( fetchif_chroma_rden_mc_o  ),
       .chroma_rddone_mc_o( fetchif_chroma_rddone_mc_o),
       .chroma_rdcrcb_mc_o( fetchif_chroma_rdcrcb_mc_o),
       .chroma_rdack_mc_i ( fetchif_chroma_rdack_mc_i ),
       .chroma_rdsw_x_mc_o( fetchif_chroma_rdsw_x_mc_o),
       .chroma_rdsw_y_mc_o( fetchif_chroma_rdsw_y_mc_o),
       .chroma_rddata_mc_o( fetchif_chroma_rddata_mc_i),

       .mc_pred_data_o    ( mc_pred_data_w            ),
       .mc_pred_addr_o    ( mc_pred_addr_w            ),
       .mc_pred_rdy_o     ( mc_pred_rdy_w             )
);

//----------------------------------------------------------
//                  OUTPUT data assignment
//                        32p => 16p
//          mc_core                    intra_tq core
//     8x4 block (32 pixel)         4x4 block (16 pixel)
//----------------------------------------------------------


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    mc_pred <= 'd0;
  end
  else if(mc_pred_rdy_w)
    mc_pred <= mc_pred_data_w;
end


assign cmb_pixel_32      = cmb_pixel[mc_cnt_r[4:1]];
assign pred_pixel_32     = mc_pred;
assign pred_pixel_32_rec = mc_pred;

assign cmb_pixel_16 =  (~mc_cnt_r[0])?
											{	cmb_pixel_32[(1+8*0+4*0)*`BIT_DEPTH-1:(0+8*0+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*0+4*0)*`BIT_DEPTH-1:(1+8*0+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*0+4*0)*`BIT_DEPTH-1:(2+8*0+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*0+4*0)*`BIT_DEPTH-1:(3+8*0+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*1+4*0)*`BIT_DEPTH-1:(0+8*1+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*1+4*0)*`BIT_DEPTH-1:(1+8*1+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*1+4*0)*`BIT_DEPTH-1:(2+8*1+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*1+4*0)*`BIT_DEPTH-1:(3+8*1+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*2+4*0)*`BIT_DEPTH-1:(0+8*2+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*2+4*0)*`BIT_DEPTH-1:(1+8*2+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*2+4*0)*`BIT_DEPTH-1:(2+8*2+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*2+4*0)*`BIT_DEPTH-1:(3+8*2+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*3+4*0)*`BIT_DEPTH-1:(0+8*3+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*3+4*0)*`BIT_DEPTH-1:(1+8*3+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*3+4*0)*`BIT_DEPTH-1:(2+8*3+4*0)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*3+4*0)*`BIT_DEPTH-1:(3+8*3+4*0)*`BIT_DEPTH]}
											  :{cmb_pixel_32[(1+8*0+4*1)*`BIT_DEPTH-1:(0+8*0+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*0+4*1)*`BIT_DEPTH-1:(1+8*0+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*0+4*1)*`BIT_DEPTH-1:(2+8*0+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*0+4*1)*`BIT_DEPTH-1:(3+8*0+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*1+4*1)*`BIT_DEPTH-1:(0+8*1+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*1+4*1)*`BIT_DEPTH-1:(1+8*1+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*1+4*1)*`BIT_DEPTH-1:(2+8*1+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*1+4*1)*`BIT_DEPTH-1:(3+8*1+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*2+4*1)*`BIT_DEPTH-1:(0+8*2+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*2+4*1)*`BIT_DEPTH-1:(1+8*2+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*2+4*1)*`BIT_DEPTH-1:(2+8*2+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*2+4*1)*`BIT_DEPTH-1:(3+8*2+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(1+8*3+4*1)*`BIT_DEPTH-1:(0+8*3+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(2+8*3+4*1)*`BIT_DEPTH-1:(1+8*3+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(3+8*3+4*1)*`BIT_DEPTH-1:(2+8*3+4*1)*`BIT_DEPTH],
												cmb_pixel_32[(4+8*3+4*1)*`BIT_DEPTH-1:(3+8*3+4*1)*`BIT_DEPTH]};



assign pred_pixel_16 = (~mc_cnt_r[0])?
											{	pred_pixel_32[(1+8*0+4*0)*`BIT_DEPTH-1:(0+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32[(2+8*0+4*0)*`BIT_DEPTH-1:(1+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32[(3+8*0+4*0)*`BIT_DEPTH-1:(2+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32[(4+8*0+4*0)*`BIT_DEPTH-1:(3+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32[(1+8*1+4*0)*`BIT_DEPTH-1:(0+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32[(2+8*1+4*0)*`BIT_DEPTH-1:(1+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32[(3+8*1+4*0)*`BIT_DEPTH-1:(2+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32[(4+8*1+4*0)*`BIT_DEPTH-1:(3+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32[(1+8*2+4*0)*`BIT_DEPTH-1:(0+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32[(2+8*2+4*0)*`BIT_DEPTH-1:(1+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32[(3+8*2+4*0)*`BIT_DEPTH-1:(2+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32[(4+8*2+4*0)*`BIT_DEPTH-1:(3+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32[(1+8*3+4*0)*`BIT_DEPTH-1:(0+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32[(2+8*3+4*0)*`BIT_DEPTH-1:(1+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32[(3+8*3+4*0)*`BIT_DEPTH-1:(2+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32[(4+8*3+4*0)*`BIT_DEPTH-1:(3+8*3+4*0)*`BIT_DEPTH]}
											  :{pred_pixel_32[(1+8*0+4*1)*`BIT_DEPTH-1:(0+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32[(2+8*0+4*1)*`BIT_DEPTH-1:(1+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32[(3+8*0+4*1)*`BIT_DEPTH-1:(2+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32[(4+8*0+4*1)*`BIT_DEPTH-1:(3+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32[(1+8*1+4*1)*`BIT_DEPTH-1:(0+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32[(2+8*1+4*1)*`BIT_DEPTH-1:(1+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32[(3+8*1+4*1)*`BIT_DEPTH-1:(2+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32[(4+8*1+4*1)*`BIT_DEPTH-1:(3+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32[(1+8*2+4*1)*`BIT_DEPTH-1:(0+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32[(2+8*2+4*1)*`BIT_DEPTH-1:(1+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32[(3+8*2+4*1)*`BIT_DEPTH-1:(2+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32[(4+8*2+4*1)*`BIT_DEPTH-1:(3+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32[(1+8*3+4*1)*`BIT_DEPTH-1:(0+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32[(2+8*3+4*1)*`BIT_DEPTH-1:(1+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32[(3+8*3+4*1)*`BIT_DEPTH-1:(2+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32[(4+8*3+4*1)*`BIT_DEPTH-1:(3+8*3+4*1)*`BIT_DEPTH]};

assign pred_pixel_16_rec = (~tq_cnt_r[0])?
											{	pred_pixel_32_rec[(1+8*0+4*0)*`BIT_DEPTH-1:(0+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*0+4*0)*`BIT_DEPTH-1:(1+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*0+4*0)*`BIT_DEPTH-1:(2+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*0+4*0)*`BIT_DEPTH-1:(3+8*0+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*1+4*0)*`BIT_DEPTH-1:(0+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*1+4*0)*`BIT_DEPTH-1:(1+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*1+4*0)*`BIT_DEPTH-1:(2+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*1+4*0)*`BIT_DEPTH-1:(3+8*1+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*2+4*0)*`BIT_DEPTH-1:(0+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*2+4*0)*`BIT_DEPTH-1:(1+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*2+4*0)*`BIT_DEPTH-1:(2+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*2+4*0)*`BIT_DEPTH-1:(3+8*2+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*3+4*0)*`BIT_DEPTH-1:(0+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*3+4*0)*`BIT_DEPTH-1:(1+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*3+4*0)*`BIT_DEPTH-1:(2+8*3+4*0)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*3+4*0)*`BIT_DEPTH-1:(3+8*3+4*0)*`BIT_DEPTH]}
											  :{pred_pixel_32_rec[(1+8*0+4*1)*`BIT_DEPTH-1:(0+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*0+4*1)*`BIT_DEPTH-1:(1+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*0+4*1)*`BIT_DEPTH-1:(2+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*0+4*1)*`BIT_DEPTH-1:(3+8*0+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*1+4*1)*`BIT_DEPTH-1:(0+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*1+4*1)*`BIT_DEPTH-1:(1+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*1+4*1)*`BIT_DEPTH-1:(2+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*1+4*1)*`BIT_DEPTH-1:(3+8*1+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*2+4*1)*`BIT_DEPTH-1:(0+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*2+4*1)*`BIT_DEPTH-1:(1+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*2+4*1)*`BIT_DEPTH-1:(2+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*2+4*1)*`BIT_DEPTH-1:(3+8*2+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(1+8*3+4*1)*`BIT_DEPTH-1:(0+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(2+8*3+4*1)*`BIT_DEPTH-1:(1+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(3+8*3+4*1)*`BIT_DEPTH-1:(2+8*3+4*1)*`BIT_DEPTH],
												pred_pixel_32_rec[(4+8*3+4*1)*`BIT_DEPTH-1:(3+8*3+4*1)*`BIT_DEPTH]};

genvar j;
generate
for(j=0; j<16; j=j+1) begin: j_n //reduced from 32 to 16!
  always @( * )
    res[(j+1)*(`BIT_DEPTH+1)-1:(j)*(`BIT_DEPTH+1)] = cmb_pixel_16[(j+1)*`BIT_DEPTH-1:j*`BIT_DEPTH]
                                                     - pred_pixel_16[(j+1)*`BIT_DEPTH-1:j*`BIT_DEPTH];
end
endgenerate


endmodule
