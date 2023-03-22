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
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------
`include "enc_defines.v"

module mc_luma_top(
       clk_i,
       rst_n_i,
       
       launch_mc_i,
       
       //read
       empty_i,
       luma_rden_mc_o,
       luma_addr_mc_o,
       luma_data_mc_i,
       luma_rdack_mc_i,
       
       //read Hfracl and Qfracl
       fracl_addr_o,
       HFracl0_i,
       HFracl1_i,
       QFracl0_i,
       QFracl1_i,
       
       //read mb_type infor
       mb_type_i,
       sub_mb_type_rd_i,
       part_cn_rd_o,
       sub_mb_type_ip_i,
       part_cn_ip_o,
       
       //output
       luma_end_onemb_o,
       
       //output
       luma_wren_o,
       luma_wraddr_o,
       luma_wrdata_o
);

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                      clk_i;
input                      rst_n_i;
input                      launch_mc_i;
input                      empty_i;
output                     luma_rden_mc_o;
output [6              :0] luma_addr_mc_o;
input  [20*`BIT_DEPTH-1:0] luma_data_mc_i;
input                      luma_rdack_mc_i;
//read Hfracl and Qfracl
output [3              :0] fracl_addr_o;
input  [3              :0] HFracl0_i;
input  [3              :0] HFracl1_i;
input  [3              :0] QFracl0_i;
input  [3              :0] QFracl1_i;
//read mb_type infor
input  [2              :0] mb_type_i;
input  [2              :0] sub_mb_type_rd_i;
output [1              :0] part_cn_rd_o;
input  [2              :0] sub_mb_type_ip_i;
output [1              :0] part_cn_ip_o;
output                      luma_end_onemb_o;
output [2               :0] luma_wraddr_o;
output [4*8*`BIT_DEPTH-1:0] luma_wrdata_o;
output                      luma_wren_o;



// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************
reg    [4*8*`BIT_DEPTH-1:0] data_luma;
reg    [6:0]                rd_addr;
reg    [1:0]                part_cn, part_ip;
reg    [1:0]                subpart_cn, subpart_ip;
reg    [3:0]                fracl_addr;
reg                         luma_wren_o;
reg                         state,nextstate;
reg    [1:0]                part_rd;
reg    [1:0]                subpart_rd;
reg    [4:0]                row_rd;
reg                         blk_rd;
reg    [4:0]                row_cn;
reg    [1:0]                blk_cn;
reg                         refdata_valid;
reg                         area_co_locate;
reg                         end_oneblk_rd;
reg    [2:0]                mc_pixel;
reg    [1:0]                luma_cnt;


// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
wire                        end_onemb;
wire                        end_oneblk;
wire                        rden;
wire                        end_onepart;
wire                        ip0_rpvalid_i;
wire [`BIT_DEPTH-1:0]       ip0_rp0_i,ip0_rp1_i,ip0_rp2_i,ip0_rp3_i,ip0_rp4_i;
wire [`BIT_DEPTH-1:0]       ip0_rp5_i,ip0_rp6_i,ip0_rp7_i,ip0_rp8_i,ip0_rp9_i;
wire                        ip1_rpvalid_i;
wire [`BIT_DEPTH-1  :0]     ip1_rp0_i,ip1_rp1_i,ip1_rp2_i,ip1_rp3_i,ip1_rp4_i;
wire [`BIT_DEPTH-1  :0]     ip1_rp5_i,ip1_rp6_i,ip1_rp7_i,ip1_rp8_i,ip1_rp9_i;
wire [8*`BIT_DEPTH-1:0]     mc_luma;
wire                        mcl_wren;
wire [20*`BIT_DEPTH-1:0]    refdata;
wire                        type_8x16;

wire   end_onesubpart  ;
wire   end_oneblk_ip   ; 
wire   candi_valid     ;

// ********************************************
//                                             
//    Parameter DECLARATION                     
//                                             
// ********************************************
//FSM
parameter MC_IDLE = 1'b0; 
parameter MC_RUN  = 1'b1;



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
  nextstate = MC_IDLE;
  case(state)
    MC_IDLE:  if(launch_mc_i) nextstate = MC_RUN;  else nextstate = MC_IDLE;
    MC_RUN :  if( end_onemb ) nextstate = MC_IDLE; else nextstate = MC_RUN;
    default: nextstate = MC_IDLE;
  endcase
end

//rd addr
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    rd_addr <= {7'b0};
  end
  else
    if(luma_rdack_mc_i)
      if(end_onemb)
        rd_addr <= 'b0;
      else
        rd_addr <=rd_addr + 1'b1;
    else
      rd_addr <= rd_addr;
end

assign rden           = (state == MC_RUN)&(!empty_i);
assign luma_rden_mc_o = rden;
assign luma_addr_mc_o = rd_addr;

///////////////////////////////////////////////////////////////////////////////
//   state setting
///////////////////////////////////////////////////////////////////////////////


always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16: begin
      part_rd      = 2'd0;
      subpart_rd   = 2'd0;
      row_rd       = 5'd21;
      blk_rd       = 1'd1;
    end
    `P_L0_L0_16x8: begin
      part_rd      = 2'd1;
      subpart_rd   = 2'd0;
      row_rd       = 5'd13;
      blk_rd       = 1'd1;
    end
    `P_L0_L0_8x16: begin
      part_rd      = 2'd1;
      subpart_rd   = 2'd0;
      row_rd       = 5'd21;
      blk_rd       = 1'd0;
    end
    `P_8x8:  begin
      part_rd      = 2'd3;
      blk_rd       = 1'd0;
      case(sub_mb_type_rd_i)
        `P_L0_8x8: begin subpart_rd = 2'd0; row_rd = 5'd13; end
        `P_L0_8x4: begin subpart_rd = 2'd1; row_rd = 5'd9;  end
        `P_L0_4x8: begin subpart_rd = 2'd0; row_rd = 5'd13; end
        `P_L0_4x4: begin subpart_rd = 2'd1; row_rd = 5'd9;  end
        default:   begin subpart_rd = 2'd0; row_rd = 5'd0;  end
      endcase
    end
    default:   begin
      part_rd    = 2'd0;
      subpart_rd = 2'd0;
      row_rd     = 5'd0;
      blk_rd     = 1'd0;
    end
  endcase
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    row_cn <= 5'd0;
  else if(luma_rdack_mc_i)
    if(row_cn == row_rd)
      row_cn <= 5'd0;
    else
      row_cn <= row_cn + 5'd1;
  else
    row_cn <= row_cn;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    blk_cn <= 2'd0;
  else if(end_oneblk)
    if(blk_cn == blk_rd)
      blk_cn <= 2'd0;
    else
      blk_cn <= blk_cn + 2'd1;
  else
    blk_cn <= blk_cn;
end

assign end_oneblk     = (row_cn == row_rd)&(luma_rdack_mc_i);
assign end_onesubpart = (end_oneblk)&(blk_cn==blk_rd);//one subpart is 8x16 8x8 

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    subpart_cn <= 0;
  else
    if(end_onesubpart)//end_one_subpart每当做完一个MC之后，就应当是一个subpart结束的时候
      if(subpart_cn == subpart_rd)
        subpart_cn <= 2'd0;
      else
        subpart_cn <= subpart_cn + 2'd1;
    else
      subpart_cn <= subpart_cn;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    part_cn <= 0;
  else
    if(end_onepart)
      if(part_cn == part_rd)
        part_cn <= 2'd0;
      else
        part_cn <= part_cn + 2'd1;
    else
      part_cn <= part_cn;
end
assign part_cn_rd_o = part_cn;

assign end_onepart      = end_onesubpart & (subpart_cn == subpart_rd);
assign end_onemb        = end_onepart & (part_cn == part_rd);
assign luma_end_onemb_o = end_onemb;

//读入要延迟一个周期

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    refdata_valid <= 1'b0;
    end_oneblk_rd <= 0;
  end
  else begin
    refdata_valid <= luma_rdack_mc_i;
    end_oneblk_rd <= end_oneblk;
  end
end


always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    area_co_locate <= 0;
  else if(luma_rdack_mc_i)
    area_co_locate <= (row_cn >= 3)&&(row_cn <= (row_rd-3));
  else
    area_co_locate <= 0;
end


//-----------------------------------------------------------------------------
//       signal interconnection
//-----------------------------------------------------------------------------

assign refdata       = luma_data_mc_i;
assign ip0_rpvalid_i = refdata_valid;
assign ip0_rp0_i     = refdata[ 1*`BIT_DEPTH-1:0*`BIT_DEPTH];
assign ip0_rp1_i     = refdata[ 2*`BIT_DEPTH-1:1*`BIT_DEPTH];
assign ip0_rp2_i     = refdata[ 3*`BIT_DEPTH-1:2*`BIT_DEPTH];
assign ip0_rp3_i     = refdata[ 4*`BIT_DEPTH-1:3*`BIT_DEPTH];
assign ip0_rp4_i     = refdata[ 5*`BIT_DEPTH-1:4*`BIT_DEPTH];
assign ip0_rp5_i     = refdata[ 6*`BIT_DEPTH-1:5*`BIT_DEPTH];
assign ip0_rp6_i     = refdata[ 7*`BIT_DEPTH-1:6*`BIT_DEPTH];
assign ip0_rp7_i     = refdata[ 8*`BIT_DEPTH-1:7*`BIT_DEPTH];
assign ip0_rp8_i     = refdata[ 9*`BIT_DEPTH-1:8*`BIT_DEPTH];
assign ip0_rp9_i     = refdata[10*`BIT_DEPTH-1:9*`BIT_DEPTH];

assign ip1_rpvalid_i = refdata_valid;
assign ip1_rp0_i     = refdata[11*`BIT_DEPTH-1:10*`BIT_DEPTH];
assign ip1_rp1_i     = refdata[12*`BIT_DEPTH-1:11*`BIT_DEPTH];
assign ip1_rp2_i     = refdata[13*`BIT_DEPTH-1:12*`BIT_DEPTH];
assign ip1_rp3_i     = refdata[14*`BIT_DEPTH-1:13*`BIT_DEPTH];
assign ip1_rp4_i     = refdata[15*`BIT_DEPTH-1:14*`BIT_DEPTH];
assign ip1_rp5_i     = refdata[16*`BIT_DEPTH-1:15*`BIT_DEPTH];
assign ip1_rp6_i     = refdata[17*`BIT_DEPTH-1:16*`BIT_DEPTH];
assign ip1_rp7_i     = refdata[18*`BIT_DEPTH-1:17*`BIT_DEPTH];
assign ip1_rp8_i     = refdata[19*`BIT_DEPTH-1:18*`BIT_DEPTH];
assign ip1_rp9_i     = refdata[20*`BIT_DEPTH-1:19*`BIT_DEPTH];


mc_luma luma_mc(
    .clk_i                ( clk_i          ),
    .rst_n_i              ( rst_n_i        ),
    .HFracl0_i            ( HFracl0_i      ),
    .HFracl1_i            ( HFracl1_i      ),
    .QFracl0_i            ( QFracl0_i      ),
    .QFracl1_i            ( QFracl1_i      ),
    .end_oneblk_input_i   ( end_oneblk_rd  ),
    .area_co_locate_i     ( area_co_locate ),
    .end_oneblk_ip_o      ( end_oneblk_ip  ),
    .ip0_rpvalid_i        ( ip0_rpvalid_i  ),
    .ip0_rp0_i            ( ip0_rp0_i      ),
    .ip0_rp1_i            ( ip0_rp1_i      ),
    .ip0_rp2_i            ( ip0_rp2_i      ),
    .ip0_rp3_i            ( ip0_rp3_i      ),
    .ip0_rp4_i            ( ip0_rp4_i      ),
    .ip0_rp5_i            ( ip0_rp5_i      ),
    .ip0_rp6_i            ( ip0_rp6_i      ),
    .ip0_rp7_i            ( ip0_rp7_i      ),
    .ip0_rp8_i            ( ip0_rp8_i      ),
    .ip0_rp9_i            ( ip0_rp9_i      ),
    .ip1_rpvalid_i        ( ip1_rpvalid_i  ),
    .ip1_rp0_i            ( ip1_rp0_i      ),
    .ip1_rp1_i            ( ip1_rp1_i      ),
    .ip1_rp2_i            ( ip1_rp2_i      ),
    .ip1_rp3_i            ( ip1_rp3_i      ),
    .ip1_rp4_i            ( ip1_rp4_i      ),
    .ip1_rp5_i            ( ip1_rp5_i      ),
    .ip1_rp6_i            ( ip1_rp6_i      ),
    .ip1_rp7_i            ( ip1_rp7_i      ),
    .ip1_rp8_i            ( ip1_rp8_i      ),
    .ip1_rp9_i            ( ip1_rp9_i      ),
    .half_ip_flag_i       ( 1'b0           ),   //1:half refinement, 0:quarter refinement
    //interpolator                         
    .candi_valid_o        ( candi_valid    ),
    //mc                                   
    .mc_luma_wren_o       ( mcl_wren       ),
    .mc_luma_o            ( mc_luma        )
);

//interpolator
//interpolator stage
always @( posedge clk_i or negedge rst_n_i ) begin
  if(!rst_n_i) begin
    part_ip    <= 2'b0;
    subpart_ip <= 2'b0;
  end
  else
    if(launch_mc_i) begin
      part_ip    <= 2'b0;
      subpart_ip <= 2'b0;
    end
    else
      if(end_oneblk_ip) begin
        part_ip <= part_cn;
        subpart_ip <= subpart_cn;
      end
end
assign part_cn_ip_o = part_ip;


always @( * ) begin
  case(mb_type_i)
    `P_L0_16x16  : fracl_addr = 0;
    `P_L0_L0_16x8: fracl_addr = {part_ip[0],3'b000};
    `P_L0_L0_8x16: fracl_addr = {part_ip,2'b00};
    `P_8x8:
      case(sub_mb_type_ip_i)
        `P_L0_8x8: fracl_addr = {part_ip,2'b00};
        `P_L0_8x4: fracl_addr = {part_ip,2'b00} | {2'b00,subpart_ip[0],1'b0};
        `P_L0_4x8: fracl_addr = {part_ip,2'b00};
        `P_L0_4x4: fracl_addr = {part_ip,2'b00} | {2'b00,subpart_ip[0],1'b0};
        default: fracl_addr = 0;
      endcase
    default: fracl_addr = 0;
  endcase
end
assign fracl_addr_o = fracl_addr;


assign type_8x16 = (mb_type_i == `P_L0_16x16 | mb_type_i == `P_L0_L0_8x16);
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    mc_pixel <= 0;
  else
    if(luma_wren_o)
      if(type_8x16)
        case(mc_pixel)
          3'd1:  mc_pixel <= 3'd4;
          3'd5:  mc_pixel <= 3'd2;
          3'd3:  mc_pixel <= 3'd6;
          default:  mc_pixel <= mc_pixel + 3'd1;
        endcase
      else
        mc_pixel <= mc_pixel + 3'd1;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    luma_cnt <= 'd0;
  else
    if(mcl_wren)
      luma_cnt <= luma_cnt + 1'b1;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    luma_wren_o <= 1'b0;
  else
    if(mcl_wren & luma_cnt == 2'b11)
      luma_wren_o <= 1'b1;
    else
      luma_wren_o <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    data_luma <= 'd0;
  else if(mcl_wren)
    case(luma_cnt)
      2'b00:  data_luma[8*`BIT_DEPTH-1:0*`BIT_DEPTH]     <= mc_luma;
      2'b01:  data_luma[2*8*`BIT_DEPTH-1:8*`BIT_DEPTH]   <= mc_luma;
      2'b10:  data_luma[3*8*`BIT_DEPTH-1:2*8*`BIT_DEPTH] <= mc_luma;
      2'b11:  data_luma[4*8*`BIT_DEPTH-1:3*8*`BIT_DEPTH] <= mc_luma;
      default: data_luma <= data_luma;
    endcase
end
    

assign luma_wraddr_o = mc_pixel;
assign luma_wrdata_o = data_luma;

endmodule
