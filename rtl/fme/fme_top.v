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
// Filename       : fme_top.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module fme_top(
       clk_i                             ,
       rst_n_i                           ,
       sysif_cmb_x_i                     ,
       sysif_cmb_y_i                     ,
       sysif_qp_i                        ,
       sysif_cmb_i                       ,
       sysif_start_fme_i                 ,
       sysif_done_fme_o                  ,
       imeif_imv_i                       ,
       imeif_mb_type_info_i              ,
       fetchif_ldstart_o                 ,
       fetchif_lden_o                    ,
       fetchif_lddone_o                  ,
       fetchif_cmb_x_o                   ,
       fetchif_cmb_y_o                   ,
       fetchif_sw_x_o                    ,
       fetchif_sw_y_o                    ,
       fetchif_valid_i                   ,
       fetchif_data_i                    ,
       mcif_fmv_o                        ,
       mcif_imv_o                        ,
       mcif_ecif_mb_type_info_o          ,
       mcif_ecif_valid_o                 ,
       mcif_rden_mc_i                    ,
       mcif_addr_mc_i                    ,
       mcif_data_mc_o                    ,
       mcif_rdack_mc_o                   ,
       mdif_valid_o                      ,
       mdif_intercost_o
       
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                                      clk_i                ;          //clock 
input                                      rst_n_i              ;          //reset_n 
// sys if                                                       
input [7                               :0] sysif_cmb_x_i        ;          //sys_interface x_coordinate of current_MB from top_ctr  
input [7                               :0] sysif_cmb_y_i        ;          //sys_interface y_coordinate of current_MB from top_ctr  
input [5                               :0] sysif_qp_i           ;          //sys_interface quantization parameter from top_ctr
input [`MB_SIZE*`BIT_DEPTH-1           :0] sysif_cmb_i          ;          //sys_interface current_MB luma data from  cur_mb module
input                                      sysif_start_fme_i    ;          //sys_interface fme_start from top_ctr 
output                                     sysif_done_fme_o     ;          //sys_interface fme_done to top_ctr 
// ime if
input [`BLK4X4_NUM*2*`IMVD_LEN-1       :0] imeif_imv_i          ;          //motion vector from IME 
input [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] imeif_mb_type_info_i;//MB's tpye_info from IME 
// fetch if
output										fetchif_ldstart_o   ;
output [7                              :0]  fetchif_cmb_x_o     ;          //fetch data of cur_MB's x_coordinate to fetch   
output [7                              :0]  fetchif_cmb_y_o     ;          //fetch data of cur_MB's y_coordinate to fetch    
output [`SW_W_LEN                      :0]  fetchif_sw_x_o      ;          //x_coordinate of search_window
output [`SW_H_LEN                      :0]  fetchif_sw_y_o      ;          //y_coordinate of search_window
output                                      fetchif_lden_o      ;          //load data enable signal to fetch
output                                      fetchif_lddone_o    ;          //load_data done signal to fetch 
input                                       fetchif_valid_i     ;          //load_data valid from fetch 
input  [16*`BIT_DEPTH-1                :0]  fetchif_data_i      ;          //load_data from fetch 
// mc if                                               
output [`BLK4X4_NUM*2*`FMVD_LEN-1      :0]  mcif_fmv_o          ;          //frac_motion_vector  to MC
output [`BLK4X4_NUM*2*`IMVD_LEN-1      :0]  mcif_imv_o          ;          //inter_motion_vector to MC
output [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] mcif_ecif_mb_type_info_o;//MB's type to MC 
output                                      mcif_ecif_valid_o   ;          //valid to MC
//mc if : read luma for mc from fme
input                                       mcif_rden_mc_i      ;          //read enable from MC 
input  [6                              :0]  mcif_addr_mc_i      ;          //address  from MC 
output [20*`BIT_DEPTH-1                :0]  mcif_data_mc_o      ;          //read_data(luma) to MC
output                                      mcif_rdack_mc_o     ;          //read_ack signal to MC
// md if                               
output                                      mdif_valid_o        ;          //valid 
output [`BIT_DEPTH+10-1                :0]  mdif_intercost_o    ;          //the minimum inter cost ; best cost 

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 
//  fme datapath wires
wire                      ip0_rpvalid_i            ;
wire [`BIT_DEPTH-1    :0] ip0_rp0_i, ip0_rp1_i     ; 
wire [`BIT_DEPTH-1    :0] ip0_rp2_i, ip0_rp3_i     ; 
wire [`BIT_DEPTH-1    :0] ip0_rp4_i                ;
wire [`BIT_DEPTH-1    :0] ip0_rp5_i, ip0_rp6_i     ; 
wire [`BIT_DEPTH-1    :0] ip0_rp7_i, ip0_rp8_i     ; 
wire [`BIT_DEPTH-1    :0] ip0_rp9_i                ;
                                                   
wire                      ip1_rpvalid_i            ;
wire [`BIT_DEPTH-1    :0] ip1_rp0_i, ip1_rp1_i     ; 
wire [`BIT_DEPTH-1    :0] ip1_rp2_i, ip1_rp3_i     ; 
wire [`BIT_DEPTH-1    :0] ip1_rp4_i                ;
wire [`BIT_DEPTH-1    :0] ip1_rp5_i, ip1_rp6_i     ; 
wire [`BIT_DEPTH-1    :0] ip1_rp7_i, ip1_rp8_i     ; 
wire [`BIT_DEPTH-1    :0] ip1_rp9_i                ;
                                                   
wire                      satd_4x4_valid           ;
wire                      satd_blk_valid           ;
//  fme load module wires                          
wire                      start_rd                 ;
wire [4               :0] rd_row                   ;
wire                      rd_blk                   ;
wire [20*`BIT_DEPTH-1 :0] refdata                  ;
wire                      refdata_valid            ;
wire                      end_one_blk_rd           ;
wire                      area_co_locate           ;
//  fme ram wires                                  
wire                      end_one_mb               ;
wire                      updata_base_rd           ;

//  fme fetch module wires
wire [`IMVD_LEN-1     :0] fetch_mv0_x, fetch_mv0_y ; 
wire [`IMVD_LEN-1     :0] fetch_mv1_x, fetch_mv1_y ;

//  global wires
wire [2               :0] mb_type                  ;
wire [1               :0] part_fetch, part_cn_rd   ; 
wire [1               :0] part_cn_ip, part_cn_satd ; 
wire [1               :0] part_cn_bcs              ;
wire [1               :0] subpart_cn_bcs           ;
wire [2*`IMVD_LEN-1   :0] mv0_fme, mv1_fme         ;

wire [3               :0] mv_addr_fme              ;
wire                      end_fme                  ;
wire [2*`IMVD_LEN-1   :0] mv0_fetch, mv1_fetch     ;
wire [3               :0] mv_addr_fetch            ;
                                                   
wire [2*`FMVD_LEN-1   :0] fmv0, fmv1               ;
wire [4               :0] cmb_p_addr               ;
                                                   
wire [`BIT_DEPTH-1    :0] cmb_p0, cmb_p1           ; 
wire [`BIT_DEPTH-1    :0] cmb_p2, cmb_p3           ;
wire [`BIT_DEPTH-1    :0] cmb_p4, cmb_p5           ;
wire [`BIT_DEPTH-1    :0] cmb_p6, cmb_p7           ;

wire                      best_candi_v             ;
wire                      half_flag_bcs            ;
wire [7               :0] fracl0, fracl1           ;
wire [2*`FMVD_LEN-1   :0] mvp_i                    ;
wire                      best_cost_v              ;
wire [`BIT_DEPTH+10-1 :0] best_cost                ;

wire                      full_ram, empty_ram      ;
wire [20*`BIT_DEPTH-1 :0] data_fetch               ;
wire                      wren_fetch               ;
wire [20*`BIT_DEPTH-1 :0] data_load                ;
wire                      rden_load                ;

wire                      start_fetch              ;
wire                      fetch_go_ahead           ;
wire                      end_onemb                ;
wire                      end_rd                   ;
wire                      half_flag_ip             ;
wire                      working_mode_satd        ;
wire                      end_oneblk_ip            ;
wire                      candi_valid              ;
wire                      working_mode_bcs         ;
// ******************************************** 
//                                              
//    Reg DECLARATION                          
//                                              
// ******************************************** 
reg                                                  best_candi            ;
reg  [`MB_TYPE_LEN+`BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] mb_type_info          ;
reg  [`BLK4X4_NUM*2*`IMVD_LEN-1                  :0] imv                   ;
reg  [2*`IMVD_LEN-1                              :0] imv_r[`BLK4X4_NUM-1:0];
reg  [2                                          :0] sub_mb_type_rd        ; 
reg  [2                                          :0] sub_mb_type_fetch     ; 
reg  [2                                          :0] sub_mb_type_ip        ;
reg  [2                                          :0] sub_mb_type_satd      ; 
reg  [2                                          :0] sub_mb_type_bcs       ;
reg                                                  mp_output             ;

reg                                                  wait_ime              ;
reg  [`BLK4X4_NUM*2*`FMVD_LEN-1                  :0] mcif_fmv_o            ;
reg  [`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN-1:0] mcif_ecif_mb_type_info_o;
reg  [`BLK4X4_NUM*8-1                            :0] fracl_o               ;

reg                                                  fme_st, fme_nst       ;
reg  [2*`FMVD_LEN-1   :0] fmvd [`BLK4X4_NUM-1    :0]                       ;

reg [`BIT_DEPTH+10-1:0] bcost;
reg [8*`BIT_DEPTH-1:0] cmb[31:0];

// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter FME_IDLE = 1'b0, FME_RUN = 1'b1;

// ********************************************
//                                             
//    FSM  Logic                  
//                                             
// ********************************************
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    fme_st <= FME_IDLE;
  else
    fme_st <= fme_nst;
end

always @( * ) begin
  fme_nst = FME_IDLE;
  case(fme_st)
    FME_IDLE:
      if(sysif_start_fme_i)
        fme_nst = FME_RUN;
      else
        fme_nst = FME_IDLE;
    FME_RUN:
      if(end_fme)
        fme_nst = FME_IDLE;
      else
        fme_nst = FME_RUN;
    default:
      fme_nst = FME_IDLE;
  endcase
end

// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
//-----------------------------------------------------------------------------
//       signal interconnection
//-----------------------------------------------------------------------------   
assign mvp_i = 'd0;
assign ip0_rpvalid_i = refdata_valid;
assign ip0_rp0_i     = refdata[ 1*`BIT_DEPTH-1:0*`BIT_DEPTH]     ;
assign ip0_rp1_i     = refdata[ 2*`BIT_DEPTH-1:1*`BIT_DEPTH]     ;
assign ip0_rp2_i     = refdata[ 3*`BIT_DEPTH-1:2*`BIT_DEPTH]     ;
assign ip0_rp3_i     = refdata[ 4*`BIT_DEPTH-1:3*`BIT_DEPTH]     ;
assign ip0_rp4_i     = refdata[ 5*`BIT_DEPTH-1:4*`BIT_DEPTH]     ;
assign ip0_rp5_i     = refdata[ 6*`BIT_DEPTH-1:5*`BIT_DEPTH]     ;
assign ip0_rp6_i     = refdata[ 7*`BIT_DEPTH-1:6*`BIT_DEPTH]     ;
assign ip0_rp7_i     = refdata[ 8*`BIT_DEPTH-1:7*`BIT_DEPTH]     ;
assign ip0_rp8_i     = refdata[ 9*`BIT_DEPTH-1:8*`BIT_DEPTH]     ;
assign ip0_rp9_i     = refdata[10*`BIT_DEPTH-1:9*`BIT_DEPTH]     ;

assign ip1_rpvalid_i = refdata_valid;
assign ip1_rp0_i     = refdata[11*`BIT_DEPTH-1:10*`BIT_DEPTH]    ;
assign ip1_rp1_i     = refdata[12*`BIT_DEPTH-1:11*`BIT_DEPTH]    ;
assign ip1_rp2_i     = refdata[13*`BIT_DEPTH-1:12*`BIT_DEPTH]    ;
assign ip1_rp3_i     = refdata[14*`BIT_DEPTH-1:13*`BIT_DEPTH]    ;
assign ip1_rp4_i     = refdata[15*`BIT_DEPTH-1:14*`BIT_DEPTH]    ;
assign ip1_rp5_i     = refdata[16*`BIT_DEPTH-1:15*`BIT_DEPTH]    ;
assign ip1_rp6_i     = refdata[17*`BIT_DEPTH-1:16*`BIT_DEPTH]    ;
assign ip1_rp7_i     = refdata[18*`BIT_DEPTH-1:17*`BIT_DEPTH]    ;
assign ip1_rp8_i     = refdata[19*`BIT_DEPTH-1:18*`BIT_DEPTH]    ;
assign ip1_rp9_i     = refdata[20*`BIT_DEPTH-1:19*`BIT_DEPTH]    ;
                                                                 
assign fetch_mv0_y   = mv0_fetch[2*`IMVD_LEN-1:`IMVD_LEN]        ;
assign fetch_mv0_x   = mv0_fetch[1*`IMVD_LEN-1:0]                ;
assign fetch_mv1_y   = mv1_fetch[2*`IMVD_LEN-1:`IMVD_LEN]        ;
assign fetch_mv1_x   = mv1_fetch[1*`IMVD_LEN-1:0]                ;
//-----------------------------------------------------------------------------
//       setting parameters and assignment to modules requiring
//-----------------------------------------------------------------------------
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mb_type_info <= 0;
  else if(sysif_start_fme_i)
    mb_type_info <= imeif_mb_type_info_i; //`MB_TYPE_LEN + `BLK8X8_NUM*`SUB_MB_TYPE_LEN ; 3+4x3  
end
assign mb_type     = mb_type_info[2:0]  ; //mb_type_info = { sub_mb_type, mb_type }

always @( * ) begin
  case(part_cn_rd)
    2'b00:
      sub_mb_type_rd = mb_type_info[5:3]  ;
    2'b01:                                
      sub_mb_type_rd = mb_type_info[8:6]  ;
    2'b10:
      sub_mb_type_rd = mb_type_info[11:9] ;
    2'b11:
      sub_mb_type_rd = mb_type_info[14:12];
    default:
      sub_mb_type_rd = 0;
  endcase
end

always @( * ) begin
  case(part_fetch)
    2'b00:
      sub_mb_type_fetch = mb_type_info[5:3]  ;
    2'b01:                                   
      sub_mb_type_fetch = mb_type_info[8:6]  ;
    2'b10:
      sub_mb_type_fetch = mb_type_info[11:9] ;
    2'b11:
      sub_mb_type_fetch = mb_type_info[14:12];
    default:
      sub_mb_type_fetch = 0;
  endcase
end

always @( * ) begin
  case(part_cn_ip)
    2'b00:
      sub_mb_type_ip = mb_type_info[5:3]  ;
    2'b01:                                
      sub_mb_type_ip = mb_type_info[8:6]  ;
    2'b10:                                
      sub_mb_type_ip = mb_type_info[11:9] ;
    2'b11:
      sub_mb_type_ip = mb_type_info[14:12];
    default:
      sub_mb_type_ip = 0;
  endcase
end

always @( * ) begin
  case(part_cn_satd)
    2'b00:
      sub_mb_type_satd = mb_type_info[5:3]  ;
    2'b01:                                  
      sub_mb_type_satd = mb_type_info[8:6]  ;
    2'b10:
      sub_mb_type_satd = mb_type_info[11:9] ;
    2'b11:
      sub_mb_type_satd = mb_type_info[14:12];
    default:
      sub_mb_type_satd = 0;
  endcase
end

//bcs:best candidate select 
always @( * ) begin
  case(part_cn_bcs)
    2'b00:
      sub_mb_type_bcs = mb_type_info[5:3]  ;
    2'b01:                                 
      sub_mb_type_bcs = mb_type_info[8:6]  ;
    2'b10:                                 
      sub_mb_type_bcs = mb_type_info[11:9] ;
    2'b11:
      sub_mb_type_bcs = mb_type_info[14:12];
    default:
      sub_mb_type_bcs = 0;
  endcase
end

//imv
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    imv <= 'b0;
  else if(sysif_start_fme_i)
    imv <= imeif_imv_i;
end

assign mcif_imv_o = imv;

genvar m;

generate
  for(m=0; m<`BLK4X4_NUM; m=m+1) begin: imv_i
    always @( * )
      imv_r[m] = imv[(m+1)*2*`IMVD_LEN-1:m*2*`IMVD_LEN];
  end
endgenerate

assign mv0_fme = imv_r[mv_addr_fme];
assign mv1_fme = imv_r[mv_addr_fme + 1];

//fetch needed
assign mv0_fetch = imv_r[mv_addr_fetch];
assign mv1_fetch = imv_r[mv_addr_fetch + 1];


assign sysif_done_fme_o = end_fme;


//-----------------------------------------------------------------------------
//   fme output
//-----------------------------------------------------------------------------

integer k;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    for(k=0; k<`BLK4X4_NUM; k=k+1) begin
      fmvd[k] <= 'b0;
    end
  end
  else if(best_candi_v & !half_flag_bcs)
    case(mb_type)
      `P_L0_16x16: begin
        for(k=0;k<`BLK4X4_NUM; k=k+1) begin
          fmvd[k] <= fmv0;
        end
      end
      `P_L0_L0_16x8: begin
        for(k=0;k<(`BLK4X4_NUM/2); k=k+1) begin
          fmvd[k + (part_cn_bcs<<3)] <= fmv0;
        end
      end
      `P_L0_L0_8x16: begin
        for(k=0; k<(`BLK4X4_NUM/4); k=k+1) begin
          fmvd[k + (part_cn_bcs<<2)] <= fmv0;
        end
        for(k=0; k<(`BLK4X4_NUM/4); k=k+1) begin
          fmvd[k + ((part_cn_bcs+2)<<2)] <= fmv0;
        end
      end
      `P_8x8: begin
        case(sub_mb_type_bcs)
          `P_L0_8x8: begin
            for(k=0; k<(`BLK4X4_NUM/4); k=k+1) begin
              fmvd[k + (part_cn_bcs<<2)] <= fmv0;
            end
          end
          `P_L0_8x4: begin
              fmvd[(part_cn_bcs<<2) + (subpart_cn_bcs*2)]   <= fmv0;
              fmvd[(part_cn_bcs<<2) + (subpart_cn_bcs*2+1)] <= fmv0;
          end
          `P_L0_4x8: begin
              fmvd[(part_cn_bcs<<2) + 0]   <= fmv0;
              fmvd[(part_cn_bcs<<2) + 2]   <= fmv0;
              fmvd[(part_cn_bcs<<2) + 1]   <= fmv1;
              fmvd[(part_cn_bcs<<2) + 3]   <= fmv1;
          end
          `P_L0_4x4: begin
              fmvd[(part_cn_bcs<<2) + (subpart_cn_bcs*2)]   <= fmv0;
              fmvd[(part_cn_bcs<<2) + (subpart_cn_bcs*2+1)] <= fmv1;
          end
          default: begin
            for(k=0; k<`BLK4X4_NUM; k=k+1) begin
               fmvd[k] <= fmvd[k];
            end
          end
        endcase
      end
      default: begin
        for(k=0; k<`BLK4X4_NUM; k=k+1) begin
          fmvd[k] <= fmvd[k];
        end
      end
    endcase
  else begin
     for(k=0; k<`BLK4X4_NUM; k=k+1) begin
       fmvd[k] <= fmvd[k];
     end
  end
end

genvar a;

generate
  for(a=0;a<`BLK4X4_NUM; a=a+1) begin: fmvd_n_o
    always @( * )
      mcif_fmv_o[(a+1)*2*`FMVD_LEN-1:a*2*`FMVD_LEN] = fmvd[a];
  end
endgenerate

//COST

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) 
    bcost <= 'd0;
  else if(sysif_start_fme_i)
    bcost <= 'd0;
  else if(best_cost_v)
    bcost <= bcost + best_cost;
end

assign mdif_intercost_o = bcost;
assign mdif_valid_o     = end_fme; 
        
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mcif_ecif_mb_type_info_o <= 'b0;
  else if(end_fme)
    mcif_ecif_mb_type_info_o <= mb_type_info;
end

assign mcif_ecif_valid_o = end_fme;
//-----------------------------------------------------------------------------
//  cmb
//-----------------------------------------------------------------------------

genvar i,j;

generate
  for(i=0;i<4;i=i+1) begin: n_i
    for(j=0;j<8;j=j+1) begin: j_n
      always @( * ) begin
        cmb[((i*8) + j)] 
           = sysif_cmb_i[(((i/2)*8 + j)*16 + (i%2)*8 + 8)*`BIT_DEPTH-1:(((i/2)*8 + j)*16 + (i%2)*8)*`BIT_DEPTH];
      end
    end
  end
endgenerate

assign {cmb_p7,cmb_p6,cmb_p5,cmb_p4,cmb_p3,cmb_p2,cmb_p1,cmb_p0} =  cmb[cmb_p_addr];  // 8_pixels 

assign fetchif_ldstart_o = sysif_start_fme_i;

//-----------------------------------------------------------------------------
//  cmb
//-----------------------------------------------------------------------------
          
//-----------------------------------------------------------------------------
//       instantiate modules 
//-----------------------------------------------------------------------------

fme_fetch fme_fetch(
       .clk_i            ( clk_i               ),
       .rst_n_i          ( rst_n_i             ),                                               
       .start_wr_i       ( start_fetch         ),                                               
       .mb_type_i        ( mb_type             ),
       .sub_mb_type_i    ( sub_mb_type_fetch   ),
       .part_o           ( part_fetch          ),                                               
       .cmb_x_i          ( sysif_cmb_x_i       ),
       .cmb_y_i          ( sysif_cmb_y_i       ),                                               
       .mv0_x_i          ( fetch_mv0_x         ),
       .mv0_y_i          ( fetch_mv0_y         ),
       .mv1_x_i          ( fetch_mv1_x         ),
       .mv1_y_i          ( fetch_mv1_y         ),
       .mv0_addr_o       ( mv_addr_fetch       ), //一个地址可以读两个mv，两个挨着的MV，这样为了能够实现8-pixel共用                                               
       .full_i           ( full_ram            ), //from fifo if the fifo is not full, wr module can write the data to fifo.
       .wrdata_o         ( data_fetch          ),
       .wren_o           ( wren_fetch          ),
       .ft_go_ahead_i    ( fetch_go_ahead      ),                                               
       .cmb_x_o          ( fetchif_cmb_x_o     ),
       .cmb_y_o          ( fetchif_cmb_y_o     ),
       .sw_pel_x_o       ( fetchif_sw_x_o      ),
       .sw_pel_y_o       ( fetchif_sw_y_o      ),
       .rden_cache_o     ( fetchif_lden_o      ),
       .rddone_cache_o   ( fetchif_lddone_o    ),
       .ack_cache_i      ( fetchif_valid_i     ),
       .rddata_cache_i   ( fetchif_data_i      )
);

fme_ram fme_ram(
       .clk_i            ( clk_i               ),
       .rst_n_i          ( rst_n_i             ),                                               
       .clear_i          ( end_onemb           ), //clear是由controller模块发出的，是为了下一个MB做好准备；                                               
       .data_i           ( data_fetch          ),
       .wren_i           ( wren_fetch          ),       
       .ft_go_ahead_o    ( fetch_go_ahead      ),                                               
       .update_base_rd_i ( updata_base_rd      ), //是由读模块发出的，为了更新base_rd
       .the_last_line_i  ( end_rd              ), //一个块中
       .rden_i           ( rden_load           ),
       .data_o           ( data_load           ),                                               
       .empty_o          ( empty_ram           ),
       .full_o           ( full_ram            ),       
       .rden_mc_i        ( mcif_rden_mc_i      ),
       .addr_mc_i        ( mcif_addr_mc_i      ),
       .data_mc_o        ( mcif_data_mc_o      ),
       .ack_mc_o         ( mcif_rdack_mc_o     )
);


fme_load fme_load(
       .clk_i            ( clk_i               ),
       .rst_n_i          ( rst_n_i             ),        
       .start_rd_i       ( start_rd            ),
       .rd_row_i         ( rd_row              ),
       .rd_blk_i         ( rd_blk              ),
       .end_rd_o         ( end_rd              ),        
       .empty_i          ( empty_ram           ),
       .rddata_i         ( data_load           ),
       .rden_o           ( rden_load           ),        
       .refdata_o        ( refdata             ),
       .refdata_valid_o  ( refdata_valid       ),
       .end_one_blk_rd_o ( end_one_blk_rd      ),
       .area_co_locate_o ( area_co_locate      )
);

fme_ctrl fme_ctrl(
       .clk_i                ( clk_i             ),
       .rst_n_i              ( rst_n_i           ),                             
       .start_fme_i          ( sysif_start_fme_i ),       
       .part_cn_rd_o         ( part_cn_rd        ),
       .mb_type_rd_i         ( mb_type           ),
       .sub_mb_type_rd_i     ( sub_mb_type_rd    ),       
       .mb_type_ip_i         ( mb_type           ), //datapath
       .sub_mb_type_ip_i     ( sub_mb_type_ip    ), 
       .part_cn_ip_o         ( part_cn_ip        ),        
       .mb_type_satd_i       ( mb_type           ), //datapath
       .sub_mb_type_satd_i   ( sub_mb_type_satd  ), 
       .part_cn_satd_o       ( part_cn_satd      ),        
       .mb_type_bcs_i        ( mb_type           ), //datapath
       .sub_mb_type_bcs_i    ( sub_mb_type_bcs   ), 
       .part_cn_bcs_o        ( part_cn_bcs       ), 
       .subpart_cn_bcs_o     ( subpart_cn_bcs    ), 
       //read refpels from fme_fifo                 
       .start_rd_o           ( start_rd          ), //read reference data
       .end_onemb_rd_o       ( end_onemb         ), 
       .updata_base_rd_o     ( updata_base_rd    ), 
       .rd_row_rd_o          ( rd_row            ), 
       .rd_blk_rd_o          ( rd_blk            ), 
       .end_rd_i             ( end_rd            ),        
       //load refpels from cache                    
       .start_ft_o           ( start_fetch       ),                              
       .half_flag_ip_o       ( half_flag_ip      ), 
       .half_flag_bcs_o      ( half_flag_bcs     ), 
       .working_mode_satd_o  ( working_mode_satd ), //inform candidate 
       .working_mode_bcs_o   ( working_mode_bcs  ),
       .end_oneblk_ip_i      ( end_oneblk_ip     ),       
       //from interpolator
       .candi_valid_i        ( candi_valid       ),
       .cmb_p_addr_o         ( cmb_p_addr        ),       
       //from and to SATD accumulation
       .satd_4x4_valid_i     ( satd_4x4_valid    ),
       .satd_blk_valid_o     ( satd_blk_valid    ),       
       //to best candidate select
       .imv_addr_o           ( mv_addr_fme       ),
       .best_candi_i         ( best_candi_v      ),       
       //control outputting
       .end_fme_o            ( end_fme           )
);

fme_datapath fme_datapath(
       .clk_i                ( clk_i             ),
       .rst_n_i              ( rst_n_i           ),
       //data signals                            
       .cmb_p0_i             ( cmb_p0            ),
       .cmb_p1_i             ( cmb_p1            ),
       .cmb_p2_i             ( cmb_p2            ),
       .cmb_p3_i             ( cmb_p3            ),
       .cmb_p4_i             ( cmb_p4            ),
       .cmb_p5_i             ( cmb_p5            ),
       .cmb_p6_i             ( cmb_p6            ),
       .cmb_p7_i             ( cmb_p7            ),       
       .end_one_blk_input_i  ( end_one_blk_rd    ),
       .area_co_locate_i     ( area_co_locate    ),
       .end_oneblk_ip_o      ( end_oneblk_ip     ),                             
       .ip0_rpvalid_i        ( ip0_rpvalid_i     ),
       .ip0_rp0_i            ( ip0_rp0_i         ),
       .ip0_rp1_i            ( ip0_rp1_i         ),
       .ip0_rp2_i            ( ip0_rp2_i         ),
       .ip0_rp3_i            ( ip0_rp3_i         ),
       .ip0_rp4_i            ( ip0_rp4_i         ),
       .ip0_rp5_i            ( ip0_rp5_i         ),
       .ip0_rp6_i            ( ip0_rp6_i         ),
       .ip0_rp7_i            ( ip0_rp7_i         ),
       .ip0_rp8_i            ( ip0_rp8_i         ),
       .ip0_rp9_i            ( ip0_rp9_i         ),       
       .ip1_rpvalid_i        ( ip1_rpvalid_i     ),
       .ip1_rp0_i            ( ip1_rp0_i         ),
       .ip1_rp1_i            ( ip1_rp1_i         ),
       .ip1_rp2_i            ( ip1_rp2_i         ),
       .ip1_rp3_i            ( ip1_rp3_i         ),
       .ip1_rp4_i            ( ip1_rp4_i         ),
       .ip1_rp5_i            ( ip1_rp5_i         ),
       .ip1_rp6_i            ( ip1_rp6_i         ),
       .ip1_rp7_i            ( ip1_rp7_i         ),
       .ip1_rp8_i            ( ip1_rp8_i         ),
       .ip1_rp9_i            ( ip1_rp9_i         ),       
       .half_flag_ip_i       ( half_flag_ip      ),  //1:half refinement, 0:quarter refinement
       .half_flag_bcs_i      ( half_flag_bcs     ),      
       //interpolator
       .candi_valid_o        ( candi_valid       ),
       //satd gen
       .working_mode_satd_i  ( working_mode_satd ),  //0 for 4x4; 1 for 8x8
       .satd_4x4_valid_o     ( satd_4x4_valid    ),  //
       .satd_blk_valid_i     ( satd_blk_valid    ),  //blk:16x16 8x16 16x8 8x8 8x4 4x8 4x4       
       //best candidate select
       .working_mode_bcs_i   ( working_mode_bcs  ),  //0 for 4x4; 1 for 8x8
       .imv0_i               ( mv0_fme           ),
       .imv1_i               ( mv1_fme           ),
       .mvp_i                ( mvp_i             ),
       .qp_i                 ( sysif_qp_i        ),
       .best_candi_v_o       ( best_candi_v      ),
       .bcost_valid_o        ( best_cost_v       ),
       .bcost_o              ( best_cost         ),       
       //mv write            
       .fmv0_o               ( fmv0              ),
       .fmv1_o               ( fmv1              )
);

endmodule
