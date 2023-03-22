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
//                  Yufeng Bai
// Created        : 2011-03-15
// Description    :
//
//
//
// $Id$

// Modified       : 2013-09-02
// Seperate cb/cr interpolation to save area
//-------------------------------------------------------------------
`include "enc_defines.v"

//????ram?????????DC????MC??RAM?????ram??????DC
module mc_chroma_top(
       clk_i,
       rst_n_i,
       launch_mc_i,
       //read sub_type
       mb_type_i,
       sub_mb_type_rd_i,
       part_cn_rd_o,
       end_onemb_chroma_o,
       //   load refpixel
       chroma_rden_mc_o  ,
       chroma_rddone_mc_o,
       chroma_rdcrcb_mc_o, //specify read cr/cb, 0:cb;1:cr
       chroma_rdack_mc_i ,
       chroma_rdsw_x_mc_o,
       chroma_rdsw_y_mc_o,
       chroma_rddata_mc_o,
       //read fmv and HFrac
	     fmv_addr_ldref_o,
       fmv0_ldref_i,
       fmv1_ldref_i,
       fmv_addr_ip_o,
       fmv0_ip_i,
       fmv1_ip_i,
       //
       chroma_wraddr_o,
       chroma_wren_o,
       cbcr_wrdata_o     //chroma data output
);

// ********************************************
//
//    INPUT / OUTPUT DECLARATION
//
// ********************************************
input                            clk_i;
input                            rst_n_i;
input                            launch_mc_i;
input   [2                 :0]   mb_type_i;
input   [2                 :0]   sub_mb_type_rd_i;
output  [1                 :0]   part_cn_rd_o;
output                           end_onemb_chroma_o;
output                           chroma_rden_mc_o  ;
output                           chroma_rddone_mc_o;
output                           chroma_rdcrcb_mc_o;
input                            chroma_rdack_mc_i ;
output  [`SW_W_LEN-1       :0]   chroma_rdsw_x_mc_o;
output  [`SW_H_LEN-1       :0]   chroma_rdsw_y_mc_o;
input   [8*`BIT_DEPTH-1   :0]   chroma_rddata_mc_o; // 16 -> 8
output  [3                 :0]   fmv_addr_ldref_o;
input   [2*`FMVD_LEN-1    :0]   fmv0_ldref_i;
input   [2*`FMVD_LEN-1    :0]   fmv1_ldref_i;
output  [3                 :0]   fmv_addr_ip_o;
input   [2*`FMVD_LEN-1    :0]   fmv0_ip_i;
input   [2*`FMVD_LEN-1    :0]   fmv1_ip_i;
output                           chroma_wraddr_o;
output                           chroma_wren_o;

output  [64*`BIT_DEPTH-1     :0]   cbcr_wrdata_o;


// ********************************************
//
//    Register DECLARATION
//
// ********************************************
reg                              blk_cn_rd;
reg     [1:0]                    subpart_cn_rd;
reg     [1:0]                    part_cn_rd;
reg     [4:0]                    addr_cn;
reg     [3:0]                    frac_addr;
reg                              chroma_wren_o;
reg     [1:0]                    state, nextstate;
reg     [3:0]                    row_rd;
reg     [1:0]                    part_rd;
reg     [1:0]                    subpart_rd;
reg                              uv_blk2xn_switch;
reg  signed [3:0]                row_cn;
reg  signed [2:0]                col_cn;
reg                              input_v;
reg                              end_oneblk_d0,end_oneblk_d1;
reg         [2:0]                x_mod8;
reg         [2:0]                cnt_data;
reg                              next_row_d;
reg                              working_mode_d0,working_mode_d1;
reg                              ref_valid_d;

reg    [11*`BIT_DEPTH-1 :0]      chroma_data_i;       //use one chroma_data to replace chroma_data & cr_data
reg    [`BIT_DEPTH-1    :0]      chroma_data[11:0];
reg    [3:0]                     mc_pixel;

reg    [4*`BIT_DEPTH-1:0]        chroma_frac[15:0]; //use one chroma_frac to replace chroma_data & cr_data
reg                              wr_cnt;

reg                              chroma_ip; //chroma_interpolation 0:cb, 1:cr



// ********************************************
//
//    Wire DECLARATION
//
// ********************************************
wire    [2:0]                    limit;
wire                             end_onemb;
wire                             end_oneblk;
wire                             working_mode;
wire signed [`FMVD_LEN-1 :0]     mv_y, mv_x;
wire signed [2           :0]     uv_blk_x, uv_blk_y;
wire signed [`IMVD_LEN+1 :0]     sr_hor_tmp, sr_ver_tmp;
wire signed [`FMVD_LEN   :0]     mv_x_pad_tmp;
wire signed [`FMVD_LEN   :0]     mv_y_pad_tmp;
wire signed [`IMVD_LEN-1 :0]     mv_x_pad;
wire signed [`IMVD_LEN-1 :0]     mv_y_pad;
wire signed [`SW_W_LEN-1 :0]     motionblk_x;
wire signed [`SW_H_LEN-1 :0]     motionblk_y;
wire signed [`SW_W_LEN-1 :0]     pixel_x;
wire signed [`SW_H_LEN-1 :0]     pixel_y;
wire                             end_onerow;
wire                             next_row;
wire                             type_8x16;

wire  end_onesubpart ;
wire  end_onepart    ;
wire  end_oneblk_rd  ;
wire  end_oneblk_ip  ;
wire  frac_cb_v      ;
wire  frac_cr_v      ;

wire        [`BIT_DEPTH-1:0]     chroma_ref0_p0, chroma_ref0_p1, chroma_ref0_p2;
wire        [`BIT_DEPTH-1:0]     chroma_ref1_p0, chroma_ref1_p1, chroma_ref1_p2;
wire        [`BIT_DEPTH-1:0]     frac_chroma_p0, frac_chroma_p1, frac_chroma_p2, frac_chroma_p3;
wire                             frac_chroma_v;

// ********************************************
//
//    Parameter DECLARATION
//
// ********************************************
//FSM
parameter MC_IDLE = 2'b00;
parameter MC_WAIT = 2'b01;
parameter MC_RUN  = 2'b11;



// ********************************************
//
//    Sequential Logic   Combinational Logic
//
// ********************************************
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    state <= MC_IDLE;
  else
    state <= nextstate;
end

always @( * ) begin
  case( state )
    MC_IDLE:
      if(launch_mc_i)
        nextstate = MC_RUN;
      else
        nextstate = MC_IDLE;
    MC_WAIT:
      nextstate = MC_RUN;
    MC_RUN:
      if(end_oneblk)
        if(end_onemb)
          nextstate = MC_IDLE;
        else
          nextstate = MC_WAIT;
      else
        nextstate = MC_RUN;
    default:
      nextstate = MC_IDLE;
  endcase
end


always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16  : begin  row_rd = 4'd8; part_rd = 2'd1; subpart_rd = 2'd0; end
    `P_L0_L0_8x16: begin  row_rd = 4'd8; part_rd = 2'd1; subpart_rd = 2'd0; end
    `P_L0_L0_16x8: begin  row_rd = 4'd4; part_rd = 2'd3; subpart_rd = 2'd0; end //partition into 8x8
    `P_8x8: begin
      part_rd = 2'd3;
      case(sub_mb_type_rd_i)
        `P_L0_8x8: begin  row_rd = 4'd4; subpart_rd = 2'd0; end
        `P_L0_8x4: begin  row_rd = 4'd2; subpart_rd = 2'd1; end
        `P_L0_4x8: begin  row_rd = 4'd4; subpart_rd = 2'd0; end
        `P_L0_4x4: begin  row_rd = 4'd2; subpart_rd = 2'd1; end
        default:   begin  row_rd = 4'd0; subpart_rd = 2'd0; end
      endcase
    end
    default: begin part_rd = 2'd0; subpart_rd = 2'd0; row_rd = 2'd0; end
  endcase
end

always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16  : frac_addr = 0;
    `P_L0_L0_16x8: frac_addr = {part_cn_rd,2'b00};
    `P_L0_L0_8x16: frac_addr = {part_cn_rd,2'b00};
    `P_8x8: case(sub_mb_type_rd_i)
			`P_L0_8x8: frac_addr = {part_cn_rd,2'b00};
			`P_L0_8x4: frac_addr = {part_cn_rd,2'b00} | {2'b00,subpart_cn_rd[0],1'b0};
			`P_L0_4x8: frac_addr = {part_cn_rd,2'b00};
			`P_L0_4x4: frac_addr = {part_cn_rd,2'b00} | {2'b00,subpart_cn_rd[0],1'b0};
			default: frac_addr = 0;
		endcase
    default: frac_addr = 0;
  endcase
end

assign fmv_addr_ldref_o = frac_addr;

//=============================================================================
// prepare rd address
//=============================================================================

assign working_mode = !((mb_type_i ==`P_8x8)&((sub_mb_type_rd_i ==`P_L0_4x4)
					||(sub_mb_type_rd_i== `P_L0_4x8)));//1 for 8x8; 0 for 4x4
assign limit        = (working_mode)?2'd3:3'd5;//8x8: 8-5; 4x4: 8-3

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    uv_blk2xn_switch <= 'd0;
  else
    if(end_onerow & !working_mode)
      uv_blk2xn_switch <= ~uv_blk2xn_switch;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    row_cn <= 'd0;
  end
  else if(next_row)
    if(row_cn == row_rd)
      row_cn <= 'd0;
    else
      row_cn <= row_cn + 1'b1;
end

wire [3:0] col_cn_tmp;
assign col_cn_tmp = col_cn + (4'd8 - pixel_x[2:0]);
always @( posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    col_cn <= 'd0;
  else
    if(chroma_rdack_mc_i)
      if(end_onerow)
        col_cn <= 'd0;
      else
        col_cn <= col_cn_tmp[2:0];
    else
      col_cn <= col_cn;
end

assign end_onerow = chroma_rdack_mc_i & ( pixel_x[2:0] < limit);
assign next_row   = (working_mode)?end_onerow : (uv_blk2xn_switch & end_onerow);

assign end_onesubpart = next_row & (row_cn == row_rd);
assign end_oneblk     = end_onesubpart;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    subpart_cn_rd <= 2'b0;
  end
  else
    if(end_onesubpart)
      if(subpart_cn_rd == subpart_rd)
        subpart_cn_rd <= 2'b0;
      else
        subpart_cn_rd <= subpart_cn_rd + 1'b1;
    else
      subpart_cn_rd <= subpart_cn_rd;
end

assign end_onepart = (subpart_cn_rd == subpart_rd) & end_onesubpart;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    part_cn_rd <= 2'd0;
  end
  else
    if(end_onepart)
      if(part_cn_rd == part_rd)
        part_cn_rd <= 2'd0;
      else
        part_cn_rd <= part_cn_rd + 1'b1;
    else
      part_cn_rd <= part_cn_rd;
end
assign part_cn_rd_o = part_cn_rd;



assign end_onemb = end_onepart & (part_cn_rd == part_rd) & (chroma_ip == 1'b1);


always @(posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i) begin
  chroma_ip <= 1'd0;
end
else
  if(end_onepart && (part_cn_rd == part_rd)) begin
    if(chroma_ip == 1'd1)
      chroma_ip <= 1'd0;
    else
      chroma_ip <= chroma_ip + 1'b1;
  end
end

//read reference
assign chroma_rden_mc_o   = (state == MC_RUN);

//read cr/cr
assign chroma_rdcrcb_mc_o = chroma_ip;

//read done
assign chroma_rddone_mc_o = end_onemb;

//addr calculation
assign {mv_y, mv_x}          = uv_blk2xn_switch? fmv1_ldref_i:fmv0_ldref_i;
assign uv_blk_x              = {part_cn_rd[0],   2'b00}|{uv_blk2xn_switch,  1'b0};
assign uv_blk_y              = {part_cn_rd[1],   2'b00}|{subpart_cn_rd[0],  1'b0};

assign sr_hor_tmp            = (8'd`SR_HOR<<2'd2);
assign sr_ver_tmp            = ((8'd`SR_VER + 2'd3)<<2'd2);

assign mv_x_pad_tmp          = {mv_x[`FMVD_LEN-1],mv_x} + sr_hor_tmp ;
assign mv_y_pad_tmp          = {mv_y[`FMVD_LEN-1],mv_y} + sr_ver_tmp ; // + ('d3<<2);

assign mv_x_pad              = mv_x_pad_tmp[8:3];
assign mv_y_pad              = mv_y_pad_tmp[8:3];

assign motionblk_x           = {1'b0,uv_blk_x} + mv_x_pad;
assign motionblk_y           = {1'b0,uv_blk_y} + mv_y_pad;

assign pixel_x               = motionblk_x + {1'b0,col_cn};
assign pixel_y               = motionblk_y + {1'b0,row_cn};
assign chroma_rdsw_x_mc_o    = pixel_x;
assign chroma_rdsw_y_mc_o    = pixel_y;

//read input


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    input_v       <= 'd0;
    end_oneblk_d0 <= 'd0;
    end_oneblk_d1 <= 'd0;
    next_row_d    <= 'd0;
  end
  else begin
    input_v       <= chroma_rdack_mc_i;
    end_oneblk_d0 <= end_oneblk;
    end_oneblk_d1 <= end_oneblk_d0;
    next_row_d    <= next_row;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    x_mod8 <= 'd0;
  else
    if(chroma_rdack_mc_i)
      x_mod8 <= pixel_x[2:0];
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    cnt_data <= 'd0;
  else
    if(input_v)
      if(next_row_d)
        cnt_data <= 'd0;
      else
        cnt_data <= col_cn + ((uv_blk2xn_switch)?2'd3:2'd0);
    else
      cnt_data <= cnt_data;
end


integer x;
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    for(x=0; x<11; x=x+1) begin
      chroma_data[x] <= 'd0;
    end
  end
  else begin
    if(input_v) begin
      case(x_mod8)
        3'b000:
          {chroma_data[cnt_data+7],
           chroma_data[cnt_data+6],
           chroma_data[cnt_data+5],
           chroma_data[cnt_data+4],
           chroma_data[cnt_data+3],
           chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o;
        3'b001:
          {chroma_data[cnt_data+6],
           chroma_data[cnt_data+5],
           chroma_data[cnt_data+4],
           chroma_data[cnt_data+3],
           chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:`BIT_DEPTH];
        3'b010:
          {chroma_data[cnt_data+5],
           chroma_data[cnt_data+4],
           chroma_data[cnt_data+3],
           chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:2*`BIT_DEPTH];
        3'b011:
          {chroma_data[cnt_data+4],
           chroma_data[cnt_data+3],
           chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:3*`BIT_DEPTH];
        3'b100:
          {chroma_data[cnt_data+3],
           chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:4*`BIT_DEPTH];
        3'b101:
          {chroma_data[cnt_data+2],
           chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:5*`BIT_DEPTH];
        3'b110:
          {chroma_data[cnt_data+1],
           chroma_data[cnt_data+0]} <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:6*`BIT_DEPTH];
        3'b111:
            chroma_data[cnt_data+0] <= chroma_rddata_mc_o[8*`BIT_DEPTH-1:7*`BIT_DEPTH];
        default: begin
          for(x=0; x<8; x=x+1) begin
            chroma_data[x] <= chroma_data[x];
          end
        end
      endcase
    end
    else begin
      for(x=0; x<11; x=x+1)
        chroma_data[x] <= chroma_data[x];
    end
  end
end

genvar m;
generate
for (m =0 ; m<11; m=m+1) begin: cr_cb
  always @( * ) begin
      chroma_data_i[(m+1)*`BIT_DEPTH-1:m*`BIT_DEPTH] = chroma_data[m];
  end
end
endgenerate

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    ref_valid_d <= 1'b0;
  else
    ref_valid_d <= next_row_d;
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

//read in

assign {chroma_ref1_p2, chroma_ref1_p1, chroma_ref1_p0,chroma_ref0_p2, chroma_ref0_p1, chroma_ref0_p0} =
       (working_mode_d1)?{chroma_data_i[5*`BIT_DEPTH-1:2*`BIT_DEPTH],chroma_data_i[3*`BIT_DEPTH-1:0]}:chroma_data_i[47:0];


assign end_oneblk_rd = end_oneblk_d1;


mc_chroma cb0(
          .clk_i             ( clk_i         ),
          .rst_n_i           ( rst_n_i       ),
          .frac0_i           ( {fmv0_ip_i[`FMVD_LEN+2:`FMVD_LEN],fmv0_ip_i[2:0]} ),
          .frac1_i           ( {fmv1_ip_i[`FMVD_LEN+2:`FMVD_LEN],fmv1_ip_i[2:0]} ),
          .end_oneblk_rd_i   ( end_oneblk_rd ),
          .refuv_valid_i     ( ref_valid_d   ),
          .refuv0_p0_i       ( chroma_ref0_p0    ),
          .refuv0_p1_i       ( chroma_ref0_p1    ),
          .refuv0_p2_i       ( chroma_ref0_p2    ),
          .refuv1_p0_i       ( chroma_ref1_p0    ),
          .refuv1_p1_i       ( chroma_ref1_p1    ),
          .refuv1_p2_i       ( chroma_ref1_p2    ),
          .end_oneblk_ip_o   ( end_oneblk_ip     ),
          .fracuv_valid_o    ( frac_chroma_v     ),
          .fracuv_p0_o       ( frac_chroma_p0    ),
          .fracuv_p1_o       ( frac_chroma_p1    ),
          .fracuv_p2_o       ( frac_chroma_p2    ),
          .fracuv_p3_o       ( frac_chroma_p3    )
);



reg [3:0] fmv_addr;
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    fmv_addr <= 4'd0;
  end
  else
    if(launch_mc_i) begin
      fmv_addr <= 4'd0;
    end
    else  if(end_oneblk_ip) begin
      fmv_addr <= frac_addr;
    end
end
assign fmv_addr_ip_o = fmv_addr;


//write
assign type_8x16 = (mb_type_i == `P_L0_16x16 | mb_type_i == `P_L0_L0_8x16);
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mc_pixel <= 0;
  else if(frac_chroma_v)
      if(type_8x16)
        case(mc_pixel)
          4'd3 : mc_pixel <= 4'd8;
          4'd11: mc_pixel <= 4'd4;
          4'd7 : mc_pixel <= 4'd12;
          default: mc_pixel <= mc_pixel + 4'd1;
        endcase
      else
        mc_pixel <= mc_pixel + 4'd1;
  else
        mc_pixel <= mc_pixel ;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin:j_n
  integer j;
    for(j=0; j<16; j=j+1) begin
      chroma_frac[j] <= 'd0;
    end
  end
  else if(frac_chroma_v)
    chroma_frac[mc_pixel] <= {frac_chroma_p3,frac_chroma_p2,frac_chroma_p1,frac_chroma_p0};
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    chroma_wren_o <= 1'b0;
  else
    if(mc_pixel == 'd15 & frac_chroma_v)
      chroma_wren_o <= 1'b1;
    else
      chroma_wren_o <= 1'b0;
end

assign end_onemb_chroma_o = (wr_cnt & chroma_wren_o);

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    wr_cnt <= 1'b0;
  else
    if(chroma_wren_o)
      wr_cnt <= wr_cnt + 1'b1;
end


genvar k;
generate
  for(k=0; k<4; k=k+1) begin: cb_cr_out
    assign cbcr_wrdata_o[(k+1)*8*`BIT_DEPTH-1    :k*8*`BIT_DEPTH    ] =  {chroma_frac[k + 4    ],chroma_frac[k    ]};
    assign cbcr_wrdata_o[(k+1)*8*`BIT_DEPTH-1+256:k*8*`BIT_DEPTH+256] =  {chroma_frac[k + 8 + 4],chroma_frac[k + 8]};
  end
endgenerate

assign chroma_wraddr_o = wr_cnt;


endmodule
