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
// Filename       : interpolator_4pel.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------  
`include "enc_defines.v"

`define  HF_EXWIDTH 7  //half filter extend bit width

module mc_ip_4pel(
                    clk_i,
                    rst_n_i,
                    
                    half_ip_flag_i,
                    yHFracl_i,
                    xHFracl_i,
                    
                    end_oneblk_input_i,//һ��������Ҫ�Ĳ�ֵ�������
                    area_co_locate_i,
                    end_oneblk_ip_o,
                    
                    refpel_valid_i,
                    ref_pel0_i,
                    ref_pel1_i,
                    ref_pel2_i,
                    ref_pel3_i,
                    ref_pel4_i,
                    ref_pel5_i,
                    ref_pel6_i,
                    ref_pel7_i,
                    ref_pel8_i,
                    ref_pel9_i,
                    
                    candi_valid_o,
                    candi0_0_o, candi1_0_o, candi2_0_o,
                    candi0_1_o, candi1_1_o, candi2_1_o,
                    candi0_2_o, candi1_2_o, candi2_2_o,
                    candi0_3_o, candi1_3_o, candi2_3_o,
                    
                    candi3_0_o, candi4_0_o, candi5_0_o,
                    candi3_1_o, candi4_1_o, candi5_1_o,
                    candi3_2_o, candi4_2_o, candi5_2_o,
                    candi3_3_o, candi4_3_o, candi5_3_o,
                    
                    candi6_0_o, candi7_0_o, candi8_0_o,
                    candi6_1_o, candi7_1_o, candi8_1_o,
                    candi6_2_o, candi7_2_o, candi8_2_o,
                    candi6_3_o, candi7_3_o, candi8_3_o
);


parameter DIA_TMP_BITS = `BIT_DEPTH+2*`HF_EXWIDTH;

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input clk_i;
input rst_n_i;

input                   half_ip_flag_i;
input  [2:0]            xHFracl_i,yHFracl_i;
input                   end_oneblk_input_i;
input                   area_co_locate_i;
output                  end_oneblk_ip_o;

input                   refpel_valid_i;
input  [`BIT_DEPTH-1:0] ref_pel0_i, ref_pel1_i, ref_pel2_i, ref_pel3_i, ref_pel4_i;
input  [`BIT_DEPTH-1:0] ref_pel5_i, ref_pel6_i, ref_pel7_i, ref_pel8_i, ref_pel9_i;

output                   candi_valid_o;
output  [`BIT_DEPTH-1:0] candi0_0_o, candi1_0_o, candi2_0_o;
output  [`BIT_DEPTH-1:0] candi0_1_o, candi1_1_o, candi2_1_o;
output  [`BIT_DEPTH-1:0] candi0_2_o, candi1_2_o, candi2_2_o;
output  [`BIT_DEPTH-1:0] candi0_3_o, candi1_3_o, candi2_3_o;

output  [`BIT_DEPTH-1:0] candi3_0_o, candi4_0_o, candi5_0_o;
output  [`BIT_DEPTH-1:0] candi3_1_o, candi4_1_o, candi5_1_o;
output  [`BIT_DEPTH-1:0] candi3_2_o, candi4_2_o, candi5_2_o;
output  [`BIT_DEPTH-1:0] candi3_3_o, candi4_3_o, candi5_3_o;
       
output  [`BIT_DEPTH-1:0] candi6_0_o, candi7_0_o, candi8_0_o;
output  [`BIT_DEPTH-1:0] candi6_1_o, candi7_1_o, candi8_1_o;
output  [`BIT_DEPTH-1:0] candi6_2_o, candi7_2_o, candi8_2_o;
output  [`BIT_DEPTH-1:0] candi6_3_o, candi7_3_o, candi8_3_o;
  

// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************  
//internal registers
reg [`BIT_DEPTH-1:0] ref_pel0, ref_pel1, ref_pel2, ref_pel3;
reg [`BIT_DEPTH-1:0] ref_pel4, ref_pel5, ref_pel6, ref_pel7;
reg [`BIT_DEPTH-1:0] ref_pel8, ref_pel9;

reg [3:0]            end_delay;
reg                  hcandi_valid,qcandi_valid;
reg [4:0]            valid_delay;

reg [`BIT_DEPTH-1:0] int_pel00, int_pel01, int_pel02, int_pel03, int_pel04, int_pel05;
reg [`BIT_DEPTH-1:0] int_pel10, int_pel11, int_pel12, int_pel13, int_pel14, int_pel15;
reg [`BIT_DEPTH-1:0] int_pel20, int_pel21, int_pel22, int_pel23, int_pel24, int_pel25;
reg [`BIT_DEPTH-1:0] int_pel30, int_pel31, int_pel32, int_pel33, int_pel34, int_pel35;
reg [`BIT_DEPTH-1:0] int_pel40, int_pel41, int_pel42, int_pel43, int_pel44, int_pel45;
reg [`BIT_DEPTH-1:0] int_pel50, int_pel51, int_pel52, int_pel53, int_pel54, int_pel55;

reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel00, hor_halfpel01, hor_halfpel02;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel03, hor_halfpel04;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel10, hor_halfpel11, hor_halfpel12;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel13, hor_halfpel14;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel20, hor_halfpel21, hor_halfpel22;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel23, hor_halfpel24;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel30, hor_halfpel31, hor_halfpel32;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel33, hor_halfpel34;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel40, hor_halfpel41, hor_halfpel42;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel43, hor_halfpel44;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel50, hor_halfpel51, hor_halfpel52;
reg  [`BIT_DEPTH+`HF_EXWIDTH-1:0] hor_halfpel53, hor_halfpel54;

reg  [`BIT_DEPTH-1:0] dia_hp00, dia_hp01, dia_hp02, dia_hp03, dia_hp04;
reg  [`BIT_DEPTH-1:0] dia_hp10, dia_hp11, dia_hp12, dia_hp13, dia_hp14;
reg  [`BIT_DEPTH-1:0] ver_hp00, ver_hp01, ver_hp02, ver_hp03, ver_hp04, ver_hp05; 
reg  [`BIT_DEPTH-1:0] ver_hp10, ver_hp11, ver_hp12, ver_hp13, ver_hp14, ver_hp15;
reg  [`BIT_DEPTH-1:0] hor_pel0, hor_pel1, hor_pel2, hor_pel3, hor_pel4;
reg  [`BIT_DEPTH-1:0] bf0_0_in0, bf1_0_in0, bf2_0_in0, bf3_0_in0;
reg  [`BIT_DEPTH-1:0] bf4_0_in0, bf5_0_in0, bf6_0_in0, bf7_0_in0, bf8_0_in0;
reg  [`BIT_DEPTH-1:0] bf0_1_in0, bf1_1_in0, bf2_1_in0, bf3_1_in0;
reg  [`BIT_DEPTH-1:0] bf4_1_in0, bf5_1_in0, bf6_1_in0, bf7_1_in0, bf8_1_in0;
reg  [`BIT_DEPTH-1:0] bf0_2_in0, bf1_2_in0, bf2_2_in0, bf3_2_in0;
reg  [`BIT_DEPTH-1:0] bf4_2_in0, bf5_2_in0, bf6_2_in0, bf7_2_in0, bf8_2_in0;
reg  [`BIT_DEPTH-1:0] bf0_3_in0, bf1_3_in0, bf2_3_in0, bf3_3_in0;
reg  [`BIT_DEPTH-1:0] bf4_3_in0, bf5_3_in0, bf6_3_in0, bf7_3_in0, bf8_3_in0;
reg  [`BIT_DEPTH-1:0] bf0_0_in1, bf1_0_in1, bf2_0_in1, bf3_0_in1;
reg  [`BIT_DEPTH-1:0] bf4_0_in1, bf5_0_in1, bf6_0_in1, bf7_0_in1, bf8_0_in1;
reg  [`BIT_DEPTH-1:0] bf0_1_in1, bf1_1_in1, bf2_1_in1, bf3_1_in1;
reg  [`BIT_DEPTH-1:0] bf4_1_in1, bf5_1_in1, bf6_1_in1, bf7_1_in1, bf8_1_in1;
reg  [`BIT_DEPTH-1:0] bf0_2_in1, bf1_2_in1, bf2_2_in1, bf3_2_in1;
reg  [`BIT_DEPTH-1:0] bf4_2_in1, bf5_2_in1, bf6_2_in1, bf7_2_in1, bf8_2_in1;
reg  [`BIT_DEPTH-1:0] bf0_3_in1, bf1_3_in1, bf2_3_in1, bf3_3_in1;
reg  [`BIT_DEPTH-1:0] bf4_3_in1, bf5_3_in1, bf6_3_in1, bf7_3_in1, bf8_3_in1;

reg  [`BIT_DEPTH-1:0] bf4_0_out_r,bf4_1_out_r,bf4_2_out_r,bf4_3_out_r;
reg  [`BIT_DEPTH-1:0] quar_pel0_0, quar_pel0_1,quar_pel0_2,quar_pel0_3;
reg  [`BIT_DEPTH-1:0] quar_pel1_0, quar_pel1_1,quar_pel1_2,quar_pel1_3;
reg  [`BIT_DEPTH-1:0] quar_pel2_0, quar_pel2_1,quar_pel2_2,quar_pel2_3;
reg  [`BIT_DEPTH-1:0] quar_pel3_0, quar_pel3_1,quar_pel3_2,quar_pel3_3;
reg  [`BIT_DEPTH-1:0] quar_pel4_0, quar_pel4_1,quar_pel4_2,quar_pel4_3;
reg  [`BIT_DEPTH-1:0] quar_pel5_0, quar_pel5_1,quar_pel5_2,quar_pel5_3;
reg  [`BIT_DEPTH-1:0] quar_pel6_0, quar_pel6_1,quar_pel6_2,quar_pel6_3;
reg  [`BIT_DEPTH-1:0] quar_pel7_0, quar_pel7_1,quar_pel7_2,quar_pel7_3;
reg  [`BIT_DEPTH-1:0] quar_pel8_0, quar_pel8_1,quar_pel8_2,quar_pel8_3;




// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
//internal wires
wire [`BIT_DEPTH+`HF_EXWIDTH-1:0]   hor_halfpel_tmp0, hor_halfpel_tmp1, hor_halfpel_tmp2;//15bits
wire [`BIT_DEPTH+`HF_EXWIDTH-1:0]   hor_halfpel_tmp3, hor_halfpel_tmp4;
wire [`BIT_DEPTH+2*`HF_EXWIDTH-1:0] dia_halfpel_tmp0, dia_halfpel_tmp1, dia_halfpel_tmp2;
wire [`BIT_DEPTH+2*`HF_EXWIDTH-1:0] dia_halfpel_tmp3, dia_halfpel_tmp4;
wire [`BIT_DEPTH+`HF_EXWIDTH-1:0]   ver_halfpel0, ver_halfpel1, ver_halfpel2; 
wire [`BIT_DEPTH+`HF_EXWIDTH-1:0]   ver_halfpel3, ver_halfpel4, ver_halfpel5;
wire                       down_shift;
wire [DIA_TMP_BITS-1:0]    dia_hp_tmp0, dia_hp_tmp1, dia_hp_tmp2, dia_hp_tmp3, dia_hp_tmp4;
wire [DIA_TMP_BITS-1-10:0] dia_hp0_w, dia_hp1_w, dia_hp2_w, dia_hp3_w, dia_hp4_w;
wire [`BIT_DEPTH+`HF_EXWIDTH-1-5:0]  ver_hp_tmp0, ver_hp_tmp1, ver_hp_tmp2, ver_hp_tmp3;
wire [`BIT_DEPTH+`HF_EXWIDTH-1-5:0]  ver_hp_tmp4, ver_hp_tmp5;
wire [`BIT_DEPTH+`HF_EXWIDTH -1 - 5:0] hor_hp_tmp0, hor_hp_tmp1, hor_hp_tmp2, hor_hp_tmp3, hor_hp_tmp4;
wire [`BIT_DEPTH-1:0] hor_pel0_w, hor_pel1_w, hor_pel2_w, hor_pel3_w, hor_pel4_w;
wire [`BIT_DEPTH-1:0] bf0_0_out, bf1_0_out, bf2_0_out, bf3_0_out;
wire [`BIT_DEPTH-1:0] bf4_0_out, bf5_0_out, bf6_0_out, bf7_0_out, bf8_0_out;
wire [`BIT_DEPTH-1:0] bf0_1_out, bf1_1_out, bf2_1_out, bf3_1_out;
wire [`BIT_DEPTH-1:0] bf4_1_out, bf5_1_out, bf6_1_out, bf7_1_out, bf8_1_out;
wire [`BIT_DEPTH-1:0] bf0_2_out, bf1_2_out, bf2_2_out, bf3_2_out;
wire [`BIT_DEPTH-1:0] bf4_2_out, bf5_2_out, bf6_2_out, bf7_2_out, bf8_2_out;
wire [`BIT_DEPTH-1:0] bf0_3_out, bf1_3_out, bf2_3_out, bf3_3_out;
wire [`BIT_DEPTH-1:0] bf4_3_out, bf5_3_out, bf6_3_out, bf7_3_out, bf8_3_out;
wire [`BIT_DEPTH+`HF_EXWIDTH -1 - 5:0] hor0_hp4qp0_w, hor0_hp4qp1_w, hor0_hp4qp2_w;
wire [`BIT_DEPTH+`HF_EXWIDTH -1 - 5:0] hor0_hp4qp3_w, hor0_hp4qp4_w;
wire [`BIT_DEPTH-1:0] hor0_hp4qp0, hor0_hp4qp1, hor0_hp4qp2, hor0_hp4qp3, hor0_hp4qp4;
wire [`BIT_DEPTH-1:0] hor1_hp4qp0, hor1_hp4qp1, hor1_hp4qp2, hor1_hp4qp3, hor1_hp4qp4;
wire [`BIT_DEPTH-1:0] hor2_hp4qp0, hor2_hp4qp1, hor2_hp4qp2, hor2_hp4qp3, hor2_hp4qp4;

    
// ********************************************
//                                             
//    Sequential Logic   Combinational Logic 
//                                             
// ********************************************
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    ref_pel0 <= 0;   ref_pel5 <= 0;
    ref_pel1 <= 0;   ref_pel6 <= 0;
    ref_pel2 <= 0;   ref_pel7 <= 0;
    ref_pel3 <= 0;   ref_pel8 <= 0;
    ref_pel4 <= 0;   ref_pel9 <= 0;
  end
  else if(refpel_valid_i) begin
    ref_pel0 <= ref_pel0_i;  ref_pel1 <= ref_pel1_i;
    ref_pel2 <= ref_pel2_i;  ref_pel3 <= ref_pel3_i;
    ref_pel4 <= ref_pel4_i;  ref_pel5 <= ref_pel5_i;
    ref_pel6 <= ref_pel6_i;  ref_pel7 <= ref_pel7_i;
    ref_pel8 <= ref_pel8_i;  ref_pel9 <= ref_pel9_i;
  end
  else begin
    ref_pel0 <= ref_pel0;  ref_pel1 <= ref_pel1;
    ref_pel2 <= ref_pel2;  ref_pel3 <= ref_pel3;
    ref_pel4 <= ref_pel4;  ref_pel5 <= ref_pel5;
    ref_pel6 <= ref_pel6;  ref_pel7 <= ref_pel7;
    ref_pel8 <= ref_pel8;  ref_pel9 <= ref_pel9;
  end
end
    
///////////////////////////////////////////////////////////////////////////////
//5 horizontal filters
half_filter            hor_hf0(
    .clk_i         ( clk_i    ),
    .rst_n_i       ( rst_n_i  ),
    .pel0_i        ( ref_pel0 ),
    .pel1_i        ( ref_pel1 ),
    .pel2_i        ( ref_pel2 ),
    .pel3_i        ( ref_pel3 ),
    .pel4_i        ( ref_pel4 ),
    .pel5_i        ( ref_pel5 ),
    .halfpel_tmp_o ( hor_halfpel_tmp0 )
);
half_filter            hor_hf1(
    .clk_i         ( clk_i    ),
    .rst_n_i       ( rst_n_i  ),
    .pel0_i        ( ref_pel1 ),
    .pel1_i        ( ref_pel2 ),
    .pel2_i        ( ref_pel3 ),
    .pel3_i        ( ref_pel4 ),
    .pel4_i        ( ref_pel5 ),
    .pel5_i        ( ref_pel6 ),
    .halfpel_tmp_o ( hor_halfpel_tmp1 )
);
half_filter            hor_hf2(
    .clk_i         ( clk_i    ),
    .rst_n_i       ( rst_n_i  ),
    .pel0_i        ( ref_pel2 ),
    .pel1_i        ( ref_pel3 ),
    .pel2_i        ( ref_pel4 ),
    .pel3_i        ( ref_pel5 ),
    .pel4_i        ( ref_pel6 ),
    .pel5_i        ( ref_pel7 ),
    .halfpel_tmp_o ( hor_halfpel_tmp2 )
);
half_filter            hor_hf3(
    .clk_i         ( clk_i    ),
    .rst_n_i       ( rst_n_i  ),
    .pel0_i        ( ref_pel3 ),
    .pel1_i        ( ref_pel4 ),
    .pel2_i        ( ref_pel5 ),
    .pel3_i        ( ref_pel6 ),
    .pel4_i        ( ref_pel7 ),
    .pel5_i        ( ref_pel8 ),
    .halfpel_tmp_o ( hor_halfpel_tmp3 )
);
half_filter            hor_hf4(
    .clk_i         ( clk_i    ),
    .rst_n_i       ( rst_n_i  ),
    .pel0_i        ( ref_pel4 ),
    .pel1_i        ( ref_pel5 ),
    .pel2_i        ( ref_pel6 ),
    .pel3_i        ( ref_pel7 ),
    .pel4_i        ( ref_pel8 ),
    .pel5_i        ( ref_pel9 ),
    .halfpel_tmp_o ( hor_halfpel_tmp4 )
);

///////////////////////////////////////////////////////////////////////////////
//5 diaganol filters
    
half_filter_d #(.INPUTWIDTH(`BIT_DEPTH+`HF_EXWIDTH)) 
	                        dia_hf0(
    .clk_i         ( clk_i         ),
    .rst_n_i       ( rst_n_i       ),
    .pel0_i        ( hor_halfpel00 ),
    .pel1_i        ( hor_halfpel10 ),
    .pel2_i        ( hor_halfpel20 ),
    .pel3_i        ( hor_halfpel30 ),
    .pel4_i        ( hor_halfpel40 ),
    .pel5_i        ( hor_halfpel50 ),
    .halfpel_tmp_o ( dia_halfpel_tmp0 )
);
half_filter_d #(.INPUTWIDTH(`BIT_DEPTH+`HF_EXWIDTH)) 
                            dia_hf1(
    .clk_i         ( clk_i         ),
    .rst_n_i       ( rst_n_i       ),
    .pel0_i        ( hor_halfpel01 ),
    .pel1_i        ( hor_halfpel11 ),
    .pel2_i        ( hor_halfpel21 ),
    .pel3_i        ( hor_halfpel31 ),
    .pel4_i        ( hor_halfpel41 ),
    .pel5_i        ( hor_halfpel51 ),
    .halfpel_tmp_o ( dia_halfpel_tmp1 )
);
half_filter_d #(.INPUTWIDTH(`BIT_DEPTH+`HF_EXWIDTH)) dia_hf2(
    .clk_i         (clk_i        ),
    .rst_n_i       (rst_n_i      ),
    .pel0_i        (hor_halfpel02),
    .pel1_i        (hor_halfpel12),
    .pel2_i        (hor_halfpel22),
    .pel3_i        (hor_halfpel32),
    .pel4_i        (hor_halfpel42),
    .pel5_i        (hor_halfpel52),
    .halfpel_tmp_o (dia_halfpel_tmp2)
);
half_filter_d #(.INPUTWIDTH(`BIT_DEPTH+`HF_EXWIDTH)) dia_hf3(
             .clk_i         (clk_i),
             .rst_n_i       (rst_n_i),
             .pel0_i        (hor_halfpel03),
             .pel1_i        (hor_halfpel13),
             .pel2_i        (hor_halfpel23),
             .pel3_i        (hor_halfpel33),
             .pel4_i        (hor_halfpel43),
             .pel5_i        (hor_halfpel53),
             .halfpel_tmp_o (dia_halfpel_tmp3)
             );
half_filter_d #(.INPUTWIDTH(`BIT_DEPTH+`HF_EXWIDTH)) dia_hf4(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (hor_halfpel04),
                 .pel1_i        (hor_halfpel14),
                 .pel2_i        (hor_halfpel24),
                 .pel3_i        (hor_halfpel34),
                 .pel4_i        (hor_halfpel44),
                 .pel5_i        (hor_halfpel54),
                 .halfpel_tmp_o (dia_halfpel_tmp4)
                 );
                 
///////////////////////////////////////////////////////////////////////////////
//6 vertical filters 
    //internal wires
half_filter ver_hf0(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel00),
                 .pel1_i        (int_pel10),
                 .pel2_i        (int_pel20),
                 .pel3_i        (int_pel30),
                 .pel4_i        (int_pel40),
                 .pel5_i        (int_pel50),
                 .halfpel_tmp_o (ver_halfpel0)
                 );
    half_filter ver_hf1(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel01),
                 .pel1_i        (int_pel11),
                 .pel2_i        (int_pel21),
                 .pel3_i        (int_pel31),
                 .pel4_i        (int_pel41),
                 .pel5_i        (int_pel51),
                 .halfpel_tmp_o (ver_halfpel1)
                 );
    half_filter ver_hf2(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel02),
                 .pel1_i        (int_pel12),
                 .pel2_i        (int_pel22),
                 .pel3_i        (int_pel32),
                 .pel4_i        (int_pel42),
                 .pel5_i        (int_pel52),
                 .halfpel_tmp_o (ver_halfpel2)
                 );
    half_filter ver_hf3(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel03),
                 .pel1_i        (int_pel13),
                 .pel2_i        (int_pel23),
                 .pel3_i        (int_pel33),
                 .pel4_i        (int_pel43),
                 .pel5_i        (int_pel53),
                 .halfpel_tmp_o (ver_halfpel3)
                 );
    half_filter ver_hf4(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel04),
                 .pel1_i        (int_pel14),
                 .pel2_i        (int_pel24),
                 .pel3_i        (int_pel34),
                 .pel4_i        (int_pel44),
                 .pel5_i        (int_pel54),
                 .halfpel_tmp_o (ver_halfpel4)
                 );
    half_filter ver_hf5(
                 .clk_i         (clk_i),
                 .rst_n_i       (rst_n_i),
                 .pel0_i        (int_pel05),
                 .pel1_i        (int_pel15),
                 .pel2_i        (int_pel25),
                 .pel3_i        (int_pel35),
                 .pel4_i        (int_pel45),
                 .pel5_i        (int_pel55),
                 .halfpel_tmp_o (ver_halfpel5)
                 );
                 
///////////////////////////////////////////////////////////////////////////////
//      register shift
///////////////////////////////////////////////////////////////////////////////

//half pels and quater pels ��ʱ��һ����
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    end_delay <= 0;
  else
    end_delay <= {end_delay[2:0],end_oneblk_input_i};
end
assign down_shift = refpel_valid_i||(|end_delay[1:0]);

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    valid_delay <= 0;
  else
    if(down_shift)
      valid_delay <= {valid_delay[3:0],area_co_locate_i};
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    hcandi_valid <= 1'b0;
    qcandi_valid <= 1'b0;
  end
  else  begin
    hcandi_valid <= (valid_delay[4] & down_shift);
    qcandi_valid <= hcandi_valid;
  end
end

assign candi_valid_o = (half_ip_flag_i)?hcandi_valid:qcandi_valid;
assign end_oneblk_ip_o = (half_ip_flag_i)?end_delay[2]:end_delay[3];

///////////////////////////////////////////////////////////////////////////////
// the integer pixel shift registors for 6 vertical filters
    always @(posedge clk_i or negedge rst_n_i) begin
      if(!rst_n_i) begin
        int_pel00 <= 0; int_pel01 <= 0; int_pel02 <= 0; int_pel03 <= 0; int_pel04 <= 0; int_pel05 <= 0;
        int_pel10 <= 0; int_pel11 <= 0; int_pel12 <= 0; int_pel13 <= 0; int_pel14 <= 0; int_pel15 <= 0;
        int_pel20 <= 0; int_pel21 <= 0; int_pel22 <= 0; int_pel23 <= 0; int_pel24 <= 0; int_pel25 <= 0;
        int_pel30 <= 0; int_pel31 <= 0; int_pel32 <= 0; int_pel33 <= 0; int_pel34 <= 0; int_pel35 <= 0;
        int_pel40 <= 0; int_pel41 <= 0; int_pel42 <= 0; int_pel43 <= 0; int_pel44 <= 0; int_pel45 <= 0;
        int_pel50 <= 0; int_pel51 <= 0; int_pel52 <= 0; int_pel53 <= 0; int_pel54 <= 0; int_pel55 <= 0;
      end
      else if(down_shift)begin
        int_pel00 <= ref_pel2;
        int_pel01 <= ref_pel3;
        int_pel02 <= ref_pel4;
        int_pel03 <= ref_pel5;
        int_pel04 <= ref_pel6;
        int_pel05 <= ref_pel7;
        
        int_pel10 <= int_pel00;
        int_pel11 <= int_pel01;
        int_pel12 <= int_pel02;
        int_pel13 <= int_pel03;
        int_pel14 <= int_pel04;
        int_pel15 <= int_pel05;
        
        int_pel20 <= int_pel10;
        int_pel21 <= int_pel11;
        int_pel22 <= int_pel12;
        int_pel23 <= int_pel13;
        int_pel24 <= int_pel14;
        int_pel25 <= int_pel15;
        
        int_pel30 <= int_pel20;
        int_pel31 <= int_pel21;
        int_pel32 <= int_pel22;
        int_pel33 <= int_pel23;
        int_pel34 <= int_pel24;
        int_pel35 <= int_pel25;
        
        int_pel40 <= int_pel30;
        int_pel41 <= int_pel31;
        int_pel42 <= int_pel32;
        int_pel43 <= int_pel33;
        int_pel44 <= int_pel34;
        int_pel45 <= int_pel35;
        
        int_pel50 <= int_pel40;
        int_pel51 <= int_pel41;
        int_pel52 <= int_pel42;
        int_pel53 <= int_pel43;
        int_pel54 <= int_pel44;
        int_pel55 <= int_pel45;

      end
    end
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//horizontal intermediate half pels for 5 diaganol filters
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    hor_halfpel00 <= 0; hor_halfpel01 <= 0; hor_halfpel02 <= 0; hor_halfpel03 <= 0; hor_halfpel04 <= 0;
    hor_halfpel10 <= 0; hor_halfpel11 <= 0; hor_halfpel12 <= 0; hor_halfpel13 <= 0; hor_halfpel14 <= 0;
    hor_halfpel20 <= 0; hor_halfpel21 <= 0; hor_halfpel22 <= 0; hor_halfpel23 <= 0; hor_halfpel24 <= 0;
    hor_halfpel30 <= 0; hor_halfpel31 <= 0; hor_halfpel32 <= 0; hor_halfpel33 <= 0; hor_halfpel34 <= 0;
    hor_halfpel40 <= 0; hor_halfpel41 <= 0; hor_halfpel42 <= 0; hor_halfpel43 <= 0; hor_halfpel44 <= 0;
    hor_halfpel50 <= 0; hor_halfpel51 <= 0; hor_halfpel52 <= 0; hor_halfpel53 <= 0; hor_halfpel54 <= 0;
  end
  else if(down_shift) begin
    hor_halfpel00 <= hor_halfpel_tmp0;
    hor_halfpel01 <= hor_halfpel_tmp1;
    hor_halfpel02 <= hor_halfpel_tmp2;
    hor_halfpel03 <= hor_halfpel_tmp3;
    hor_halfpel04 <= hor_halfpel_tmp4;
    
    hor_halfpel10 <= hor_halfpel00;
    hor_halfpel11 <= hor_halfpel01;
    hor_halfpel12 <= hor_halfpel02;
    hor_halfpel13 <= hor_halfpel03;
    hor_halfpel14 <= hor_halfpel04;
    
    hor_halfpel20 <= hor_halfpel10;
    hor_halfpel21 <= hor_halfpel11;
    hor_halfpel22 <= hor_halfpel12;
    hor_halfpel23 <= hor_halfpel13;
    hor_halfpel24 <= hor_halfpel14;
    
    hor_halfpel30 <= hor_halfpel20;
    hor_halfpel31 <= hor_halfpel21;
    hor_halfpel32 <= hor_halfpel22;
    hor_halfpel33 <= hor_halfpel23;
    hor_halfpel34 <= hor_halfpel24;
    
    hor_halfpel40 <= hor_halfpel30;
    hor_halfpel41 <= hor_halfpel31;
    hor_halfpel42 <= hor_halfpel32;
    hor_halfpel43 <= hor_halfpel33;
    hor_halfpel44 <= hor_halfpel34;
    
    hor_halfpel50 <= hor_halfpel40;
    hor_halfpel51 <= hor_halfpel41;
    hor_halfpel52 <= hor_halfpel42;
    hor_halfpel53 <= hor_halfpel43;
    hor_halfpel54 <= hor_halfpel44;
  end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//   output
///////////////////////////////////////////////////////////////////////////////
    //output diagnoal half pels registers

	   
    assign dia_hp_tmp0 = (dia_halfpel_tmp0 + 22'd512);
    assign dia_hp_tmp1 = (dia_halfpel_tmp1 + 22'd512);
    assign dia_hp_tmp2 = (dia_halfpel_tmp2 + 22'd512);
    assign dia_hp_tmp3 = (dia_halfpel_tmp3 + 22'd512);
    assign dia_hp_tmp4 = (dia_halfpel_tmp4 + 22'd512);
    
    assign dia_hp0_w = dia_hp_tmp0[DIA_TMP_BITS-1:10];
    assign dia_hp1_w = dia_hp_tmp1[DIA_TMP_BITS-1:10];
    assign dia_hp2_w = dia_hp_tmp2[DIA_TMP_BITS-1:10];
    assign dia_hp3_w = dia_hp_tmp3[DIA_TMP_BITS-1:10];
    assign dia_hp4_w = dia_hp_tmp4[DIA_TMP_BITS-1:10];
        
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    dia_hp00 <= 0;
    dia_hp01 <= 0;
    dia_hp02 <= 0;
    dia_hp03 <= 0;
    dia_hp04 <= 0;
    
    dia_hp10 <= 0;
    dia_hp11 <= 0;
    dia_hp12 <= 0;
    dia_hp13 <= 0;
    dia_hp14 <= 0;
  end
  else if(down_shift) begin
    dia_hp00 <= (dia_hp0_w[DIA_TMP_BITS-1-10])?`BIT_DEPTH'b0:
      (dia_hp0_w[DIA_TMP_BITS-1-10-1:`BIT_DEPTH] == 0)?dia_hp0_w[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    dia_hp01 <= (dia_hp1_w[DIA_TMP_BITS-1-10])?`BIT_DEPTH'b0:
      (dia_hp1_w[DIA_TMP_BITS-1-10-1:`BIT_DEPTH] == 0)?dia_hp1_w[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    dia_hp02 <= (dia_hp2_w[DIA_TMP_BITS-1-10])?`BIT_DEPTH'b0:
      (dia_hp2_w[DIA_TMP_BITS-1-10-1:`BIT_DEPTH] == 0)?dia_hp2_w[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    dia_hp03 <= (dia_hp3_w[DIA_TMP_BITS-1-10])?`BIT_DEPTH'b0:
      (dia_hp3_w[DIA_TMP_BITS-1-10-1:`BIT_DEPTH] == 0)?dia_hp3_w[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    dia_hp04 <= (dia_hp4_w[DIA_TMP_BITS-1-10])?`BIT_DEPTH'b0:
      (dia_hp4_w[DIA_TMP_BITS-1-10-1:`BIT_DEPTH] == 0)?dia_hp4_w[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} );  //(~(`BIT_DEPTH'd1<<(`BIT_DEPTH)))
    
    dia_hp10 <= dia_hp00;
    dia_hp11 <= dia_hp01;
    dia_hp12 <= dia_hp02;
    dia_hp13 <= dia_hp03;
    dia_hp14 <= dia_hp04;
  end
end

wire [14:0] ver_hp_tmp0_w; 
wire [14:0] ver_hp_tmp1_w; 
wire [14:0] ver_hp_tmp2_w; 
wire [14:0] ver_hp_tmp3_w; 
wire [14:0] ver_hp_tmp4_w; 
wire [14:0] ver_hp_tmp5_w; 

assign ver_hp_tmp0_w = ver_halfpel0 + 15'd16;
assign ver_hp_tmp1_w = ver_halfpel1 + 15'd16;
assign ver_hp_tmp2_w = ver_halfpel2 + 15'd16;
assign ver_hp_tmp3_w = ver_halfpel3 + 15'd16;
assign ver_hp_tmp4_w = ver_halfpel4 + 15'd16;
assign ver_hp_tmp5_w = ver_halfpel5 + 15'd16;

assign ver_hp_tmp0 = ver_hp_tmp0_w[14:5];
assign ver_hp_tmp1 = ver_hp_tmp1_w[14:5];
assign ver_hp_tmp2 = ver_hp_tmp2_w[14:5];
assign ver_hp_tmp3 = ver_hp_tmp3_w[14:5];
assign ver_hp_tmp4 = ver_hp_tmp4_w[14:5];
assign ver_hp_tmp5 = ver_hp_tmp5_w[14:5];
    
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    ver_hp00 <= 0;
    ver_hp01 <= 0;
    ver_hp02 <= 0;
    ver_hp03 <= 0;
    ver_hp04 <= 0;
    ver_hp05 <= 0;
    
    ver_hp10 <= 0;
    ver_hp11 <= 0;
    ver_hp12 <= 0;
    ver_hp13 <= 0;
    ver_hp14 <= 0;
    ver_hp15 <= 0;
  end
  else if(down_shift) begin
    ver_hp00 <= (ver_hp_tmp0[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp0[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp0[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    ver_hp01 <= (ver_hp_tmp1[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp1[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp1[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    ver_hp02 <= (ver_hp_tmp2[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp2[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp2[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    ver_hp03 <= (ver_hp_tmp3[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp3[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp3[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    ver_hp04 <= (ver_hp_tmp4[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp4[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp4[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} ); 
    ver_hp05 <= (ver_hp_tmp5[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (ver_hp_tmp5[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?ver_hp_tmp5[`BIT_DEPTH-1:0]:( {`BIT_DEPTH{1'b1}} );  //(~(`BIT_DEPTH'd1<<(`BIT_DEPTH)))
        
    ver_hp10 <= ver_hp00;
    ver_hp11 <= ver_hp01;
    ver_hp12 <= ver_hp02;
    ver_hp13 <= ver_hp03;
    ver_hp14 <= ver_hp04;
    ver_hp15 <= ver_hp05;
    end
end
    

   //horizontal half pixels
    wire [14:0] hor_hp_tmp0_w;
    wire [14:0] hor_hp_tmp1_w;
    wire [14:0] hor_hp_tmp2_w;
    wire [14:0] hor_hp_tmp3_w;
    wire [14:0] hor_hp_tmp4_w;
    
    assign hor_hp_tmp0_w = hor_halfpel30 + 15'd16;
    assign hor_hp_tmp1_w = hor_halfpel31 + 15'd16;
    assign hor_hp_tmp2_w = hor_halfpel32 + 15'd16;
    assign hor_hp_tmp3_w = hor_halfpel33 + 15'd16;
    assign hor_hp_tmp4_w = hor_halfpel34 + 15'd16;
    
    assign hor_hp_tmp0 = hor_hp_tmp0_w[14:5];
    assign hor_hp_tmp1 = hor_hp_tmp1_w[14:5];
    assign hor_hp_tmp2 = hor_hp_tmp2_w[14:5];
    assign hor_hp_tmp3 = hor_hp_tmp3_w[14:5];
    assign hor_hp_tmp4 = hor_hp_tmp4_w[14:5];
    
    assign hor_pel0_w = (hor_hp_tmp0[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
            (hor_hp_tmp0[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor_hp_tmp0[`BIT_DEPTH-1:0]:
            ( {`BIT_DEPTH{1'b1}} ); 
    assign hor_pel1_w = (hor_hp_tmp1[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
            (hor_hp_tmp1[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor_hp_tmp1[`BIT_DEPTH-1:0]:
            ( {`BIT_DEPTH{1'b1}} ); 
    assign hor_pel2_w = (hor_hp_tmp2[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
            (hor_hp_tmp2[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor_hp_tmp2[`BIT_DEPTH-1:0]:
            ( {`BIT_DEPTH{1'b1}} ); 
    assign hor_pel3_w = (hor_hp_tmp3[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
            (hor_hp_tmp3[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor_hp_tmp3[`BIT_DEPTH-1:0]:
            ( {`BIT_DEPTH{1'b1}} ); 
    assign hor_pel4_w = (hor_hp_tmp4[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
            (hor_hp_tmp4[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor_hp_tmp4[`BIT_DEPTH-1:0]:
            ( {`BIT_DEPTH{1'b1}} );  //(~(`BIT_DEPTH'd1<<(`BIT_DEPTH)))
    
    always @(posedge clk_i or negedge rst_n_i) begin
      if(!rst_n_i) begin
        hor_pel0 <= 0;
        hor_pel1 <= 0;
        hor_pel2 <= 0;
        hor_pel3 <= 0;
        hor_pel4 <= 0;
      end
      else begin
        hor_pel0 <= hor_pel0_w;
        hor_pel1 <= hor_pel1_w;
        hor_pel2 <= hor_pel2_w;
        hor_pel3 <= hor_pel3_w;
        hor_pel4 <= hor_pel4_w;
      end
    end
        
    
////////////////////////////////////////////////////////////////////////////////    
//    quarter-pel filter
////////////////////////////////////////////////////////////////////////////////
//interleaver
wire [14:0] hor0_hp4qp0_w_t;
wire [14:0] hor0_hp4qp1_w_t;
wire [14:0] hor0_hp4qp2_w_t;
wire [14:0] hor0_hp4qp3_w_t;
wire [14:0] hor0_hp4qp4_w_t;

assign hor0_hp4qp0_w_t = hor_halfpel50 + 15'd16;
assign hor0_hp4qp1_w_t = hor_halfpel51 + 15'd16;
assign hor0_hp4qp2_w_t = hor_halfpel52 + 15'd16;
assign hor0_hp4qp3_w_t = hor_halfpel53 + 15'd16;
assign hor0_hp4qp4_w_t = hor_halfpel54 + 15'd16;
   
assign hor0_hp4qp0_w = hor0_hp4qp0_w_t[14:5];
assign hor0_hp4qp1_w = hor0_hp4qp1_w_t[14:5];
assign hor0_hp4qp2_w = hor0_hp4qp2_w_t[14:5];
assign hor0_hp4qp3_w = hor0_hp4qp3_w_t[14:5];
assign hor0_hp4qp4_w = hor0_hp4qp4_w_t[14:5];

assign hor0_hp4qp0 = (hor0_hp4qp0_w[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (hor0_hp4qp0_w[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor0_hp4qp0_w[`BIT_DEPTH-1:0]:
         ( {`BIT_DEPTH{1'b1}} );
assign hor0_hp4qp1 = (hor0_hp4qp1_w[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (hor0_hp4qp1_w[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor0_hp4qp1_w[`BIT_DEPTH-1:0]:
         ( {`BIT_DEPTH{1'b1}} );
assign hor0_hp4qp2 = (hor0_hp4qp2_w[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (hor0_hp4qp2_w[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor0_hp4qp2_w[`BIT_DEPTH-1:0]:
         ( {`BIT_DEPTH{1'b1}} );
assign hor0_hp4qp3 = (hor0_hp4qp3_w[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (hor0_hp4qp3_w[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor0_hp4qp3_w[`BIT_DEPTH-1:0]:
         ( {`BIT_DEPTH{1'b1}} );
assign hor0_hp4qp4 = (hor0_hp4qp4_w[`BIT_DEPTH+`HF_EXWIDTH-1-5])?`BIT_DEPTH'd0:
        (hor0_hp4qp4_w[`BIT_DEPTH+`HF_EXWIDTH-1-5:`BIT_DEPTH] == 0)?hor0_hp4qp4_w[`BIT_DEPTH-1:0]:
         ( {`BIT_DEPTH{1'b1}} );  //(~(`BIT_DEPTH'd1<<(`BIT_DEPTH)))

assign hor1_hp4qp0 = hor_pel0;
assign hor1_hp4qp1 = hor_pel1;
assign hor1_hp4qp2 = hor_pel2;
assign hor1_hp4qp3 = hor_pel3;
assign hor1_hp4qp4 = hor_pel4;
    
assign hor2_hp4qp0 = hor_pel0_w;
assign hor2_hp4qp1 = hor_pel1_w;
assign hor2_hp4qp2 = hor_pel2_w;
assign hor2_hp4qp3 = hor_pel3_w;
assign hor2_hp4qp4 = hor_pel4_w;
    
    always @( * ) begin
      case ({yHFracl_i[2:1],xHFracl_i[2:1]})//-2:110 0:000 2:010
        4'b0000: begin
          bf0_0_in0 = ver_hp11;    bf0_0_in1 = hor1_hp4qp0;
          bf0_1_in0 = ver_hp12;    bf0_1_in1 = hor1_hp4qp1;
          bf0_2_in0 = ver_hp13;    bf0_2_in1 = hor1_hp4qp2;
          bf0_3_in0 = ver_hp14;    bf0_3_in1 = hor1_hp4qp3;

          bf1_0_in0 = ver_hp11;    bf1_0_in1 = int_pel41;
          bf1_1_in0 = ver_hp12;    bf1_1_in1 = int_pel42;
          bf1_2_in0 = ver_hp13;    bf1_2_in1 = int_pel43;
          bf1_3_in0 = ver_hp14;    bf1_3_in1 = int_pel44;

          bf2_0_in0 = ver_hp11;    bf2_0_in1 = hor1_hp4qp1;
          bf2_1_in0 = ver_hp12;    bf2_1_in1 = hor1_hp4qp2;
          bf2_2_in0 = ver_hp13;    bf2_2_in1 = hor1_hp4qp3;
          bf2_3_in0 = ver_hp14;    bf2_3_in1 = hor1_hp4qp4;

          bf3_0_in0 = hor1_hp4qp0; bf3_0_in1 = int_pel41;
          bf3_1_in0 = hor1_hp4qp1; bf3_1_in1 = int_pel42;
          bf3_2_in0 = hor1_hp4qp2; bf3_2_in1 = int_pel43;
          bf3_3_in0 = hor1_hp4qp3; bf3_3_in1 = int_pel44;
          
          bf4_0_out_r = int_pel41;
          bf4_1_out_r = int_pel42;
          bf4_2_out_r = int_pel43;
          bf4_3_out_r = int_pel44;
          
          bf5_0_in0 = hor1_hp4qp1; bf5_0_in1 = int_pel41;
          bf5_1_in0 = hor1_hp4qp2; bf5_1_in1 = int_pel42;
          bf5_2_in0 = hor1_hp4qp3; bf5_2_in1 = int_pel43;
          bf5_3_in0 = hor1_hp4qp4; bf5_3_in1 = int_pel44;

          bf6_0_in0 = ver_hp01;    bf6_0_in1 = hor1_hp4qp0;
          bf6_1_in0 = ver_hp02;    bf6_1_in1 = hor1_hp4qp1;
          bf6_2_in0 = ver_hp03;    bf6_2_in1 = hor1_hp4qp2;
          bf6_3_in0 = ver_hp04;    bf6_3_in1 = hor1_hp4qp3;

          bf7_0_in0 = ver_hp01;    bf7_0_in1 = int_pel41;
          bf7_1_in0 = ver_hp02;    bf7_1_in1 = int_pel42;
          bf7_2_in0 = ver_hp03;    bf7_2_in1 = int_pel43;
          bf7_3_in0 = ver_hp04;    bf7_3_in1 = int_pel44;

          bf8_0_in0 = ver_hp01;    bf8_0_in1 = hor1_hp4qp1;
          bf8_1_in0 = ver_hp02;    bf8_1_in1 = hor1_hp4qp2;
          bf8_2_in0 = ver_hp03;    bf8_2_in1 = hor1_hp4qp3;
          bf8_3_in0 = ver_hp04;    bf8_3_in1 = hor1_hp4qp4;
        end
        4'b0001: begin
          bf0_0_in0 = ver_hp11;    bf0_0_in1 = hor1_hp4qp1;
          bf0_1_in0 = ver_hp12;    bf0_1_in1 = hor1_hp4qp2;
          bf0_2_in0 = ver_hp13;    bf0_2_in1 = hor1_hp4qp3;
          bf0_3_in0 = ver_hp14;    bf0_3_in1 = hor1_hp4qp4;

          bf1_0_in0 = dia_hp11;    bf1_0_in1 = hor1_hp4qp1;
          bf1_1_in0 = dia_hp12;    bf1_1_in1 = hor1_hp4qp2;
          bf1_2_in0 = dia_hp13;    bf1_2_in1 = hor1_hp4qp3;
          bf1_3_in0 = dia_hp14;    bf1_3_in1 = hor1_hp4qp4;

          bf2_0_in0 = ver_hp12;    bf2_0_in1 = hor1_hp4qp1;
          bf2_1_in0 = ver_hp13;    bf2_1_in1 = hor1_hp4qp2;
          bf2_2_in0 = ver_hp14;    bf2_2_in1 = hor1_hp4qp3;
          bf2_3_in0 = ver_hp15;    bf2_3_in1 = hor1_hp4qp4;

          bf3_0_in0 = int_pel41;   bf3_0_in1 = hor1_hp4qp1;
          bf3_1_in0 = int_pel42;   bf3_1_in1 = hor1_hp4qp2;
          bf3_2_in0 = int_pel43;   bf3_2_in1 = hor1_hp4qp3;
          bf3_3_in0 = int_pel44;   bf3_3_in1 = hor1_hp4qp4;
          
          bf4_0_out_r = hor1_hp4qp1;
          bf4_1_out_r = hor1_hp4qp2;
          bf4_2_out_r = hor1_hp4qp3;
          bf4_3_out_r = hor1_hp4qp4;
          
          bf5_0_in0 = int_pel42;   bf5_0_in1 = hor1_hp4qp1;
          bf5_1_in0 = int_pel43;   bf5_1_in1 = hor1_hp4qp2;
          bf5_2_in0 = int_pel44;   bf5_2_in1 = hor1_hp4qp3;
          bf5_3_in0 = int_pel45;   bf5_3_in1 = hor1_hp4qp4;
          
          bf6_0_in0 = ver_hp01;    bf6_0_in1 = hor1_hp4qp1;
          bf6_1_in0 = ver_hp02;    bf6_1_in1 = hor1_hp4qp2;
          bf6_2_in0 = ver_hp03;    bf6_2_in1 = hor1_hp4qp3;
          bf6_3_in0 = ver_hp04;    bf6_3_in1 = hor1_hp4qp4;
  
          bf7_0_in0 = dia_hp01;    bf7_0_in1 = hor1_hp4qp1;
          bf7_1_in0 = dia_hp02;    bf7_1_in1 = hor1_hp4qp2;
          bf7_2_in0 = dia_hp03;    bf7_2_in1 = hor1_hp4qp3;
          bf7_3_in0 = dia_hp04;    bf7_3_in1 = hor1_hp4qp4;

          bf8_0_in0 = ver_hp02;    bf8_0_in1 = hor1_hp4qp1;
          bf8_1_in0 = ver_hp03;    bf8_1_in1 = hor1_hp4qp2;
          bf8_2_in0 = ver_hp04;    bf8_2_in1 = hor1_hp4qp3;
          bf8_3_in0 = ver_hp05;    bf8_3_in1 = hor1_hp4qp4;
        end
        4'b0011: begin
          bf0_0_in0 = ver_hp10;    bf0_0_in1 = hor1_hp4qp0;
          bf0_1_in0 = ver_hp11;    bf0_1_in1 = hor1_hp4qp1;
          bf0_2_in0 = ver_hp12;    bf0_2_in1 = hor1_hp4qp2;
          bf0_3_in0 = ver_hp13;    bf0_3_in1 = hor1_hp4qp3;
                                   
          bf1_0_in0 = dia_hp10;    bf1_0_in1 = hor1_hp4qp0;
          bf1_1_in0 = dia_hp11;    bf1_1_in1 = hor1_hp4qp1;
          bf1_2_in0 = dia_hp12;    bf1_2_in1 = hor1_hp4qp2;
          bf1_3_in0 = dia_hp13;    bf1_3_in1 = hor1_hp4qp3;
                                   
          bf2_0_in0 = ver_hp11;    bf2_0_in1 = hor1_hp4qp0;
          bf2_1_in0 = ver_hp12;    bf2_1_in1 = hor1_hp4qp1;
          bf2_2_in0 = ver_hp13;    bf2_2_in1 = hor1_hp4qp2;
          bf2_3_in0 = ver_hp14;    bf2_3_in1 = hor1_hp4qp3;
          
          bf3_0_in0 = int_pel40;   bf3_0_in1 = hor1_hp4qp0;
          bf3_1_in0 = int_pel41;   bf3_1_in1 = hor1_hp4qp1;
          bf3_2_in0 = int_pel42;   bf3_2_in1 = hor1_hp4qp2;
          bf3_3_in0 = int_pel43;   bf3_3_in1 = hor1_hp4qp3;
          
          bf4_0_out_r  = hor1_hp4qp0;
          bf4_1_out_r  = hor1_hp4qp1;
          bf4_2_out_r  = hor1_hp4qp2;
          bf4_3_out_r  = hor1_hp4qp3;
          
          bf5_0_in0 = int_pel41;   bf5_0_in1 = hor1_hp4qp0;
          bf5_1_in0 = int_pel42;   bf5_1_in1 = hor1_hp4qp1;
          bf5_2_in0 = int_pel43;   bf5_2_in1 = hor1_hp4qp2;
          bf5_3_in0 = int_pel44;   bf5_3_in1 = hor1_hp4qp3;
                                             
          bf6_0_in0 = ver_hp00;    bf6_0_in1 = hor1_hp4qp0;
          bf6_1_in0 = ver_hp01;    bf6_1_in1 = hor1_hp4qp1;
          bf6_2_in0 = ver_hp02;    bf6_2_in1 = hor1_hp4qp2;
          bf6_3_in0 = ver_hp03;    bf6_3_in1 = hor1_hp4qp3;
                                             
          bf7_0_in0 = dia_hp00;    bf7_0_in1 = hor1_hp4qp0;
          bf7_1_in0 = dia_hp01;    bf7_1_in1 = hor1_hp4qp1;
          bf7_2_in0 = dia_hp02;    bf7_2_in1 = hor1_hp4qp2;
          bf7_3_in0 = dia_hp03;    bf7_3_in1 = hor1_hp4qp3;
                                             
          bf8_0_in0 = ver_hp01;    bf8_0_in1 = hor1_hp4qp0;
          bf8_1_in0 = ver_hp02;    bf8_1_in1 = hor1_hp4qp1;
          bf8_2_in0 = ver_hp03;    bf8_2_in1 = hor1_hp4qp2;
          bf8_3_in0 = ver_hp04;    bf8_3_in1 = hor1_hp4qp3;
        end
        4'b0100: begin
          bf0_0_in0 = hor1_hp4qp0;   bf0_0_in1 = ver_hp01;
          bf0_1_in0 = hor1_hp4qp1;   bf0_1_in1 = ver_hp02;
          bf0_2_in0 = hor1_hp4qp2;   bf0_2_in1 = ver_hp03;
          bf0_3_in0 = hor1_hp4qp3;   bf0_3_in1 = ver_hp04;
                                               
          bf1_0_in0 = int_pel41;     bf1_0_in1 = ver_hp01;
          bf1_1_in0 = int_pel42;     bf1_1_in1 = ver_hp02;
          bf1_2_in0 = int_pel43;     bf1_2_in1 = ver_hp03;
          bf1_3_in0 = int_pel44;     bf1_3_in1 = ver_hp04;
                                               
          bf2_0_in0 = hor1_hp4qp1;   bf2_0_in1 = ver_hp01;
          bf2_1_in0 = hor1_hp4qp2;   bf2_1_in1 = ver_hp02;
          bf2_2_in0 = hor1_hp4qp3;   bf2_2_in1 = ver_hp03;
          bf2_3_in0 = hor1_hp4qp4;   bf2_3_in1 = ver_hp04;
                                               
          bf3_0_in0 = dia_hp00;      bf3_0_in1 = ver_hp01;
          bf3_1_in0 = dia_hp01;      bf3_1_in1 = ver_hp02;
          bf3_2_in0 = dia_hp02;      bf3_2_in1 = ver_hp03;
          bf3_3_in0 = dia_hp03;      bf3_3_in1 = ver_hp04;
          
          bf4_0_out_r = ver_hp01;
          bf4_1_out_r = ver_hp02;
          bf4_2_out_r = ver_hp03;
          bf4_3_out_r = ver_hp04;
          
          bf5_0_in0 = dia_hp01;      bf5_0_in1 = ver_hp01;
          bf5_1_in0 = dia_hp02;      bf5_1_in1 = ver_hp02;
          bf5_2_in0 = dia_hp03;      bf5_2_in1 = ver_hp03;
          bf5_3_in0 = dia_hp04;      bf5_3_in1 = ver_hp04;
                                               
          bf6_0_in0 = hor2_hp4qp0;   bf6_0_in1 = ver_hp01;
          bf6_1_in0 = hor2_hp4qp1;   bf6_1_in1 = ver_hp02;
          bf6_2_in0 = hor2_hp4qp2;   bf6_2_in1 = ver_hp03;
          bf6_3_in0 = hor2_hp4qp3;   bf6_3_in1 = ver_hp04;
                                               
          bf7_0_in0 = int_pel31;     bf7_0_in1 = ver_hp01;
          bf7_1_in0 = int_pel32;     bf7_1_in1 = ver_hp02;
          bf7_2_in0 = int_pel33;     bf7_2_in1 = ver_hp03;
          bf7_3_in0 = int_pel34;     bf7_3_in1 = ver_hp04;
                                               
          bf8_0_in0 = hor2_hp4qp1;   bf8_0_in1 = ver_hp01;
          bf8_1_in0 = hor2_hp4qp2;   bf8_1_in1 = ver_hp02;
          bf8_2_in0 = hor2_hp4qp3;   bf8_2_in1 = ver_hp03;
          bf8_3_in0 = hor2_hp4qp4;   bf8_3_in1 = ver_hp04;
        end
        4'b1100: begin
          bf0_0_in0 = hor0_hp4qp0;   bf0_0_in1 = ver_hp11;
          bf0_1_in0 = hor0_hp4qp1;   bf0_1_in1 = ver_hp12;
          bf0_2_in0 = hor0_hp4qp2;   bf0_2_in1 = ver_hp13;
          bf0_3_in0 = hor0_hp4qp3;   bf0_3_in1 = ver_hp14;
                                               
          bf1_0_in0 = int_pel51;     bf1_0_in1 = ver_hp11;
          bf1_1_in0 = int_pel52;     bf1_1_in1 = ver_hp12;
          bf1_2_in0 = int_pel53;     bf1_2_in1 = ver_hp13;
          bf1_3_in0 = int_pel54;     bf1_3_in1 = ver_hp14;
                                               
          bf2_0_in0 = hor0_hp4qp1;   bf2_0_in1 = ver_hp11;
          bf2_1_in0 = hor0_hp4qp2;   bf2_1_in1 = ver_hp12;
          bf2_2_in0 = hor0_hp4qp3;   bf2_2_in1 = ver_hp13;
          bf2_3_in0 = hor0_hp4qp4;   bf2_3_in1 = ver_hp14;
                                               
          bf3_0_in0 = dia_hp10;      bf3_0_in1 = ver_hp11;
          bf3_1_in0 = dia_hp11;      bf3_1_in1 = ver_hp12;
          bf3_2_in0 = dia_hp12;      bf3_2_in1 = ver_hp13;
          bf3_3_in0 = dia_hp13;      bf3_3_in1 = ver_hp14;
          
          bf4_0_out_r = ver_hp11;
          bf4_1_out_r = ver_hp12;
          bf4_2_out_r = ver_hp13;
          bf4_3_out_r = ver_hp14;
          
          bf5_0_in0 = dia_hp11;      bf5_0_in1 = ver_hp11;
          bf5_1_in0 = dia_hp12;      bf5_1_in1 = ver_hp12;
          bf5_2_in0 = dia_hp13;      bf5_2_in1 = ver_hp13;
          bf5_3_in0 = dia_hp14;      bf5_3_in1 = ver_hp14;
                                               
          bf6_0_in0 = hor1_hp4qp0;   bf6_0_in1 = ver_hp11;
          bf6_1_in0 = hor1_hp4qp1;   bf6_1_in1 = ver_hp12;
          bf6_2_in0 = hor1_hp4qp2;   bf6_2_in1 = ver_hp13;
          bf6_3_in0 = hor1_hp4qp3;   bf6_3_in1 = ver_hp14;
                                               
          bf7_0_in0 = int_pel41;     bf7_0_in1 = ver_hp11;
          bf7_1_in0 = int_pel42;     bf7_1_in1 = ver_hp12;
          bf7_2_in0 = int_pel43;     bf7_2_in1 = ver_hp13;
          bf7_3_in0 = int_pel44;     bf7_3_in1 = ver_hp14;
                                               
          bf8_0_in0 = hor1_hp4qp1;   bf8_0_in1 = ver_hp11;
          bf8_1_in0 = hor1_hp4qp2;   bf8_1_in1 = ver_hp12;
          bf8_2_in0 = hor1_hp4qp3;   bf8_2_in1 = ver_hp13;
          bf8_3_in0 = hor1_hp4qp4;   bf8_3_in1 = ver_hp14;
        end
        4'b1111: begin
          bf0_0_in0 = hor0_hp4qp0;   bf0_0_in1 = ver_hp10;
          bf0_1_in0 = hor0_hp4qp1;   bf0_1_in1 = ver_hp11;
          bf0_2_in0 = hor0_hp4qp2;   bf0_2_in1 = ver_hp12;
          bf0_3_in0 = hor0_hp4qp3;   bf0_3_in1 = ver_hp13;
                                               
          bf1_0_in0 = hor0_hp4qp0;   bf1_0_in1 = dia_hp10;
          bf1_1_in0 = hor0_hp4qp1;   bf1_1_in1 = dia_hp11;
          bf1_2_in0 = hor0_hp4qp2;   bf1_2_in1 = dia_hp12;
          bf1_3_in0 = hor0_hp4qp3;   bf1_3_in1 = dia_hp13;
                                               
          bf2_0_in0 = hor0_hp4qp0;   bf2_0_in1 = ver_hp11;
          bf2_1_in0 = hor0_hp4qp1;   bf2_1_in1 = ver_hp12;
          bf2_2_in0 = hor0_hp4qp2;   bf2_2_in1 = ver_hp13;
          bf2_3_in0 = hor0_hp4qp3;   bf2_3_in1 = ver_hp14;
                                               
          bf3_0_in0 = ver_hp10;      bf3_0_in1 = dia_hp10;
          bf3_1_in0 = ver_hp11;      bf3_1_in1 = dia_hp11;
          bf3_2_in0 = ver_hp12;      bf3_2_in1 = dia_hp12;
          bf3_3_in0 = ver_hp13;      bf3_3_in1 = dia_hp13;
          
          bf4_0_out_r = dia_hp10;
          bf4_1_out_r = dia_hp11;
          bf4_2_out_r = dia_hp12;
          bf4_3_out_r = dia_hp13;
          
          bf5_0_in0 = ver_hp11;      bf5_0_in1 = dia_hp10;
          bf5_1_in0 = ver_hp12;      bf5_1_in1 = dia_hp11;
          bf5_2_in0 = ver_hp13;      bf5_2_in1 = dia_hp12;
          bf5_3_in0 = ver_hp14;      bf5_3_in1 = dia_hp13;
                                               
          bf6_0_in0 = hor1_hp4qp0;   bf6_0_in1 = ver_hp10;
          bf6_1_in0 = hor1_hp4qp1;   bf6_1_in1 = ver_hp11;
          bf6_2_in0 = hor1_hp4qp2;   bf6_2_in1 = ver_hp12;
          bf6_3_in0 = hor1_hp4qp3;   bf6_3_in1 = ver_hp13;
                                               
          bf7_0_in0 = hor1_hp4qp0;   bf7_0_in1 = dia_hp10;
          bf7_1_in0 = hor1_hp4qp1;   bf7_1_in1 = dia_hp11;
          bf7_2_in0 = hor1_hp4qp2;   bf7_2_in1 = dia_hp12;
          bf7_3_in0 = hor1_hp4qp3;   bf7_3_in1 = dia_hp13;
                                               
          bf8_0_in0 = hor1_hp4qp0;   bf8_0_in1 = ver_hp11;
          bf8_1_in0 = hor1_hp4qp1;   bf8_1_in1 = ver_hp12;
          bf8_2_in0 = hor1_hp4qp2;   bf8_2_in1 = ver_hp13;
          bf8_3_in0 = hor1_hp4qp3;   bf8_3_in1 = ver_hp14;
        end
        4'b1101: begin
          bf0_0_in0  = hor0_hp4qp1;   bf0_0_in1 = ver_hp11;
          bf0_1_in0  = hor0_hp4qp2;   bf0_1_in1 = ver_hp12;
          bf0_2_in0  = hor0_hp4qp3;   bf0_2_in1 = ver_hp13;
          bf0_3_in0  = hor0_hp4qp4;   bf0_3_in1 = ver_hp14;
                                                
          bf1_0_in0  = hor0_hp4qp1;   bf1_0_in1 = dia_hp11;
          bf1_1_in0  = hor0_hp4qp2;   bf1_1_in1 = dia_hp12;
          bf1_2_in0  = hor0_hp4qp3;   bf1_2_in1 = dia_hp13;
          bf1_3_in0  = hor0_hp4qp4;   bf1_3_in1 = dia_hp14;
                                                
          bf2_0_in0  = hor0_hp4qp1;   bf2_0_in1 = ver_hp12;
          bf2_1_in0  = hor0_hp4qp2;   bf2_1_in1 = ver_hp13;
          bf2_2_in0  = hor0_hp4qp3;   bf2_2_in1 = ver_hp14;
          bf2_3_in0  = hor0_hp4qp4;   bf2_3_in1 = ver_hp15;
                                                
          bf3_0_in0  = ver_hp11;      bf3_0_in1 = dia_hp11;
          bf3_1_in0  = ver_hp12;      bf3_1_in1 = dia_hp12;
          bf3_2_in0  = ver_hp13;      bf3_2_in1 = dia_hp13;
          bf3_3_in0  = ver_hp14;      bf3_3_in1 = dia_hp14;
          
          bf4_0_out_r = dia_hp11;
          bf4_1_out_r = dia_hp12;
          bf4_2_out_r = dia_hp13;
          bf4_3_out_r = dia_hp14;
          
          bf5_0_in0 = ver_hp12;      bf5_0_in1 = dia_hp11;
          bf5_1_in0 = ver_hp13;      bf5_1_in1 = dia_hp12;
          bf5_2_in0 = ver_hp14;      bf5_2_in1 = dia_hp13;
          bf5_3_in0 = ver_hp15;      bf5_3_in1 = dia_hp14;
                                               
          bf6_0_in0 = hor1_hp4qp1;   bf6_0_in1 = ver_hp11;
          bf6_1_in0 = hor1_hp4qp2;   bf6_1_in1 = ver_hp12;
          bf6_2_in0 = hor1_hp4qp3;   bf6_2_in1 = ver_hp13;
          bf6_3_in0 = hor1_hp4qp4;   bf6_3_in1 = ver_hp14;
                                               
          bf7_0_in0 = hor1_hp4qp1;   bf7_0_in1 = dia_hp11;
          bf7_1_in0 = hor1_hp4qp2;   bf7_1_in1 = dia_hp12;
          bf7_2_in0 = hor1_hp4qp3;   bf7_2_in1 = dia_hp13;
          bf7_3_in0 = hor1_hp4qp4;   bf7_3_in1 = dia_hp14;
                                               
          bf8_0_in0 = hor1_hp4qp1;   bf8_0_in1 = ver_hp12;
          bf8_1_in0 = hor1_hp4qp2;   bf8_1_in1 = ver_hp13;
          bf8_2_in0 = hor1_hp4qp3;   bf8_2_in1 = ver_hp14;
          bf8_3_in0 = hor1_hp4qp4;   bf8_3_in1 = ver_hp15;
        end        
        4'b0101: begin
          bf0_0_in0 = hor1_hp4qp1;   bf0_0_in1 = ver_hp01;
          bf0_1_in0 = hor1_hp4qp2;   bf0_1_in1 = ver_hp02;
          bf0_2_in0 = hor1_hp4qp3;   bf0_2_in1 = ver_hp03;
          bf0_3_in0 = hor1_hp4qp4;   bf0_3_in1 = ver_hp04;
                                               
          bf1_0_in0 = hor1_hp4qp1;   bf1_0_in1 = dia_hp01;
          bf1_1_in0 = hor1_hp4qp2;   bf1_1_in1 = dia_hp02;
          bf1_2_in0 = hor1_hp4qp3;   bf1_2_in1 = dia_hp03;
          bf1_3_in0 = hor1_hp4qp4;   bf1_3_in1 = dia_hp04;
                                               
          bf2_0_in0 = hor1_hp4qp1;   bf2_0_in1 = ver_hp02;
          bf2_1_in0 = hor1_hp4qp2;   bf2_1_in1 = ver_hp03;
          bf2_2_in0 = hor1_hp4qp3;   bf2_2_in1 = ver_hp04;
          bf2_3_in0 = hor1_hp4qp4;   bf2_3_in1 = ver_hp05;
                                               
          bf3_0_in0 = ver_hp01;      bf3_0_in1 = dia_hp01;
          bf3_1_in0 = ver_hp02;      bf3_1_in1 = dia_hp02;
          bf3_2_in0 = ver_hp03;      bf3_2_in1 = dia_hp03;
          bf3_3_in0 = ver_hp04;      bf3_3_in1 = dia_hp04;
          
          bf4_0_out_r = dia_hp01;
          bf4_1_out_r = dia_hp02;
          bf4_2_out_r = dia_hp03;
          bf4_3_out_r = dia_hp04;
          
          bf5_0_in0 = ver_hp02;      bf5_0_in1 = dia_hp01;
          bf5_1_in0 = ver_hp03;      bf5_1_in1 = dia_hp02;
          bf5_2_in0 = ver_hp04;      bf5_2_in1 = dia_hp03;
          bf5_3_in0 = ver_hp05;      bf5_3_in1 = dia_hp04;
                                               
          bf6_0_in0 = hor2_hp4qp1;   bf6_0_in1 = ver_hp01;
          bf6_1_in0 = hor2_hp4qp2;   bf6_1_in1 = ver_hp02;
          bf6_2_in0 = hor2_hp4qp3;   bf6_2_in1 = ver_hp03;
          bf6_3_in0 = hor2_hp4qp4;   bf6_3_in1 = ver_hp04;
                                               
          bf7_0_in0 = hor2_hp4qp1;   bf7_0_in1 = dia_hp01;
          bf7_1_in0 = hor2_hp4qp2;   bf7_1_in1 = dia_hp02;
          bf7_2_in0 = hor2_hp4qp3;   bf7_2_in1 = dia_hp03;
          bf7_3_in0 = hor2_hp4qp4;   bf7_3_in1 = dia_hp04;
                                               
          bf8_0_in0 = hor2_hp4qp1;   bf8_0_in1 = ver_hp02;
          bf8_1_in0 = hor2_hp4qp2;   bf8_1_in1 = ver_hp03;
          bf8_2_in0 = hor2_hp4qp3;   bf8_2_in1 = ver_hp04;
          bf8_3_in0 = hor2_hp4qp4;   bf8_3_in1 = ver_hp05;
        end 
        4'b0111: begin
          bf0_0_in0 = hor1_hp4qp0;   bf0_0_in1 = ver_hp00;
          bf0_1_in0 = hor1_hp4qp1;   bf0_1_in1 = ver_hp01;
          bf0_2_in0 = hor1_hp4qp2;   bf0_2_in1 = ver_hp02;
          bf0_3_in0 = hor1_hp4qp3;   bf0_3_in1 = ver_hp03;
                                               
          bf1_0_in0 = hor1_hp4qp0;   bf1_0_in1 = dia_hp00;
          bf1_1_in0 = hor1_hp4qp1;   bf1_1_in1 = dia_hp01;
          bf1_2_in0 = hor1_hp4qp2;   bf1_2_in1 = dia_hp02;
          bf1_3_in0 = hor1_hp4qp3;   bf1_3_in1 = dia_hp03;
                                               
          bf2_0_in0 = hor1_hp4qp0;   bf2_0_in1 = ver_hp01;
          bf2_1_in0 = hor1_hp4qp1;   bf2_1_in1 = ver_hp02;
          bf2_2_in0 = hor1_hp4qp2;   bf2_2_in1 = ver_hp03;
          bf2_3_in0 = hor1_hp4qp3;   bf2_3_in1 = ver_hp04;
                                               
          bf3_0_in0 = ver_hp00;      bf3_0_in1 = dia_hp00;
          bf3_1_in0 = ver_hp01;      bf3_1_in1 = dia_hp01;
          bf3_2_in0 = ver_hp02;      bf3_2_in1 = dia_hp02;
          bf3_3_in0 = ver_hp03;      bf3_3_in1 = dia_hp03;
          
          bf4_0_out_r = dia_hp00;
          bf4_1_out_r = dia_hp01;
          bf4_2_out_r = dia_hp02;
          bf4_3_out_r = dia_hp03;
          
          bf5_0_in0 = ver_hp01;      bf5_0_in1 = dia_hp00;
          bf5_1_in0 = ver_hp02;      bf5_1_in1 = dia_hp01;
          bf5_2_in0 = ver_hp03;      bf5_2_in1 = dia_hp02;
          bf5_3_in0 = ver_hp04;      bf5_3_in1 = dia_hp03;
                                               
          bf6_0_in0 = hor2_hp4qp0;   bf6_0_in1 = ver_hp00;
          bf6_1_in0 = hor2_hp4qp1;   bf6_1_in1 = ver_hp01;
          bf6_2_in0 = hor2_hp4qp2;   bf6_2_in1 = ver_hp02;
          bf6_3_in0 = hor2_hp4qp3;   bf6_3_in1 = ver_hp03;
                                               
          bf7_0_in0 = hor2_hp4qp0;   bf7_0_in1 = dia_hp00;
          bf7_1_in0 = hor2_hp4qp1;   bf7_1_in1 = dia_hp01;
          bf7_2_in0 = hor2_hp4qp2;   bf7_2_in1 = dia_hp02;
          bf7_3_in0 = hor2_hp4qp3;   bf7_3_in1 = dia_hp03;
                                               
          bf8_0_in0 = hor2_hp4qp0;   bf8_0_in1 = ver_hp01;
          bf8_1_in0 = hor2_hp4qp1;   bf8_1_in1 = ver_hp02;
          bf8_2_in0 = hor2_hp4qp2;   bf8_2_in1 = ver_hp03;
          bf8_3_in0 = hor2_hp4qp3;   bf8_3_in1 = ver_hp04;
        end
        default: begin
          bf0_0_in0 = 0;   bf0_0_in1 = 0;
          bf0_1_in0 = 0;   bf0_1_in1 = 0;
          bf0_2_in0 = 0;   bf0_2_in1 = 0;
          bf0_3_in0 = 0;   bf0_3_in1 = 0;
                                     
          bf1_0_in0 = 0;   bf1_0_in1 = 0;
          bf1_1_in0 = 0;   bf1_1_in1 = 0;
          bf1_2_in0 = 0;   bf1_2_in1 = 0;
          bf1_3_in0 = 0;   bf1_3_in1 = 0;
                                     
          bf2_0_in0 = 0;   bf2_0_in1 = 0;
          bf2_1_in0 = 0;   bf2_1_in1 = 0;
          bf2_2_in0 = 0;   bf2_2_in1 = 0;
          bf2_3_in0 = 0;   bf2_3_in1 = 0;
                                     
          bf3_0_in0 = 0;   bf3_0_in1 = 0;
          bf3_1_in0 = 0;   bf3_1_in1 = 0;
          bf3_2_in0 = 0;   bf3_2_in1 = 0;
          bf3_3_in0 = 0;   bf3_3_in1 = 0;
          
          bf4_0_out_r = 0;
          bf4_1_out_r = 0;
          bf4_2_out_r = 0;
          bf4_3_out_r = 0;
          
          bf5_0_in0 = 0;   bf5_0_in1 = 0;
          bf5_1_in0 = 0;   bf5_1_in1 = 0;
          bf5_2_in0 = 0;   bf5_2_in1 = 0;
          bf5_3_in0 = 0;   bf5_3_in1 = 0;
                                     
          bf6_0_in0 = 0;   bf6_0_in1 = 0;
          bf6_1_in0 = 0;   bf6_1_in1 = 0;
          bf6_2_in0 = 0;   bf6_2_in1 = 0;
          bf6_3_in0 = 0;   bf6_3_in1 = 0;
                                     
          bf7_0_in0 = 0;   bf7_0_in1 = 0;
          bf7_1_in0 = 0;   bf7_1_in1 = 0;
          bf7_2_in0 = 0;   bf7_2_in1 = 0;
          bf7_3_in0 = 0;   bf7_3_in1 = 0;
                                     
          bf8_0_in0 = 0;   bf8_0_in1 = 0;
          bf8_1_in0 = 0;   bf8_1_in1 = 0;
          bf8_2_in0 = 0;   bf8_2_in1 = 0;
          bf8_3_in0 = 0;   bf8_3_in1 = 0;
        end
      endcase
    end
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf0_0(.a_i(bf0_0_in0),.b_i(bf0_0_in1),.r_o(bf0_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf0_1(.a_i(bf0_1_in0),.b_i(bf0_1_in1),.r_o(bf0_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf0_2(.a_i(bf0_2_in0),.b_i(bf0_2_in1),.r_o(bf0_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf0_3(.a_i(bf0_3_in0),.b_i(bf0_3_in1),.r_o(bf0_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf1_0(.a_i(bf1_0_in0),.b_i(bf1_0_in1),.r_o(bf1_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf1_1(.a_i(bf1_1_in0),.b_i(bf1_1_in1),.r_o(bf1_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf1_2(.a_i(bf1_2_in0),.b_i(bf1_2_in1),.r_o(bf1_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf1_3(.a_i(bf1_3_in0),.b_i(bf1_3_in1),.r_o(bf1_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf2_0(.a_i(bf2_0_in0),.b_i(bf2_0_in1),.r_o(bf2_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf2_1(.a_i(bf2_1_in0),.b_i(bf2_1_in1),.r_o(bf2_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf2_2(.a_i(bf2_2_in0),.b_i(bf2_2_in1),.r_o(bf2_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf2_3(.a_i(bf2_3_in0),.b_i(bf2_3_in1),.r_o(bf2_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf3_0(.a_i(bf3_0_in0),.b_i(bf3_0_in1),.r_o(bf3_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf3_1(.a_i(bf3_1_in0),.b_i(bf3_1_in1),.r_o(bf3_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf3_2(.a_i(bf3_2_in0),.b_i(bf3_2_in1),.r_o(bf3_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf3_3(.a_i(bf3_3_in0),.b_i(bf3_3_in1),.r_o(bf3_3_out));
    
    assign bf4_0_out = bf4_0_out_r;
    assign bf4_1_out = bf4_1_out_r;
    assign bf4_2_out = bf4_2_out_r;
    assign bf4_3_out = bf4_3_out_r;
    //no 4
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf5_0(.a_i(bf5_0_in0),.b_i(bf5_0_in1),.r_o(bf5_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf5_1(.a_i(bf5_1_in0),.b_i(bf5_1_in1),.r_o(bf5_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf5_2(.a_i(bf5_2_in0),.b_i(bf5_2_in1),.r_o(bf5_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf5_3(.a_i(bf5_3_in0),.b_i(bf5_3_in1),.r_o(bf5_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf6_0(.a_i(bf6_0_in0),.b_i(bf6_0_in1),.r_o(bf6_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf6_1(.a_i(bf6_1_in0),.b_i(bf6_1_in1),.r_o(bf6_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf6_2(.a_i(bf6_2_in0),.b_i(bf6_2_in1),.r_o(bf6_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf6_3(.a_i(bf6_3_in0),.b_i(bf6_3_in1),.r_o(bf6_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf7_0(.a_i(bf7_0_in0),.b_i(bf7_0_in1),.r_o(bf7_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf7_1(.a_i(bf7_1_in0),.b_i(bf7_1_in1),.r_o(bf7_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf7_2(.a_i(bf7_2_in0),.b_i(bf7_2_in1),.r_o(bf7_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf7_3(.a_i(bf7_3_in0),.b_i(bf7_3_in1),.r_o(bf7_3_out));
    
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf8_0(.a_i(bf8_0_in0),.b_i(bf8_0_in1),.r_o(bf8_0_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf8_1(.a_i(bf8_1_in0),.b_i(bf8_1_in1),.r_o(bf8_1_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf8_2(.a_i(bf8_2_in0),.b_i(bf8_2_in1),.r_o(bf8_2_out));
    bilinear_filter #(.INPUT_BITS(`BIT_DEPTH)) bf8_3(.a_i(bf8_3_in0),.b_i(bf8_3_in1),.r_o(bf8_3_out));
    

    
    always @(posedge clk_i or negedge rst_n_i) begin
      if(!rst_n_i) begin
        quar_pel0_0 <= 0; quar_pel0_1 <= 0; quar_pel0_2 <= 0; quar_pel0_3 <= 0;
        quar_pel1_0 <= 0; quar_pel1_1 <= 0; quar_pel1_2 <= 0; quar_pel1_3 <= 0;
        quar_pel2_0 <= 0; quar_pel2_1 <= 0; quar_pel2_2 <= 0; quar_pel2_3 <= 0;
        quar_pel3_0 <= 0; quar_pel3_1 <= 0; quar_pel3_2 <= 0; quar_pel3_3 <= 0;
        quar_pel4_0 <= 0; quar_pel4_1 <= 0; quar_pel4_2 <= 0; quar_pel4_3 <= 0;
        quar_pel5_0 <= 0; quar_pel5_1 <= 0; quar_pel5_2 <= 0; quar_pel5_3 <= 0;
        quar_pel6_0 <= 0; quar_pel6_1 <= 0; quar_pel6_2 <= 0; quar_pel6_3 <= 0;
        quar_pel7_0 <= 0; quar_pel7_1 <= 0; quar_pel7_2 <= 0; quar_pel7_3 <= 0;
        quar_pel8_0 <= 0; quar_pel8_1 <= 0; quar_pel8_2 <= 0; quar_pel8_3 <= 0;
      end
      else begin
        quar_pel0_0 <= bf0_0_out; quar_pel0_1 <= bf0_1_out;
        quar_pel0_2 <= bf0_2_out; quar_pel0_3 <= bf0_3_out;
        quar_pel1_0 <= bf1_0_out; quar_pel1_1 <= bf1_1_out; 
        quar_pel1_2 <= bf1_2_out; quar_pel1_3 <= bf1_3_out;
        quar_pel2_0 <= bf2_0_out; quar_pel2_1 <= bf2_1_out;
        quar_pel2_2 <= bf2_2_out; quar_pel2_3 <= bf2_3_out;
        quar_pel3_0 <= bf3_0_out; quar_pel3_1 <= bf3_1_out;
        quar_pel3_2 <= bf3_2_out; quar_pel3_3 <= bf3_3_out;
        quar_pel4_0 <= bf4_0_out; quar_pel4_1 <= bf4_1_out;
        quar_pel4_2 <= bf4_2_out; quar_pel4_3 <= bf4_3_out;
        quar_pel5_0 <= bf5_0_out; quar_pel5_1 <= bf5_1_out;
        quar_pel5_2 <= bf5_2_out; quar_pel5_3 <= bf5_3_out;
        quar_pel6_0 <= bf6_0_out; quar_pel6_1 <= bf6_1_out;
        quar_pel6_2 <= bf6_2_out; quar_pel6_3 <= bf6_3_out;
        quar_pel7_0 <= bf7_0_out; quar_pel7_1 <= bf7_1_out;
        quar_pel7_2 <= bf7_2_out; quar_pel7_3 <= bf7_3_out;
        quar_pel8_0 <= bf8_0_out; quar_pel8_1 <= bf8_1_out;
        quar_pel8_2 <= bf8_2_out; quar_pel8_3 <= bf8_3_out;
      end
    end
    
    assign candi0_0_o = (half_ip_flag_i)?dia_hp10 :quar_pel0_0;
    assign candi1_0_o = (half_ip_flag_i)?ver_hp11 :quar_pel1_0;
    assign candi2_0_o = (half_ip_flag_i)?dia_hp11 :quar_pel2_0;
    assign candi3_0_o = (half_ip_flag_i)?hor_pel0 :quar_pel3_0;
    assign candi4_0_o = (half_ip_flag_i)?int_pel41:quar_pel4_0;
    assign candi5_0_o = (half_ip_flag_i)?hor_pel1 :quar_pel5_0;
    assign candi6_0_o = (half_ip_flag_i)?dia_hp00 :quar_pel6_0;
    assign candi7_0_o = (half_ip_flag_i)?ver_hp01 :quar_pel7_0;
    assign candi8_0_o = (half_ip_flag_i)?dia_hp01 :quar_pel8_0;
    
    assign candi0_1_o = (half_ip_flag_i)?dia_hp11 :quar_pel0_1;
    assign candi1_1_o = (half_ip_flag_i)?ver_hp12 :quar_pel1_1;
    assign candi2_1_o = (half_ip_flag_i)?dia_hp12 :quar_pel2_1;
    assign candi3_1_o = (half_ip_flag_i)?hor_pel1 :quar_pel3_1;
    assign candi4_1_o = (half_ip_flag_i)?int_pel42:quar_pel4_1;
    assign candi5_1_o = (half_ip_flag_i)?hor_pel2 :quar_pel5_1;
    assign candi6_1_o = (half_ip_flag_i)?dia_hp01 :quar_pel6_1;
    assign candi7_1_o = (half_ip_flag_i)?ver_hp02 :quar_pel7_1;
    assign candi8_1_o = (half_ip_flag_i)?dia_hp02 :quar_pel8_1;
    
    assign candi0_2_o = (half_ip_flag_i)?dia_hp12 :quar_pel0_2;
    assign candi1_2_o = (half_ip_flag_i)?ver_hp13 :quar_pel1_2;
    assign candi2_2_o = (half_ip_flag_i)?dia_hp13 :quar_pel2_2;
    assign candi3_2_o = (half_ip_flag_i)?hor_pel2 :quar_pel3_2;
    assign candi4_2_o = (half_ip_flag_i)?int_pel43:quar_pel4_2;
    assign candi5_2_o = (half_ip_flag_i)?hor_pel3 :quar_pel5_2;
    assign candi6_2_o = (half_ip_flag_i)?dia_hp02 :quar_pel6_2;
    assign candi7_2_o = (half_ip_flag_i)?ver_hp03 :quar_pel7_2;
    assign candi8_2_o = (half_ip_flag_i)?dia_hp03 :quar_pel8_2;
    
    assign candi0_3_o = (half_ip_flag_i)?dia_hp13 :quar_pel0_3;
    assign candi1_3_o = (half_ip_flag_i)?ver_hp14 :quar_pel1_3;
    assign candi2_3_o = (half_ip_flag_i)?dia_hp14 :quar_pel2_3;
    assign candi3_3_o = (half_ip_flag_i)?hor_pel3 :quar_pel3_3;
    assign candi4_3_o = (half_ip_flag_i)?int_pel44:quar_pel4_3;
    assign candi5_3_o = (half_ip_flag_i)?hor_pel4 :quar_pel5_3;
    assign candi6_3_o = (half_ip_flag_i)?dia_hp03 :quar_pel6_3;
    assign candi7_3_o = (half_ip_flag_i)?ver_hp04 :quar_pel7_3;
    assign candi8_3_o = (half_ip_flag_i)?dia_hp04 :quar_pel8_3;
endmodule


`ifndef HALF_FILTER
`define HALF_FILTER
module half_filter
#(parameter INPUTWIDTH = `BIT_DEPTH)
(
                 clk_i,
                 rst_n_i,
                 pel0_i,pel1_i,pel2_i,pel3_i,pel4_i,pel5_i,
                 
                 halfpel_tmp_o
);
    //Inputs
    input clk_i;
    input rst_n_i;
    input  [INPUTWIDTH-1:0] pel0_i;//a
    input  [INPUTWIDTH-1:0] pel1_i;//b
    input  [INPUTWIDTH-1:0] pel2_i;//c
    input  [INPUTWIDTH-1:0] pel3_i;//d
    input  [INPUTWIDTH-1:0] pel4_i;//e
    input  [INPUTWIDTH-1:0] pel5_i;//f
    //Output
    output [INPUTWIDTH+6:0] halfpel_tmp_o;//15bits
    

	//Internal wires
    wire [(INPUTWIDTH-1)+1:0] af_w;//9bits
    wire [(INPUTWIDTH-1)+1:0] be_w;//9bits
    wire [(INPUTWIDTH-1)+1:0] cd_w;//9bits
    wire [(INPUTWIDTH-1)+4:0] be4cd_w;//12bits
    wire [(INPUTWIDTH-1)+5:0] afbe4cd_w;//12bits
	
	
    assign af_w = pel0_i + pel5_i;
    assign be_w = pel1_i + pel4_i;
    assign cd_w = pel2_i + pel3_i;
    assign be4cd_w = {3'b000,be_w} - {1'b0,cd_w,2'b00};
    assign afbe4cd_w  = {4'b0000,af_w} - {be4cd_w[(INPUTWIDTH-1)+4],be4cd_w};//13bits
   assign halfpel_tmp_o = {{2{afbe4cd_w[(INPUTWIDTH-1)+5]}},afbe4cd_w} - {be4cd_w[(INPUTWIDTH-1)+4],be4cd_w,2'b00};//15bits
 
endmodule

module half_filter_d
#(parameter INPUTWIDTH = `BIT_DEPTH)
(
       clk_i           ,
       rst_n_i         ,
       pel0_i,pel1_i   ,
       pel2_i,pel3_i   ,
       pel4_i,pel5_i   ,
       halfpel_tmp_o   
);
//Inputs
input clk_i;
input rst_n_i;

input  [INPUTWIDTH-1:0] pel0_i;//a
input  [INPUTWIDTH-1:0] pel1_i;//b
input  [INPUTWIDTH-1:0] pel2_i;//c
input  [INPUTWIDTH-1:0] pel3_i;//d
input  [INPUTWIDTH-1:0] pel4_i;//e
input  [INPUTWIDTH-1:0] pel5_i;//f

//Output
output [INPUTWIDTH+6:0] halfpel_tmp_o;//15bits


//Internal wires
wire [(INPUTWIDTH-1)+1:0] af_w;//9bits
wire [(INPUTWIDTH-1)+1:0] be_w;//9bits
wire [(INPUTWIDTH-1)+1:0] cd_w;//9bits


assign af_w = {pel0_i[INPUTWIDTH-1],pel0_i} + {pel5_i[INPUTWIDTH-1],pel5_i};
assign be_w = {pel1_i[INPUTWIDTH-1],pel1_i} + {pel4_i[INPUTWIDTH-1],pel4_i};
assign cd_w = {pel2_i[INPUTWIDTH-1],pel2_i} + {pel3_i[INPUTWIDTH-1],pel3_i};

wire [(INPUTWIDTH-1)+4:0] be4cd_w;//12bits

assign be4cd_w = {{3{be_w[(INPUTWIDTH-1)+1]}},be_w} - {cd_w[(INPUTWIDTH-1)+1],cd_w,2'b00};

//Internal wires
wire [(INPUTWIDTH-1)+5:0] afbe4cd_w;//13bits

assign afbe4cd_w  = {{4{af_w[(INPUTWIDTH-1)+1]}},af_w} - {be4cd_w[(INPUTWIDTH-1)+4],be4cd_w};//13bits
//output
assign halfpel_tmp_o = {{2{afbe4cd_w[(INPUTWIDTH-1)+5]}},afbe4cd_w} - {be4cd_w[(INPUTWIDTH-1)+4],be4cd_w,2'b00};//15bits
    
endmodule

module bilinear_filter
#(parameter INPUT_BITS = `BIT_DEPTH+7)
(
          a_i,
          b_i,
          r_o
);

    input [INPUT_BITS-1:0] a_i;
    input [INPUT_BITS-1:0] b_i;
    
    output [INPUT_BITS-1:0] r_o;
    
    wire   [INPUT_BITS:0] ab_w;
    assign ab_w = {1'b0,a_i} + {1'b0,b_i} + {{INPUT_BITS{1'b0}},1'b1};
    
    assign r_o = ab_w[INPUT_BITS:1];
	
endmodule
`endif
