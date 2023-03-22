//-------------------------------------------------------------------
//
//  COPYRIGHT (C) 2011, VIPcore Group, Fudan University
//
//  THIS FILE MAY NOT BE MODIFIED OR REDISTRIBUTED WITHOUT THE
//  EXPRESSED WRITTEN CONSENT OF VIPcore Group
//
//  VIPcore       : http://soc.fudan.edu.cn/vip
//  IP Owner    : Yibo FAN
//  Contact       : fanyibo@fudan.edu.cn
//-------------------------------------------------------------------
// Filename       : fetch_chroma.v
// Author         : huibo zhong
// Created        : 2011-08-24
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//
// $Id$
// Edited         : 2012-04-07
// Author         : xing yuan
//
// Modified       : 2013-09-12 by Baiyufeng
//                : update mem bank, replace cbcr interlaced by
//                : cb bank and cr bank
//
// Edited         : 2013-09-17 by Yufeng Bai
//                : rewrite the whole module
//-------------------------------------------------------------------
`include "enc_defines.v"

module fetch_chroma(
        clk                           ,
        rst_n                         ,
        sys_total_mb_x                ,
        sys_total_mb_y                ,

        sysif_start_ld_chroma_i       ,
        sysif_done_ld_chroma_o        ,
        sysif_mb_x_i                  ,
        sysif_mb_y_i                  ,

        chroma_req_ext_o              ,
        chroma_done_ext_i             ,
        chroma_mb_x_ext_o             ,
        chroma_mb_y_ext_o             ,
        chroma_data_v_ext_i           ,
        chroma_data_ext_i             ,

        mc_chroma_rd_en_i             ,
        mc_chroma_rd_done_i           ,
        mc_chroma_rd_crcb_i           ,
        mc_chroma_rd_ack_o            ,
        mc_chroma_rd_mb_x_i           ,
        mc_chroma_rd_mb_y_i           ,
        mc_chroma_rd_sw_x_i           ,
        mc_chroma_rd_sw_y_i           ,
        mc_chroma_rd_data_o
);
// *****************************************************
//
//    INPUT / OUTPUT DECLARATION
//
// *****************************************************
input                       clk                    ;      //clock
input                       rst_n                  ;      //reset_n

//sys if
input [`PIC_W_MB_LEN-1:0]   sys_total_mb_x         ;
input [`PIC_W_MB_LEN-1:0]   sys_total_mb_y         ;
input                       sysif_start_ld_chroma_i;      //load_chroma start = ime_start
output                      sysif_done_ld_chroma_o ;      //load_chroma_done
input [`PIC_W_MB_LEN-1:0]   sysif_mb_x_i           ;      //mb's x_coordinate from top_ctr = ime_cmb_x
input [`PIC_W_MB_LEN-1:0]   sysif_mb_y_i           ;      //mb's y_coordinate from top_ctr = ime_cmb_y

//ext if
output                      chroma_req_ext_o       ;      //load_chroma request
input                       chroma_done_ext_i      ;      //load_done chroma
output[`PIC_W_MB_LEN-1:0]   chroma_mb_x_ext_o      ;      //load_chroma MB's x_coordinate
output[`PIC_W_MB_LEN-1:0]   chroma_mb_y_ext_o      ;      //load_chroma MB's y_coordinate
input                       chroma_data_v_ext_i    ;      //load_chroma data_valid
input [8*`BIT_DEPTH-1 :0]   chroma_data_ext_i      ;      //load_chroma data  from ext_mem

//mc fetch if
input                       mc_chroma_rd_en_i      ;      //read_chroma_enable  from MC
input                       mc_chroma_rd_done_i    ;      //read_chroma_done from MC
input                       mc_chroma_rd_crcb_i    ;      //read_chroma_crcb from MC, specifiy read cr or cb
output                      mc_chroma_rd_ack_o     ;      //read_chroma_ack  to MC
input [`PIC_W_MB_LEN-1:0]   mc_chroma_rd_mb_x_i    ;      //read_chroma MB's x_coordinate from MC
input [`PIC_W_MB_LEN-1:0]   mc_chroma_rd_mb_y_i    ;      //read_chroma MB's y_coordinate
input [`SW_W_LEN-1    :0]   mc_chroma_rd_sw_x_i    ;      //read_chroma search_window's x_coordinate
input [`SW_H_LEN-1    :0]   mc_chroma_rd_sw_y_i    ;      //read_chroma search_window's y_coordinate
output [8*`BIT_DEPTH-1:0]   mc_chroma_rd_data_o    ;      //read_chroma data to MC
// *************************************************
//
//    Wire DECLARATION
//
// *************************************************



// *************************************************
//
//    PARAMETER DECLARATION
//
// *************************************************

parameter                 IDLE = 3'd0    ;  //  IDLE
parameter                 LD_T = 3'd1    ;  //  LOAD top MB sw strip
parameter                 LD_S = 3'd2    ;  //  LOAD normal MB sw strip
parameter                 LD_B = 3'd3    ;  //  LOAD bottom mb sw strip
parameter                 LD_N = 3'd4    ;  //  TOP sw strip NOT LOAD


parameter                 EXT_WAIT = 1'd0;  //  EXT LOAD WATING
parameter                 EXT_LOAD = 1'd1;  //  EXT LOADING

// *************************************************
//
//    REG DECLARATION
//
// *************************************************
//output
reg                        sysif_done_ld_chroma_o ;      //load_chroma_done

// ctrl
reg [2                :0]  current_state          ;
reg [2                :0]  next_state             ;

reg [1                :0]  load_x_num_r           ; // number of MB to load in x direction
reg [1                :0]  load_y_num_r           ; // number of MB to load in y direction
reg [1                :0]  load_x_cnt_r           ; // number of MB loading in x direction
reg [1                :0]  load_y_cnt_r           ; // number of MB loading in y direction
reg [`PIC_W_MB_LEN - 1:0]  load_x_pos_r           ; // base x coordinate of MB to load, actual = pos + cnt
reg [`PIC_H_MB_LEN - 1:0]  load_y_pos_r           ; // base y coordinate of MB to load



//ext load
reg                        ext_cst                ;
reg                        ext_nst                ;

reg                        load_r                 ; // one cycle delay of sysif_start_ld_chroma_i
reg                        ext_load_req_r         ; //
reg                        chroma_req_ext_o       ;
reg [`PIC_W_MB_LEN-1:0]    chroma_mb_x_ext_o      ;
reg [`PIC_W_MB_LEN-1:0]    chroma_mb_y_ext_o      ;

// row arrangement
reg [3                :0]  row_cnt_r              ; // 1 MB ref chroma pixels = 8 row cb + 8 row cr
reg [2                :0]  ram_wsel_r             ; // 4 row
reg [1                :0]  ram_wpt_r              ;

// read control
reg [2                :0]  ram_rsel_r             ; // ram read sel
reg signed [2         :0]  x_offset_r             ; // ram_x offset according to sw_x
reg [2                :0]  y_offset_r             ; // ram_y offset according to sw_y
reg [2                :0]  ram_offset_r           ; // actual ram offset according to ram_x offset
reg [2                :0]  addr_offset_r          ; // addr_offset according to sw_y

reg [2                :0]  ram_rd                 ;
reg [1                :0]  b_boundary             ; // 0: not boundary  1:left 2:right
reg [1                :0]  boundary_r             ;
reg                        mc_chroma_rd_crcb_d    ;

reg [8*`BIT_DEPTH-1   :0]  mc_chroma_rd_data_w    ;

// *************************************************
//
//    Wire DECLARATION
//
// *************************************************

wire [7               :0] ram_raddr_w             ;
wire                      rden_rb,rden_lb         ;
wire [8*`BIT_DEPTH-1  :0] rddata_w                ;
wire [8*`BIT_DEPTH-1  :0] rddata_rb,rddata_lb     ;
wire [7               :0] ram_waddr_w             ;

// *************************************************
//
//   CTRL FSM  Logic
//
// *************************************************
//ctrl FSM
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    current_state <= IDLE;
  else
    current_state <= next_state;
end

always @(*)begin
  case(current_state)
    IDLE :if(sysif_start_ld_chroma_i)
            next_state = LD_T;
          else
            next_state = IDLE;
    LD_T :if(sysif_start_ld_chroma_i && (sysif_mb_x_i+1'b1)>sys_total_mb_x )
            next_state = LD_S;
        else
            next_state = LD_T;
    LD_S :if(sysif_start_ld_chroma_i  && (sysif_mb_x_i+1'b1)>sys_total_mb_x && sysif_mb_y_i==(sys_total_mb_y-1'b1))
            next_state = LD_B;
          else
            next_state = LD_S;
    LD_B :if(sysif_start_ld_chroma_i && (sysif_mb_x_i+1'b1)>sys_total_mb_x)
            next_state = LD_N;
          else
            next_state = LD_B;
    LD_N :  next_state = IDLE;
  default:next_state = IDLE;
  endcase
end

//set load parameter according to state
always @(posedge clk or negedge rst_n) begin
   if(~rst_n)
      load_r <= 1'b0;
   else if(sysif_start_ld_chroma_i)
      load_r <= 1'b1;
   else
      load_r <= 1'b0;
end

// set ext_load & row_bank parameter
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    load_x_pos_r <= 'b0;
    load_y_pos_r <= 'b0;
    load_x_num_r <= 'b0;
    load_y_num_r <= 'b0;
    ram_wpt_r    <= 'b0;
  end
  else begin
    case (current_state)
      LD_T  : if(sysif_mb_x_i=='b0 && sysif_mb_y_i=='b0) begin
            load_x_pos_r <= 'd0;
            load_y_pos_r <= 'd0;
            load_x_num_r <= 'd1; // load 2x2 MB
            load_y_num_r <= 'd1;
            ram_wpt_r    <= 'd1; //?
            end
            else begin
            load_x_pos_r <= sysif_mb_x_i + 'd1;
            load_y_pos_r <= 'd0;
            load_x_num_r <= 'd0; // load 2x2 MB
            load_y_num_r <= 'd1;
            ram_wpt_r    <= 'd1; //?
            end
      LD_S  : begin
            load_x_pos_r <= (sysif_mb_x_i+1'b1)>sys_total_mb_x ? 'd0 : sysif_mb_x_i+1'b1;
            load_y_pos_r <= (sysif_mb_x_i+1'b1)>sys_total_mb_x ? sysif_mb_y_i : (sysif_mb_y_i-'d1);
            load_x_num_r <= 'd0;
            load_y_num_r <= 'd2; // load 3x1 MB
            ram_wpt_r    <= 'd0;
            end
      LD_B  : begin
            load_x_pos_r <= (sysif_mb_x_i+1'b1)>sys_total_mb_x ? 'd0 : sysif_mb_x_i+1'b1;
            load_y_pos_r <= (sysif_mb_x_i+1'b1)>sys_total_mb_x ? sysif_mb_y_i : (sysif_mb_y_i-'d1);
            load_x_num_r <= 'd0;
            load_y_num_r <= 'd1; // load 2x1 MB
            ram_wpt_r    <= 'd0;
            end
      default : begin
            load_x_pos_r <= 'd0;
            load_y_pos_r <= 'd0;
            load_x_num_r <= 'd0;
            load_y_num_r <= 'd0;
            ram_wpt_r    <= 'd0;
            end
    endcase
  end
end

// set ext load req
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    ext_load_req_r <= 1'b0;
  else if (ext_cst == EXT_LOAD && chroma_done_ext_i && load_x_cnt_r==load_x_num_r && load_y_cnt_r==load_y_num_r )
    ext_load_req_r <= 1'b0;
  else if (load_r && (current_state==LD_T || current_state==LD_S || current_state==LD_B))
    ext_load_req_r <= 1'b1;
end
// *************************************************
//
//   EXT LOAD Logic
//
// *************************************************
// ext load FSM
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    ext_cst <= EXT_WAIT;
  else
    ext_cst <= ext_nst;
end

always @(*)begin
  case(ext_cst)
    EXT_WAIT:if(ext_load_req_r)
            ext_nst = EXT_LOAD;
          else
            ext_nst = EXT_WAIT;
    EXT_LOAD :if(chroma_done_ext_i)
            ext_nst = EXT_WAIT;
          else
            ext_nst = EXT_LOAD;
    default:ext_nst = EXT_WAIT;
  endcase
end

// ext load cnt
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    load_y_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && chroma_done_ext_i) begin
    if (load_y_cnt_r == load_y_num_r)
      load_y_cnt_r <= 'b0;
    else
      load_y_cnt_r <= load_y_cnt_r + 1'b1;
  end
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    load_x_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && chroma_done_ext_i && load_y_cnt_r == load_y_num_r) begin
    if (load_x_cnt_r == load_x_num_r)
      load_x_cnt_r <= 'b0;
    else
      load_x_cnt_r <= load_x_cnt_r + 1'b1;
  end
end

// ext load output
always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    chroma_req_ext_o   <= 1'b0;
    chroma_mb_x_ext_o  <= 'b0;
    chroma_mb_y_ext_o  <= 'b0;
  end
  else if (ext_cst == EXT_LOAD) begin
    if (chroma_done_ext_i) begin
      chroma_req_ext_o   <= 1'b0;
      chroma_mb_x_ext_o  <= 'b0;
      chroma_mb_y_ext_o  <= 'b0;
    end
    else begin
      chroma_req_ext_o   <= 1'b1;
      chroma_mb_x_ext_o  <= load_x_pos_r + load_x_cnt_r; //?
      chroma_mb_y_ext_o  <= load_y_pos_r + load_y_cnt_r; //?
    end
  end
end

// load done output
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
  sysif_done_ld_chroma_o <= 1'b0;
  else if (sysif_done_ld_chroma_o)
    sysif_done_ld_chroma_o <= 1'b0;
  else if (ext_cst == EXT_LOAD && chroma_done_ext_i && load_x_cnt_r==load_x_num_r && load_y_cnt_r==load_y_num_r || (current_state == LD_N))
    sysif_done_ld_chroma_o <= 1'b1;
end

// *************************************************
//
//    RAM ARRANGEMENT
//
// *************************************************
// *************************************************
// 6 RAM: each one contains 3 MB
// MC nees
//    ___________
// R |___________| -> load_y_cnt_r=0
// A |___________| -> load_y_cnt_r=1
// M |___________| -> load_y_cnt_r=2
// 0
//    ...........
//    ___________
// R |___________| -> load_y_cnt_r=0
// A |___________| -> load_y_cnt_r=1
// M |___________| -> load_y_cnt_r=2
// 5
// ************************************************
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
  row_cnt_r <= 'b0;
  else if (ext_cst == EXT_WAIT)
    row_cnt_r <= 'b0;
  else if (ext_cst == EXT_LOAD && chroma_data_v_ext_i)
  row_cnt_r <= row_cnt_r + 1'b1;
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    ram_wsel_r <= 'b0;
  else if (ext_cst == EXT_LOAD && chroma_done_ext_i && load_y_cnt_r == load_y_num_r /*|| (current_state==LD_N)*/) begin
    if(ram_wsel_r == 5'd5)
      ram_wsel_r <= 'd0;
    else
      ram_wsel_r <= ram_wsel_r + 'd1;
  end
end

assign ram_waddr_w = ram_wsel_r*24 + (ram_wpt_r + load_y_cnt_r)*8 + {row_cnt_r[3],row_cnt_r[1:0]};

assign ram_wren_rb   = chroma_data_v_ext_i & !(row_cnt_r[2]);
assign ram_wren_lb   = chroma_data_v_ext_i &  (row_cnt_r[2]);


// *************************************************
//
//    READ CONTROL
//
// *************************************************
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)
    ram_rsel_r <= 'd0;
  else if (mc_chroma_rd_done_i) begin
    if(ram_rsel_r == 5'd5)
      ram_rsel_r <= 'd0;
    else
      ram_rsel_r <= ram_rsel_r + 'd1;
  end
end
// Read Address Mapping

// general mc_chroma_rd_sw_x_i  => ram offset rules
//  ______________________________________________________________________________
// |mc_chroma_rd_sw_x_i[`SW_W_LEN-2:`SW_W_LEN-3]     |      ram offset            |
// -------------------------------------------------------------------------------
// |                  3'b1xx                         |           -2               |
// |                  3'b000                         |           -1               |
// |                  3'b001                         |            0               |
// |                  3'b010                         |            1               |
// |                  3'b011                         |            2               |
// |_________________________________________________|____________________________|

always @(*) begin
  if(mc_chroma_rd_sw_x_i[`SW_W_LEN-1])
    x_offset_r = 3'b110;                                           // ram offset = -2
  else if(mc_chroma_rd_sw_x_i[`SW_W_LEN-2:`SW_W_LEN-3] == 2'b00)
    x_offset_r = 3'b111;                                           // ram offset = -1
  else
    x_offset_r = mc_chroma_rd_sw_x_i[`SW_W_LEN-2:`SW_W_LEN-3] - 'd1; // ram offset = 0, 1, 2
end

// exception
// always @(*) begin
//   if ((mc_chroma_rd_mb_x_i == 0) && (x_offset_r < 0)) begin
//     ram_offset_r = 'd0;
//     //b_boundary = 'd1;
//   end
//   else if((mc_chroma_rd_mb_x_i == sys_total_mb_x) && (x_offset_r > 0)) begin
//     ram_offset_r = 'd0;
//     //b_boundary = 'd2;
//   end
//   else begin
//     ram_offset_r = x_offset_r;
//     //b_boundary = 'd0;
//   end
// end

always @(*) begin
  if ((mc_chroma_rd_mb_x_i == 0) && (x_offset_r < 0))
    ram_offset_r = 'd0;
  else if((mc_chroma_rd_mb_x_i == 1) && (x_offset_r == 3'b110))
    ram_offset_r = 3'b111;
  else if((mc_chroma_rd_mb_x_i == sys_total_mb_x) && (x_offset_r > 0))
    ram_offset_r = 'd0;
  else if((mc_chroma_rd_mb_x_i == (sys_total_mb_x - 1)) && (x_offset_r == 3'b010))
    ram_offset_r = 3'b001;
  else
    ram_offset_r = x_offset_r;
end

always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    boundary_r <= 'd0;
  else if((mc_chroma_rd_mb_x_i == 0) && (x_offset_r[2]))
    boundary_r <= 'd01;
  else if((mc_chroma_rd_mb_x_i == 1) && (x_offset_r == 3'b110))
    boundary_r <= 'd01;
  else if((mc_chroma_rd_mb_x_i == sys_total_mb_x) && (x_offset_r > 0))
    boundary_r <= 'd02;
  else if((mc_chroma_rd_mb_x_i == (sys_total_mb_x -1)) && (x_offset_r == 3'b010))
    boundary_r <= 'd02;
  else
    boundary_r <= 'd0;
end



always @(*) begin
  if((mc_chroma_rd_mb_y_i == 0) && (mc_chroma_rd_sw_y_i[`SW_H_LEN-2:`SW_H_LEN-3] == 2'b00))  begin // 0-7
    y_offset_r = 2'b1;
    addr_offset_r = {{3{|mc_chroma_rd_sw_y_i[4:3]}}&mc_chroma_rd_sw_y_i[2:0]};
  end
  else if(mc_chroma_rd_mb_y_i == sys_total_mb_y && (mc_chroma_rd_sw_y_i[`SW_H_LEN-2:`SW_H_LEN-3] == 2'b10))  begin//  16-23
    y_offset_r = 2'b1;
    addr_offset_r = {{3{mc_chroma_rd_sw_y_i[4]}}|mc_chroma_rd_sw_y_i[2:0]};
  end
  else begin
    y_offset_r = mc_chroma_rd_sw_y_i[`SW_H_LEN-2:`SW_H_LEN-3];
    addr_offset_r = mc_chroma_rd_sw_y_i[2:0];
  end
end

wire [2:0] ram_rd_tmp;

assign ram_rd_tmp = ram_rsel_r + ram_offset_r;

// real ram to read
always @(*) begin
  if(ram_rsel_r[2]) begin                      // ram_rsel_r = 4 | 5
    if(ram_rd_tmp > 'd5)
      ram_rd = ram_rd_tmp - 'd6;
    else
      ram_rd = ram_rd_tmp;
  end
  else if(ram_rsel_r[2:1] == 'd0) begin           // ram_rsel_r = 0 | 1
    if(ram_rd_tmp[2])
      ram_rd = ram_rd_tmp + 'd6;
    else
      ram_rd = ram_rd_tmp;
  end
  else
    ram_rd = ram_rd_tmp;
end

//assign ram_rd = (ram_rsel_r+ram_offset_r < 0) ? (ram_rsel_r+ram_offset_r + 3'd6) : ((ram_rsel_r+ram_offset_r > 3'd5) ? (ram_rsel_r+ram_offset_r - 3'd6):ram_rsel_r+ram_offset_r);

assign ram_raddr_w =  ram_rd*24 + y_offset_r*8 + addr_offset_r;

always @(posedge clk or negedge rst_n) begin
   if(!rst_n) begin
    mc_chroma_rd_crcb_d <= 'd0;
   end
   else begin
    mc_chroma_rd_crcb_d <= mc_chroma_rd_crcb_i; // 1 cycle delay due to read delay!
   end
end

assign rden_rb   = mc_chroma_rd_en_i & (~mc_chroma_rd_crcb_i);
assign rden_lb   = mc_chroma_rd_en_i & (mc_chroma_rd_crcb_i);
assign mc_chroma_rd_ack_o = (rden_rb)|(rden_lb);

// ram module
fetch_ram_2p_64x144 left_bank0(
    .clk_i ( clk               ),
    .wren  ( ram_wren_lb       ),
    .wraddr( ram_waddr_w       ),
    .wrdata( chroma_data_ext_i ),
    .rden  ( rden_lb           ),
    .rdaddr( ram_raddr_w       ),
    .rddata( rddata_lb         )
);

fetch_ram_2p_64x144 right_bank0(
    .clk_i ( clk               ),
    .wren  ( ram_wren_rb       ),
    .wraddr( ram_waddr_w       ),
    .wrdata( chroma_data_ext_i ),
    .rden  ( rden_rb           ),
    .rdaddr( ram_raddr_w       ),
    .rddata( rddata_rb         )
);


// read output
assign rddata_w = (~mc_chroma_rd_crcb_d)?rddata_rb:rddata_lb; //0:cb,1:cr

always @( * ) begin
  case (boundary_r)
    2'd1: mc_chroma_rd_data_w = {8{rddata_w[`BIT_DEPTH-1:0]}};
    2'd2: mc_chroma_rd_data_w = {8{rddata_w[8*`BIT_DEPTH-1:7*`BIT_DEPTH]}};
     default : mc_chroma_rd_data_w = rddata_w;
  endcase
end

//assign mc_chroma_rd_data_o = (mc_chroma_rd_ack_o)? (mc_chroma_rd_data_w) : 64'b0;
assign mc_chroma_rd_data_o = (mc_chroma_rd_data_w);

endmodule
