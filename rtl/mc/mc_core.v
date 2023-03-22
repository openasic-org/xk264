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
//                : Yufebg Bai
// Created        : 2011-03-15
// Description    :
//
//
// Modified       : 2013-09-06
//                  mc_pred_data_o is shared by luma & chroma;
//                  donnot need to save data in register. sent it to tq once finished
// $Id$
//-------------------------------------------------------------------
`include "enc_defines.v"

//Ä¿Ç°ÏÈ°Ñram²¿·Ö·Åµ½Íâ²¿£¬ÎªÁËDC£¬ÈôÊÇÓÃMCÉú³ÉRAMÖ®ºó£¬ÔÙ½«ram²¿·Ö¼ÓÉÏ£¬ÔÚDC
module mc_core(
       clk_i,
       rst_n_i,
//-----------------------------------------------------------------------------
//   settng parameters
//-----------------------------------------------------------------------------
       start_mc_i,
       done_mc_o,

       mb_type_info_i,
       fmv_i,
       imv_i,
//-----------------------------------------------------------------------------
//   load refpixel
//-----------------------------------------------------------------------------
       luma_rden_mc_o,
       luma_addr_mc_o,
       luma_data_mc_i,
       luma_rdack_mc_i,

       chroma_rden_mc_o  ,
       chroma_rddone_mc_o,
       chroma_rdcrcb_mc_o,
       chroma_rdack_mc_i ,
       chroma_rdsw_x_mc_o,
       chroma_rdsw_y_mc_o,
       chroma_rddata_mc_o,
//-----------------------------------------------------------------------------
//   to fme_ctrol
//-----------------------------------------------------------------------------
       mc_pred_data_o,
       mc_pred_addr_o,
       mc_pred_rdy_o
);


// ********************************************
//
//    INPUT / OUTPUT DECLARATION
//
// ********************************************
input                                clk_i;
input                                rst_n_i;
input [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] mb_type_info_i;
input [`BLK4X4_NUM*2*`FMVD_LEN-1:0]  fmv_i;
input [`BLK4X4_NUM*2*`IMVD_LEN-1:0]  imv_i;
input                                start_mc_i;
output                               done_mc_o;
output                               luma_rden_mc_o;
output [6:0]                         luma_addr_mc_o;
input  [20*`BIT_DEPTH-1:0]           luma_data_mc_i;
input                                luma_rdack_mc_i;
output                               chroma_rden_mc_o  ;
output                               chroma_rddone_mc_o;
output                               chroma_rdcrcb_mc_o;
input                                chroma_rdack_mc_i ;
output [`SW_W_LEN-1    :0]           chroma_rdsw_x_mc_o;
output [`SW_H_LEN-1    :0]           chroma_rdsw_y_mc_o;
input  [8*`BIT_DEPTH-1:0]            chroma_rddata_mc_o;
output [32*`BIT_DEPTH-1:0]           mc_pred_data_o;
output [3:              0]           mc_pred_addr_o;
output                               mc_pred_rdy_o;



// ********************************************
//
//    Parameter DECLARATION
//
// ********************************************


parameter MC_IDLE      = 2'b00;
parameter RUN_LUMA     = 2'b01;
parameter RUN_CHROMA   = 2'b10;




// ********************************************
//
//    Register DECLARATION
//
// ********************************************
reg  [2:0]  sub_mb_type_rd_luma, sub_mb_type_ip_luma, sub_mb_type_rd_chroma, sub_mb_type_ip_chroma;
reg  [`BLK4X4_NUM*2*`FMVD_LEN-1:0] fmv;
reg  [`BLK4X4_NUM*2*`IMVD_LEN-1:0] imv;
reg  [2*`FMVD_LEN-1            :0] fmv_r[`BLK4X4_NUM-1:0];
reg  [2*`IMVD_LEN-1            :0] imv_r[`BLK4X4_NUM-1:0];
reg  [6                        :0] rd_addr;
reg  [8*`BIT_DEPTH-1           :0] data_tq_o;
reg  [1                        :0] state, nextstate;

reg                                luma_rdy;
reg  [2                        :0] wr_cnt;
reg                                wr_cnt_tmp;
reg  [3                        :0] mc_pred_addr;
reg  [64*`BIT_DEPTH-1          :0] mc_pred_data;


// ********************************************
//
//    Wire DECLARATION
//
// ********************************************
wire [14 :0]  mb_type_info;
wire [2  :0]  mb_type;
wire [1  :0]  part_cn_rd_luma,   part_cn_ip_luma, part_cn_rd_chroma,part_cn_ip_chroma;
wire [1  :0]  subpart_cn_rd_luma,subpart_cn_ip_luma, subpart_cn_rd_chroma, subpart_cn_ip_chroma;

wire [2*`IMVD_LEN-1   :0] imv0, imv1, imv0_chroma, imv1_chroma;
wire [2*`FMVD_LEN-1   :0] fmv0, fmv1, fmv0_chroma, fmv1_chroma;
wire [`FMVD_LEN-1     :0] fmv0_x, fmv0_y, fmv1_x, fmv1_y;
wire [`IMVD_LEN-1     :0] imv0_x, imv0_y, imv1_x, imv1_y;
wire [1               :0] HFracl0_x, HFracl0_y, HFracl1_x, HFracl1_y;
wire [1               :0] QFracl0_x, QFracl0_y, QFracl1_x, QFracl1_y;
wire [1               :0] HFrac0_x_chroma, HFrac0_y_chroma, HFrac1_x_chroma, HFrac1_y_chroma;
wire [3               :0] fracl_addr_luma, fmv_addr_ldref_chroma, fmv_addr_ip_chroma;
wire                      rden;
wire                      end_onemb_luma, end_onemb_chroma;
wire                      launch_mc;
wire [20*`BIT_DEPTH-1 :0] refdata;
wire [3               :0] HFracl0,HFracl1, QFracl0, QFracl1;
wire [4*8*`BIT_DEPTH-1:0] luma_wrdata;
wire [2               :0] luma_wraddr;
wire                      luma_wren;
wire                      end_mc;

wire [8*8*`BIT_DEPTH-1:0] cbcr_wrdata;
wire [3               :0] HFrac0_chroma, HFrac1_chroma;
wire [2*`FMVD_LEN-1   :0] fmv0_ip_chroma,fmv1_ip_chroma,fmv0_ldref_chroma,fmv1_ldref_chroma;
wire [2*`IMVD_LEN-1   :0] imv0_rd_chroma,imv1_rd_chroma;

wire                      chroma_wraddr ;
wire                      chroma_wren   ;

wire                      launch_luma,launch_chroma;
wire                      chroma_rdy;
// ********************************************
//
//    Sequential Logic   Combinational Logic
//
// ********************************************
assign mb_type_info = mb_type_info_i;

//input parameters
assign mb_type     = mb_type_info[2:0];
always @( * ) begin
  case(part_cn_rd_luma)
    2'b00: sub_mb_type_rd_luma = mb_type_info[5:3];
    2'b01: sub_mb_type_rd_luma = mb_type_info[8:6];
    2'b10: sub_mb_type_rd_luma = mb_type_info[11:9];
    2'b11: sub_mb_type_rd_luma = mb_type_info[14:12];
    default: sub_mb_type_rd_luma = 0;
  endcase
end

always @( * ) begin
  case(part_cn_ip_luma)
    2'b00: sub_mb_type_ip_luma = mb_type_info[5:3];
    2'b01: sub_mb_type_ip_luma = mb_type_info[8:6];
    2'b10: sub_mb_type_ip_luma = mb_type_info[11:9];
    2'b11: sub_mb_type_ip_luma = mb_type_info[14:12];
    default: sub_mb_type_ip_luma = 0;
  endcase
end


//
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    fmv <= 'b0;
	imv <= 'b0;
  end
  else if(launch_mc) begin
    fmv <= fmv_i;
    imv <= imv_i;
  end
end


genvar n;
generate
  for(n=0; n<`BLK4X4_NUM; n=n+1) begin: fmvd_i
    always @( * )
      fmv_r[n] = fmv[(n+1)*2*`FMVD_LEN-1:n*2*`FMVD_LEN];
  end
endgenerate

genvar k;
generate
  for(k=0; k<`BLK4X4_NUM; k=k+1) begin: imvd_i
    always @( * )
      imv_r[k] = imv[(k+1)*2*`IMVD_LEN-1:k*2*`IMVD_LEN];
  end
endgenerate

assign imv0 = imv_r[fracl_addr_luma];
assign imv1 = imv_r[fracl_addr_luma+1];
assign fmv0 = fmv_r[fracl_addr_luma];
assign fmv1 = fmv_r[fracl_addr_luma+1];

assign imv0_x = imv0[`IMVD_LEN-1:0];
assign imv0_y = imv0[2*`IMVD_LEN-1:`IMVD_LEN];
assign imv1_x = imv1[`IMVD_LEN-1:0];
assign imv1_y = imv1[2*`IMVD_LEN-1:`IMVD_LEN];

assign fmv0_x = fmv0[`FMVD_LEN-1:0];
assign fmv0_y = fmv0[2*`FMVD_LEN-1:`FMVD_LEN];
assign fmv1_x = fmv1[`FMVD_LEN-1:0];
assign fmv1_y = fmv1[2*`FMVD_LEN-1:`FMVD_LEN];

assign HFracl0_x = (fmv0_x[`FMVD_LEN-1:2] == imv0_x)?((fmv0_x[1:0] == 2'b00)?{2'b00}:{2'b01}):{2'b11};
assign HFracl0_y = (fmv0_y[`FMVD_LEN-1:2] == imv0_y)?((fmv0_y[1:0] == 2'b00)?{2'b00}:{2'b01}):{2'b11};
assign HFracl1_x = (fmv1_x[`FMVD_LEN-1:2] == imv1_x)?((fmv1_x[1:0] == 2'b00)?{2'b00}:{2'b01}):{2'b11};
assign HFracl1_y = (fmv1_y[`FMVD_LEN-1:2] == imv1_y)?((fmv1_y[1:0] == 2'b00)?{2'b00}:{2'b01}):{2'b11};

assign QFracl0_x = (fmv0_x[1:0] == 2'b00)?fmv0_x[1:0]:{fmv0_x[1]^1'b1,fmv0_x[0]};
assign QFracl0_y = (fmv0_y[1:0] == 2'b00)?fmv0_y[1:0]:{fmv0_y[1]^1'b1,fmv0_y[0]};
assign QFracl1_x = (fmv1_x[1:0] == 2'b00)?fmv1_x[1:0]:{fmv1_x[1]^1'b1,fmv1_x[0]};
assign QFracl1_y = (fmv1_y[1:0] == 2'b00)?fmv1_y[1:0]:{fmv1_y[1]^1'b1,fmv1_y[0]};

assign HFracl0 = {HFracl0_y, HFracl0_x};
assign HFracl1 = {HFracl1_y, HFracl1_x};
assign QFracl0 = {QFracl0_y, QFracl0_x};
assign QFracl1 = {QFracl1_y, QFracl1_x};

//chroma
assign fmv0_ldref_chroma   = fmv_r[fmv_addr_ldref_chroma];
assign fmv1_ldref_chroma   = fmv_r[fmv_addr_ldref_chroma+1];

assign fmv0_ip_chroma      = fmv_r[fmv_addr_ip_chroma];
assign fmv1_ip_chroma      = fmv_r[fmv_addr_ip_chroma+1];


always @( * ) begin
  case(part_cn_rd_chroma)
    2'b00: sub_mb_type_rd_chroma = mb_type_info[5:3];
    2'b01: sub_mb_type_rd_chroma = mb_type_info[8:6];
    2'b10: sub_mb_type_rd_chroma = mb_type_info[11:9];
    2'b11: sub_mb_type_rd_chroma = mb_type_info[14:12];
    default: sub_mb_type_rd_chroma = 0;
  endcase
end


//-----------------------------------------------------------------------------
//       instantiate modules
//-----------------------------------------------------------------------------
assign launch_mc = start_mc_i;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    state <= MC_IDLE;
  else
    state <= nextstate;
end


always @( * ) begin
  case(state)
    MC_IDLE:
      if(launch_mc)
        nextstate = RUN_LUMA;
      else
        nextstate = MC_IDLE;
    RUN_LUMA:
      if(end_onemb_luma)
        nextstate = RUN_CHROMA;
      else
        nextstate = RUN_LUMA;
    RUN_CHROMA:
      if(end_onemb_chroma)
        nextstate = MC_IDLE;
      else
        nextstate = RUN_CHROMA;
    default:
      nextstate = MC_IDLE;
  endcase
end

assign end_mc = (state == RUN_CHROMA & end_onemb_chroma);

assign launch_luma    = launch_mc;
assign launch_chroma  = (state == RUN_LUMA & end_onemb_luma);

assign done_mc_o = end_mc ;

mc_luma_top mc_luma_top(
       .clk_i            ( clk_i          ),
       .rst_n_i          ( rst_n_i        ),
       .launch_mc_i      ( launch_luma    ),
       //read
       .empty_i          ( 1'b0           ),
       .luma_rden_mc_o   ( luma_rden_mc_o ),
       .luma_addr_mc_o   ( luma_addr_mc_o ),
       .luma_data_mc_i   ( luma_data_mc_i ),
       .luma_rdack_mc_i  ( luma_rdack_mc_i),
       //read Hfracl and Qfracl
       .fracl_addr_o     ( fracl_addr_luma),
       .HFracl0_i        ( HFracl0        ),
       .HFracl1_i        ( HFracl1        ),
       .QFracl0_i        ( QFracl0        ),
       .QFracl1_i        ( QFracl1        ),
       //read mb_type infor
       .mb_type_i        ( mb_type             ),
       .sub_mb_type_rd_i ( sub_mb_type_rd_luma ),
       .part_cn_rd_o     ( part_cn_rd_luma     ),
       .sub_mb_type_ip_i ( sub_mb_type_ip_luma ),
       .part_cn_ip_o     ( part_cn_ip_luma     ),
       // output
       .luma_end_onemb_o ( end_onemb_luma ),
       // output
       .luma_wren_o      ( luma_wren      ),
       .luma_wraddr_o    ( luma_wraddr    ),
       .luma_wrdata_o    ( luma_wrdata    )
);

mc_chroma_top mc_chroma_top(
       .clk_i            ( clk_i          ),
       .rst_n_i          ( rst_n_i        ),
       .launch_mc_i      ( launch_chroma  ),
       // read sub_type
       .mb_type_i        ( mb_type        ),
       .sub_mb_type_rd_i ( sub_mb_type_rd_chroma),
       .part_cn_rd_o     ( part_cn_rd_chroma),
       .end_onemb_chroma_o( end_onemb_chroma),
       // load refpixel
       .chroma_rden_mc_o  ( chroma_rden_mc_o   ),
       .chroma_rddone_mc_o( chroma_rddone_mc_o ),
       .chroma_rdcrcb_mc_o( chroma_rdcrcb_mc_o ),
       .chroma_rdack_mc_i ( chroma_rdack_mc_i  ),
       .chroma_rdsw_x_mc_o( chroma_rdsw_x_mc_o ),
       .chroma_rdsw_y_mc_o( chroma_rdsw_y_mc_o ),
       .chroma_rddata_mc_o( chroma_rddata_mc_o ),
       //read fmv and HFrac
       .fmv_addr_ldref_o  ( fmv_addr_ldref_chroma  ),
       .fmv0_ldref_i      ( fmv0_ldref_chroma      ),
       .fmv1_ldref_i      ( fmv1_ldref_chroma      ),
       .fmv_addr_ip_o     ( fmv_addr_ip_chroma     ),
       .fmv0_ip_i         ( fmv0_ip_chroma         ),
       .fmv1_ip_i         ( fmv1_ip_chroma         ),
       //
       .chroma_wraddr_o   ( chroma_wraddr          ),
       .chroma_wren_o     ( chroma_wren            ),

       .cbcr_wrdata_o     ( cbcr_wrdata            )

);


///////////////////////////////////////////////////////////////////////////////
//  write mc luma
//  Revised by Yufeng Bai on 2013-09-07
///////////////////////////////////////////////////////////////////////////////
always @(posedge clk_i or negedge rst_n_i) begin : proc_wrdata
   if(!rst_n_i) begin
     mc_pred_data <= 'd0;
   end
   else begin
     case({luma_wren,chroma_wren})
      2'b01:    mc_pred_data <= cbcr_wrdata;
      2'b10:    mc_pred_data <= {256'b0,luma_wrdata};
      default:  mc_pred_data <= mc_pred_data;
     endcase
   end
end



always @(posedge clk_i or negedge rst_n_i) begin
  if(~rst_n_i) begin
    luma_rdy  <= 'd0;
   end
  else begin
    if(luma_wren)
      luma_rdy  <= 1'b1;
    else
      luma_rdy  <= 1'b0;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
 if(~rst_n_i) begin
  mc_pred_addr <= 'd0;
 end
 else begin
  if(luma_wren | chroma_wren) begin
    mc_pred_addr <= (luma_wren) ? luma_wraddr : ((chroma_wraddr<<1) + 'd8);
  end
  else begin
    mc_pred_addr <= mc_pred_addr;
  end
 end
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(~rst_n_i) begin
    wr_cnt_tmp <= 1'b0;
  end
  else begin
    if(chroma_wren)
      wr_cnt_tmp   <= 1'b1;
    if(wr_cnt == 3'd4)
      wr_cnt_tmp   <= 1'b0;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(~rst_n_i) begin
    wr_cnt <= 'd0;
  end
  else begin
    if(wr_cnt_tmp)
      wr_cnt  <= wr_cnt +1'b1;
    else
      wr_cnt  <= 1'b0;
  end
end

assign chroma_rdy = (wr_cnt == 'd1 || wr_cnt == 'd5);

assign mc_pred_rdy_o = (luma_rdy | chroma_rdy);
assign mc_pred_data_o = (wr_cnt == 5) ?(mc_pred_data[64*`BIT_DEPTH-1:32*`BIT_DEPTH]) : (mc_pred_data[32*`BIT_DEPTH-1:0]);
assign mc_pred_addr_o = (wr_cnt == 5) ?(mc_pred_addr + 1'b1) : (mc_pred_addr);

endmodule
