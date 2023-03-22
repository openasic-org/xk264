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
// Filename       : fme_datapath.v
// Author         : Jialiang Liu
// Created        : 2011.5-2011.6
// Description    : 
//                  
//                  
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"


module fme_datapath(
       clk_i                 ,
       rst_n_i               ,

       cmb_p0_i              ,
       cmb_p1_i              ,
       cmb_p2_i              ,
       cmb_p3_i              ,
       cmb_p4_i              ,
       cmb_p5_i              ,
       cmb_p6_i              ,
       cmb_p7_i              ,

       end_one_blk_input_i   ,    
       area_co_locate_i      ,    
       ip0_rpvalid_i         ,
       ip0_rp0_i             ,
       ip0_rp1_i             ,
       ip0_rp2_i             ,
       ip0_rp3_i             ,
       ip0_rp4_i             ,
       ip0_rp5_i             ,
       ip0_rp6_i             ,
       ip0_rp7_i             ,
       ip0_rp8_i             ,
       ip0_rp9_i             ,
       
       ip1_rpvalid_i         ,
       ip1_rp0_i             ,
       ip1_rp1_i             ,
       ip1_rp2_i             ,
       ip1_rp3_i             ,
       ip1_rp4_i             ,
       ip1_rp5_i             ,
       ip1_rp6_i             ,
       ip1_rp7_i             ,
       ip1_rp8_i             ,
       ip1_rp9_i             ,
       
       half_flag_ip_i        ,   
       half_flag_bcs_i       ,
       end_oneblk_ip_o       ,
       
       working_mode_satd_i   ,   
       working_mode_bcs_i    ,
             
       candi_valid_o         ,   

       satd_4x4_valid_o      , 
       satd_blk_valid_i      , 

       imv0_i                ,
       imv1_i                ,
       mvp_i                 ,
       qp_i                  ,
       best_candi_v_o        ,
       
       bcost_valid_o         ,
       bcost_o               ,

       fmv0_o                ,
       fmv1_o     

);
// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                     clk_i                              ;
input                     rst_n_i                            ;

//     data signals
input  [`BIT_DEPTH-1 :0]  cmb_p0_i,cmb_p1_i,cmb_p2_i,cmb_p3_i;
input  [`BIT_DEPTH-1 :0]  cmb_p4_i,cmb_p5_i,cmb_p6_i,cmb_p7_i;

//     interpolator signals
input                     end_one_blk_input_i                ;     //signal to interpolator need to shift down 2 cycles still.                        
input                     area_co_locate_i                   ;     //after delaying 5 cycle, this signal indicates the output candidates are valid.   
input                     ip0_rpvalid_i                      ;
input  [`BIT_DEPTH-1 :0]  ip0_rp0_i, ip0_rp1_i, ip0_rp2_i    ; 
input  [`BIT_DEPTH-1 :0]  ip0_rp3_i, ip0_rp4_i               ;
input  [`BIT_DEPTH-1 :0]  ip0_rp5_i, ip0_rp6_i, ip0_rp7_i    ;
input  [`BIT_DEPTH-1 :0]  ip0_rp8_i, ip0_rp9_i               ;

input                     ip1_rpvalid_i                      ;
input  [`BIT_DEPTH-1 :0]  ip1_rp0_i, ip1_rp1_i, ip1_rp2_i    ; 
input  [`BIT_DEPTH-1 :0]  ip1_rp3_i, ip1_rp4_i               ;
input  [`BIT_DEPTH-1 :0]  ip1_rp5_i, ip1_rp6_i, ip1_rp7_i    ;
input  [`BIT_DEPTH-1 :0]  ip1_rp8_i, ip1_rp9_i               ;

input                     half_flag_ip_i                     ;   //1:half refinement, 0:quarter refinement  
input                     half_flag_bcs_i                    ;
input                     working_mode_satd_i                ;   //0 for 4x4; 1 for 8x8 
input                     working_mode_bcs_i                 ; 
output                    end_oneblk_ip_o                    ;

output                    candi_valid_o                      ;   //output to fme_ctrl for cmb pixels read    

//     satd gen signals                                                           
output                    satd_4x4_valid_o                   ;   //satd_4x4 or satd_8x4  //output to fme_ctrl for counting satd of blk4x4 acc.
input                     satd_blk_valid_i                   ;   //blk:16x16 8x16 16x8 8x8 8x4 4x8 4x4  

//     best candidate select signals
input  [2*`IMVD_LEN-1 :0] imv0_i,imv1_i                      ;
input  [2*`FMVD_LEN-1 :0] mvp_i                              ;
                                                             
input  [5             :0] qp_i                               ;
output                    best_candi_v_o                     ;

output [`BIT_DEPTH+10-1:0]bcost_o                            ;
output                    bcost_valid_o                      ;

//     fmv write signals                                                            
output [2*`FMVD_LEN-1 :0] fmv0_o, fmv1_o                     ;

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ******************************************** 
wire                      ip0_candi_valid                         ;
wire                      ip1_candi_valid                         ;

wire [`BIT_DEPTH-1:0]     ip0_candi0_0, ip0_candi1_0, ip0_candi2_0;
wire [`BIT_DEPTH-1:0]     ip0_candi0_1, ip0_candi1_1, ip0_candi2_1;
wire [`BIT_DEPTH-1:0]     ip0_candi0_2, ip0_candi1_2, ip0_candi2_2;
wire [`BIT_DEPTH-1:0]     ip0_candi0_3, ip0_candi1_3, ip0_candi2_3;
                          
wire [`BIT_DEPTH-1:0]     ip0_candi3_0, ip0_candi4_0, ip0_candi5_0;
wire [`BIT_DEPTH-1:0]     ip0_candi3_1, ip0_candi4_1, ip0_candi5_1;
wire [`BIT_DEPTH-1:0]     ip0_candi3_2, ip0_candi4_2, ip0_candi5_2;
wire [`BIT_DEPTH-1:0]     ip0_candi3_3, ip0_candi4_3, ip0_candi5_3;
                          
wire [`BIT_DEPTH-1:0]     ip0_candi6_0, ip0_candi7_0, ip0_candi8_0;
wire [`BIT_DEPTH-1:0]     ip0_candi6_1, ip0_candi7_1, ip0_candi8_1;
wire [`BIT_DEPTH-1:0]     ip0_candi6_2, ip0_candi7_2, ip0_candi8_2;
wire [`BIT_DEPTH-1:0]     ip0_candi6_3, ip0_candi7_3, ip0_candi8_3;
                          
wire [`BIT_DEPTH-1:0]     ip1_candi0_0, ip1_candi1_0, ip1_candi2_0;
wire [`BIT_DEPTH-1:0]     ip1_candi0_1, ip1_candi1_1, ip1_candi2_1;
wire [`BIT_DEPTH-1:0]     ip1_candi0_2, ip1_candi1_2, ip1_candi2_2;
wire [`BIT_DEPTH-1:0]     ip1_candi0_3, ip1_candi1_3, ip1_candi2_3;
                          
wire [`BIT_DEPTH-1:0]     ip1_candi3_0, ip1_candi4_0, ip1_candi5_0;
wire [`BIT_DEPTH-1:0]     ip1_candi3_1, ip1_candi4_1, ip1_candi5_1;
wire [`BIT_DEPTH-1:0]     ip1_candi3_2, ip1_candi4_2, ip1_candi5_2;
wire [`BIT_DEPTH-1:0]     ip1_candi3_3, ip1_candi4_3, ip1_candi5_3;
                          
wire [`BIT_DEPTH-1:0]     ip1_candi6_0, ip1_candi7_0, ip1_candi8_0;
wire [`BIT_DEPTH-1:0]     ip1_candi6_1, ip1_candi7_1, ip1_candi8_1;
wire [`BIT_DEPTH-1:0]     ip1_candi6_2, ip1_candi7_2, ip1_candi8_2;
wire [`BIT_DEPTH-1:0]     ip1_candi6_3, ip1_candi7_3, ip1_candi8_3;

wire [`SATD_BLK_BITS-2:0] sg0_satd0_4xn,sg0_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg1_satd0_4xn,sg1_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg2_satd0_4xn,sg2_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg3_satd0_4xn,sg3_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg4_satd0_4xn,sg4_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg5_satd0_4xn,sg5_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg6_satd0_4xn,sg6_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg7_satd0_4xn,sg7_satd1_4xn             ;
wire [`SATD_BLK_BITS-2:0] sg8_satd0_4xn,sg8_satd1_4xn             ;

//satd gen 
wire                      satd_4x4_valid                          ; 

wire [`SATD_BLK_BITS-1:0] satd0_8xn,satd1_8xn,satd2_8xn           ;
wire [`SATD_BLK_BITS-1:0 ]satd3_8xn,satd4_8xn                     ;
wire [`SATD_BLK_BITS-1:0] satd5_8xn,satd6_8xn,satd7_8xn           ;
wire [`SATD_BLK_BITS-1:0] satd8_8xn                               ;

wire [`SATD_BLK_BITS-1:0] satd0_blk,satd1_blk,satd2_blk           ;
wire [`SATD_BLK_BITS-1:0] satd3_blk,satd4_blk                     ;
wire [`SATD_BLK_BITS-1:0] satd5_blk,satd6_blk,satd7_blk           ;
wire [`SATD_BLK_BITS-1:0] satd8_blk                               ;
wire                      satd_blk_v                              ;
//comparison
wire [`SATD_BLK_BITS  :0] bcost                                   ;
wire [1               :0] bcand_x, bcand_y                        ;
wire                      cost_valid                              ;
wire [`FMVD_LEN-1     :0] mv_x, mv_y                              ;
wire                       half_flag                              ;
wire [`FMVD_LEN-1     :0] mvp_x, mvp_y                            ;

// ********************************************
//                                             
//    Reg   DECLARATION                         
//                                             
// ******************************************** 
reg  [2:0]                xHFracl_ip0, yHFracl_ip0                ;
reg  [1:0]                xQFracl_ip0, yQFracl_ip0                ;
reg  [2:0]                xHFracl_ip1, yHFracl_ip1                ;
reg  [1:0]                xQFracl_ip1, yQFracl_ip1                ;
reg  [`SATD_BLK_BITS-1:0] satd0_blk0,satd1_blk0,satd2_blk0        ;
reg  [`SATD_BLK_BITS-1:0] satd3_blk0,satd4_blk0                   ;
reg  [`SATD_BLK_BITS-1:0] satd5_blk0,satd6_blk0,satd7_blk0        ;
reg  [`SATD_BLK_BITS-1:0] satd8_blk0                              ;
reg  [`SATD_BLK_BITS-1:0] satd0_blk1,satd1_blk1,satd2_blk1        ;
reg  [`SATD_BLK_BITS-1:0] satd3_blk1,satd4_blk1                   ;
reg  [`SATD_BLK_BITS-1:0] satd5_blk1,satd6_blk1,satd7_blk1        ;
reg  [`SATD_BLK_BITS-1:0] satd8_blk1                              ;
reg                       satd_blk_v_d                            ;
reg                       switch_blk4xn                           ;

//comparison
reg  [1               :0] pos0_x,pos0_y,pos1_x,pos1_y             ;
reg                                     switch_bcandi             ;
reg  [2*`FMVD_LEN-1   :0] fmv0,fmv1                               ;
reg                       best_candi_valid                        ;

// ******************************************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ****************************************************************** 

assign candi_valid_o = ip0_candi_valid;


// ****************************************************************** 
//
//     Sub  modules 
//                                             
// ******************************************************************


// ****************************************************************** 
//
//    interpolator
//                                             
// ****************************************************************** 
interpolator_4pel ip0_4pel(
        .clk_i           ( clk_i           ),
        .rst_n_i         ( rst_n_i         ),

        .half_ip_flag_i  ( half_flag_ip_i  ),
        .yHFracl_i       ( yHFracl_ip0     ),
        .xHFracl_i       ( xHFracl_ip0     ),
        
        .end_one_blk_input_i( end_one_blk_input_i),
        .area_co_locate_i( area_co_locate_i),
        .end_oneblk_ip_o ( end_oneblk_ip_o ),

        .refpel_valid_i  ( ip0_rpvalid_i   ),
        .ref_pel0_i      ( ip0_rp0_i       ),
        .ref_pel1_i      ( ip0_rp1_i       ),
        .ref_pel2_i      ( ip0_rp2_i       ),
        .ref_pel3_i      ( ip0_rp3_i       ),
        .ref_pel4_i      ( ip0_rp4_i       ),
        .ref_pel5_i      ( ip0_rp5_i       ),
        .ref_pel6_i      ( ip0_rp6_i       ),
        .ref_pel7_i      ( ip0_rp7_i       ),
        .ref_pel8_i      ( ip0_rp8_i       ),
        .ref_pel9_i      ( ip0_rp9_i       ),

        .candi_valid_o   ( ip0_candi_valid ),
        .candi0_0_o      ( ip0_candi0_0    ),
        .candi0_1_o      ( ip0_candi0_1    ),
        .candi0_2_o      ( ip0_candi0_2    ),
        .candi0_3_o      ( ip0_candi0_3    ),

        .candi1_0_o      ( ip0_candi1_0    ),
        .candi1_1_o      ( ip0_candi1_1    ),
        .candi1_2_o      ( ip0_candi1_2    ),
        .candi1_3_o      ( ip0_candi1_3    ),

        .candi2_0_o      ( ip0_candi2_0    ),
        .candi2_1_o      ( ip0_candi2_1    ),
        .candi2_2_o      ( ip0_candi2_2    ),
        .candi2_3_o      ( ip0_candi2_3    ),

        .candi3_0_o      ( ip0_candi3_0    ),
        .candi3_1_o      ( ip0_candi3_1    ),
        .candi3_2_o      ( ip0_candi3_2    ),
        .candi3_3_o      ( ip0_candi3_3    ),

        .candi4_0_o      ( ip0_candi4_0    ),
        .candi4_1_o      ( ip0_candi4_1    ),
        .candi4_2_o      ( ip0_candi4_2    ),
        .candi4_3_o      ( ip0_candi4_3    ),

        .candi5_0_o      ( ip0_candi5_0    ),
        .candi5_1_o      ( ip0_candi5_1    ),
        .candi5_2_o      ( ip0_candi5_2    ),
        .candi5_3_o      ( ip0_candi5_3    ),

        .candi6_0_o      ( ip0_candi6_0    ),
        .candi6_1_o      ( ip0_candi6_1    ),
        .candi6_2_o      ( ip0_candi6_2    ),
        .candi6_3_o      ( ip0_candi6_3    ),

        .candi7_0_o      ( ip0_candi7_0    ),
        .candi7_1_o      ( ip0_candi7_1    ),
        .candi7_2_o      ( ip0_candi7_2    ),
        .candi7_3_o      ( ip0_candi7_3    ),

        .candi8_0_o      ( ip0_candi8_0    ),
        .candi8_1_o      ( ip0_candi8_1    ),
        .candi8_2_o      ( ip0_candi8_2    ),
        .candi8_3_o      ( ip0_candi8_3    )
);

interpolator_4pel ip1_4pel(
        .clk_i           ( clk_i           ),
        .rst_n_i         ( rst_n_i         ),

        .half_ip_flag_i  ( half_flag_ip_i  ),
        .yHFracl_i       ( yHFracl_ip1     ),
        .xHFracl_i       ( xHFracl_ip1     ),
        
        .end_one_blk_input_i( end_one_blk_input_i),
        .area_co_locate_i( area_co_locate_i),
        .end_oneblk_ip_o (                 ),

        .refpel_valid_i  ( ip1_rpvalid_i   ),
        .ref_pel0_i      ( ip1_rp0_i       ),
        .ref_pel1_i      ( ip1_rp1_i       ),
        .ref_pel2_i      ( ip1_rp2_i       ),
        .ref_pel3_i      ( ip1_rp3_i       ),
        .ref_pel4_i      ( ip1_rp4_i       ),
        .ref_pel5_i      ( ip1_rp5_i       ),
        .ref_pel6_i      ( ip1_rp6_i       ),
        .ref_pel7_i      ( ip1_rp7_i       ),
        .ref_pel8_i      ( ip1_rp8_i       ),
        .ref_pel9_i      ( ip1_rp9_i       ),

        .candi_valid_o   ( ip1_candi_valid ),
        .candi0_0_o      ( ip1_candi0_0    ),
        .candi0_1_o      ( ip1_candi0_1    ),
        .candi0_2_o      ( ip1_candi0_2    ),
        .candi0_3_o      ( ip1_candi0_3    ),

        .candi1_0_o      ( ip1_candi1_0    ),
        .candi1_1_o      ( ip1_candi1_1    ),
        .candi1_2_o      ( ip1_candi1_2    ),
        .candi1_3_o      ( ip1_candi1_3    ),

        .candi2_0_o      ( ip1_candi2_0    ),
        .candi2_1_o      ( ip1_candi2_1    ),
        .candi2_2_o      ( ip1_candi2_2    ),
        .candi2_3_o      ( ip1_candi2_3    ),

        .candi3_0_o      ( ip1_candi3_0    ),
        .candi3_1_o      ( ip1_candi3_1    ),
        .candi3_2_o      ( ip1_candi3_2    ),
        .candi3_3_o      ( ip1_candi3_3    ),

        .candi4_0_o      ( ip1_candi4_0    ),
        .candi4_1_o      ( ip1_candi4_1    ),
        .candi4_2_o      ( ip1_candi4_2    ),
        .candi4_3_o      ( ip1_candi4_3    ),

        .candi5_0_o      ( ip1_candi5_0    ),
        .candi5_1_o      ( ip1_candi5_1    ),
        .candi5_2_o      ( ip1_candi5_2    ),
        .candi5_3_o      ( ip1_candi5_3    ),

        .candi6_0_o      ( ip1_candi6_0    ),
        .candi6_1_o      ( ip1_candi6_1    ),
        .candi6_2_o      ( ip1_candi6_2    ),
        .candi6_3_o      ( ip1_candi6_3    ),

        .candi7_0_o      ( ip1_candi7_0    ),
        .candi7_1_o      ( ip1_candi7_1    ),
        .candi7_2_o      ( ip1_candi7_2    ),
        .candi7_3_o      ( ip1_candi7_3    ),

        .candi8_0_o      ( ip1_candi8_0    ),
        .candi8_1_o      ( ip1_candi8_1    ),
        .candi8_2_o      ( ip1_candi8_2    ),
        .candi8_3_o      ( ip1_candi8_3    )
);
// ****************************************************************** 
//
//    satd gen
//
// ****************************************************************** 
assign satd_4x4_valid_o = satd_4x4_valid;

satd_gen_double4xn sg0_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi0_0     ),
       .ip0_sp1_i        ( ip0_candi0_1     ),
       .ip0_sp2_i        ( ip0_candi0_2     ),
       .ip0_sp3_i        ( ip0_candi0_3     ),
       .ip1_sp0_i        ( ip1_candi0_0     ),
       .ip1_sp1_i        ( ip1_candi0_1     ),
       .ip1_sp2_i        ( ip1_candi0_2     ),
       .ip1_sp3_i        ( ip1_candi0_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg0_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg0_satd1_4xn    ),
       .satd_4x4_valid_o ( satd_4x4_valid   ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg1_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi1_0     ),
       .ip0_sp1_i        ( ip0_candi1_1     ),
       .ip0_sp2_i        ( ip0_candi1_2     ),
       .ip0_sp3_i        ( ip0_candi1_3     ),
       .ip1_sp0_i        ( ip1_candi1_0     ),
       .ip1_sp1_i        ( ip1_candi1_1     ),
       .ip1_sp2_i        ( ip1_candi1_2     ),
       .ip1_sp3_i        ( ip1_candi1_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg1_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg1_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg2_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi2_0     ),
       .ip0_sp1_i        ( ip0_candi2_1     ),
       .ip0_sp2_i        ( ip0_candi2_2     ),
       .ip0_sp3_i        ( ip0_candi2_3     ),
       .ip1_sp0_i        ( ip1_candi2_0     ),
       .ip1_sp1_i        ( ip1_candi2_1     ),
       .ip1_sp2_i        ( ip1_candi2_2     ),
       .ip1_sp3_i        ( ip1_candi2_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg2_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg2_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg3_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi3_0     ),
       .ip0_sp1_i        ( ip0_candi3_1     ),
       .ip0_sp2_i        ( ip0_candi3_2     ),
       .ip0_sp3_i        ( ip0_candi3_3     ),
       .ip1_sp0_i        ( ip1_candi3_0     ),
       .ip1_sp1_i        ( ip1_candi3_1     ),
       .ip1_sp2_i        ( ip1_candi3_2     ),
       .ip1_sp3_i        ( ip1_candi3_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg3_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg3_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg4_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi4_0     ),
       .ip0_sp1_i        ( ip0_candi4_1     ),
       .ip0_sp2_i        ( ip0_candi4_2     ),
       .ip0_sp3_i        ( ip0_candi4_3     ),
       .ip1_sp0_i        ( ip1_candi4_0     ),
       .ip1_sp1_i        ( ip1_candi4_1     ),
       .ip1_sp2_i        ( ip1_candi4_2     ),
       .ip1_sp3_i        ( ip1_candi4_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg4_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg4_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg5_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi5_0     ),
       .ip0_sp1_i        ( ip0_candi5_1     ),
       .ip0_sp2_i        ( ip0_candi5_2     ),
       .ip0_sp3_i        ( ip0_candi5_3     ),
       .ip1_sp0_i        ( ip1_candi5_0     ),
       .ip1_sp1_i        ( ip1_candi5_1     ),
       .ip1_sp2_i        ( ip1_candi5_2     ),
       .ip1_sp3_i        ( ip1_candi5_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg5_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg5_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg6_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi6_0     ),
       .ip0_sp1_i        ( ip0_candi6_1     ),
       .ip0_sp2_i        ( ip0_candi6_2     ),
       .ip0_sp3_i        ( ip0_candi6_3     ),
       .ip1_sp0_i        ( ip1_candi6_0     ),
       .ip1_sp1_i        ( ip1_candi6_1     ),
       .ip1_sp2_i        ( ip1_candi6_2     ),
       .ip1_sp3_i        ( ip1_candi6_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg6_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg6_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg7_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi7_0     ),
       .ip0_sp1_i        ( ip0_candi7_1     ),
       .ip0_sp2_i        ( ip0_candi7_2     ),
       .ip0_sp3_i        ( ip0_candi7_3     ),
       .ip1_sp0_i        ( ip1_candi7_0     ),
       .ip1_sp1_i        ( ip1_candi7_1     ),
       .ip1_sp2_i        ( ip1_candi7_2     ),
       .ip1_sp3_i        ( ip1_candi7_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg7_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg7_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);

satd_gen_double4xn sg8_d4xn(
       .clk_i            ( clk_i            ),
       .rst_n_i          ( rst_n_i          ),
       //CMB pels                           
       .cmb_p0_i         ( cmb_p0_i         ),
       .cmb_p1_i         ( cmb_p1_i         ),
       .cmb_p2_i         ( cmb_p2_i         ),
       .cmb_p3_i         ( cmb_p3_i         ),
       .cmb_p4_i         ( cmb_p4_i         ),
       .cmb_p5_i         ( cmb_p5_i         ),
       .cmb_p6_i         ( cmb_p6_i         ),
       .cmb_p7_i         ( cmb_p7_i         ),
       //subpels                            
       .valid_i          ( ip0_candi_valid  ),
       .ip0_sp0_i        ( ip0_candi8_0     ),
       .ip0_sp1_i        ( ip0_candi8_1     ),
       .ip0_sp2_i        ( ip0_candi8_2     ),
       .ip0_sp3_i        ( ip0_candi8_3     ),
       .ip1_sp0_i        ( ip1_candi8_0     ),
       .ip1_sp1_i        ( ip1_candi8_1     ),
       .ip1_sp2_i        ( ip1_candi8_2     ),
       .ip1_sp3_i        ( ip1_candi8_3     ),
       //                                   
       .hd0_satd_4xn_o   ( sg8_satd0_4xn    ),
       .hd1_satd_4xn_o   ( sg8_satd1_4xn    ),
       .satd_4x4_valid_o (                  ),
       .satd_blk_valid_i ( satd_blk_valid_i )
);


//add two satd 4x4
assign satd0_8xn = {1'b0,sg0_satd0_4xn} + {1'b0,sg0_satd1_4xn};
assign satd1_8xn = {1'b0,sg1_satd0_4xn} + {1'b0,sg1_satd1_4xn};
assign satd2_8xn = {1'b0,sg2_satd0_4xn} + {1'b0,sg2_satd1_4xn};
assign satd3_8xn = {1'b0,sg3_satd0_4xn} + {1'b0,sg3_satd1_4xn};
assign satd4_8xn = {1'b0,sg4_satd0_4xn} + {1'b0,sg4_satd1_4xn};
assign satd5_8xn = {1'b0,sg5_satd0_4xn} + {1'b0,sg5_satd1_4xn};
assign satd6_8xn = {1'b0,sg6_satd0_4xn} + {1'b0,sg6_satd1_4xn};
assign satd7_8xn = {1'b0,sg7_satd0_4xn} + {1'b0,sg7_satd1_4xn};
assign satd8_8xn = {1'b0,sg8_satd0_4xn} + {1'b0,sg8_satd1_4xn};

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    satd0_blk1 <= 0;
    satd1_blk1 <= 0;
    satd2_blk1 <= 0;
    satd3_blk1 <= 0;
    satd4_blk1 <= 0;
    satd5_blk1 <= 0;
    satd6_blk1 <= 0;
    satd7_blk1 <= 0;
    satd8_blk1 <= 0;
  end
  else if(working_mode_satd_i) begin//0:for 4x4 1:upper 8x8
    if(satd_blk_valid_i) begin
      satd0_blk1 <= satd0_8xn;
      satd1_blk1 <= satd1_8xn;
      satd2_blk1 <= satd2_8xn;
      satd3_blk1 <= satd3_8xn;
      satd4_blk1 <= satd4_8xn;
      satd5_blk1 <= satd5_8xn;
      satd6_blk1 <= satd6_8xn;
      satd7_blk1 <= satd7_8xn;
      satd8_blk1 <= satd8_8xn;
    end
  end
  else begin
    if(satd_blk_valid_i) begin
      satd0_blk1 <= {1'b0,sg0_satd1_4xn};
      satd1_blk1 <= {1'b0,sg1_satd1_4xn};
      satd2_blk1 <= {1'b0,sg2_satd1_4xn};
      satd3_blk1 <= {1'b0,sg3_satd1_4xn};
      satd4_blk1 <= {1'b0,sg4_satd1_4xn};
      satd5_blk1 <= {1'b0,sg5_satd1_4xn};
      satd6_blk1 <= {1'b0,sg6_satd1_4xn};
      satd7_blk1 <= {1'b0,sg7_satd1_4xn};
      satd8_blk1 <= {1'b0,sg8_satd1_4xn};
    end
  end
end

always @( * ) begin
      satd0_blk0  = {1'b0,sg0_satd0_4xn};
      satd1_blk0  = {1'b0,sg1_satd0_4xn};
      satd2_blk0  = {1'b0,sg2_satd0_4xn};
      satd3_blk0  = {1'b0,sg3_satd0_4xn};
      satd4_blk0  = {1'b0,sg4_satd0_4xn};
      satd5_blk0  = {1'b0,sg5_satd0_4xn};
      satd6_blk0  = {1'b0,sg6_satd0_4xn};
      satd7_blk0  = {1'b0,sg7_satd0_4xn};
      satd8_blk0  = {1'b0,sg8_satd0_4xn};
end
    

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    satd_blk_v_d <= 0;
  else 
    satd_blk_v_d <= satd_blk_valid_i;
end
assign  satd_blk_v = (satd_blk_v_d) || (satd_blk_valid_i && (!working_mode_satd_i));

always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    switch_blk4xn <= 0;
  else if(!working_mode_bcs_i)
    if(satd_blk_v)
      switch_blk4xn <= ~switch_blk4xn;
end

assign satd0_blk = (switch_blk4xn | working_mode_bcs_i )?satd0_blk1:satd0_blk0;
assign satd1_blk = (switch_blk4xn | working_mode_bcs_i )?satd1_blk1:satd1_blk0;
assign satd2_blk = (switch_blk4xn | working_mode_bcs_i )?satd2_blk1:satd2_blk0;
assign satd3_blk = (switch_blk4xn | working_mode_bcs_i )?satd3_blk1:satd3_blk0;
assign satd4_blk = (switch_blk4xn | working_mode_bcs_i )?satd4_blk1:satd4_blk0;
assign satd5_blk = (switch_blk4xn | working_mode_bcs_i )?satd5_blk1:satd5_blk0;
assign satd6_blk = (switch_blk4xn | working_mode_bcs_i )?satd6_blk1:satd6_blk0;
assign satd7_blk = (switch_blk4xn | working_mode_bcs_i )?satd7_blk1:satd7_blk0;
assign satd8_blk = (switch_blk4xn | working_mode_bcs_i )?satd8_blk1:satd8_blk0;

// ****************************************************************** 
//
//    comparison
//
// ****************************************************************** 

assign half_flag = half_flag_bcs_i;
assign mvp_x = mvp_i[2*`FMVD_LEN-1:1*`FMVD_LEN];
assign mvp_y = mvp_i[1*`FMVD_LEN-1:0*`FMVD_LEN];      

best_candidate #(.SATD_BITS(`SATD_BLK_BITS)) bcandi(
    .clk_i         ( clk_i           ),
    .rst_n_i       ( rst_n_i         ),
    
    .qp_i          ( qp_i            ),
    
    .mv_x_i        ( mv_x            ),
    .mv_y_i        ( mv_y            ),
    .mvp_x_i       ( mvp_x           ),
    .mvp_y_i       ( mvp_y           ),
    
    .half_i        ( half_flag       ),

    .satd_valid_i  ( satd_blk_v      ),
    .satd0_i       ( satd0_blk       ),
    .satd1_i       ( satd1_blk       ),
    .satd2_i       ( satd2_blk       ),
    .satd3_i       ( satd3_blk       ),
    .satd4_i       ( satd4_blk       ),
    .satd5_i       ( satd5_blk       ),
    .satd6_i       ( satd6_blk       ),
    .satd7_i       ( satd7_blk       ),
    .satd8_i       ( satd8_blk       ),
    
    .bcost_o       ( bcost           ),
    .bcand_x_o     ( bcand_x         ),
    .bcand_y_o     ( bcand_y         ),
    .cost_valid_o  ( cost_valid      )
);

always @(posedge clk_i or  negedge rst_n_i) begin
  if(!rst_n_i)
    switch_bcandi <= 0;
  else if(cost_valid & (!working_mode_bcs_i))
    switch_bcandi <= switch_bcandi + 1'b1;
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    fmv0 <= 4'd0;
    fmv1 <= 4'd0;
  end
  else if(half_flag) begin
    if( cost_valid ) begin
      if(working_mode_bcs_i) begin
        fmv0[2*`FMVD_LEN-1:`FMVD_LEN]<= {imv0_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00}  + {{(`FMVD_LEN-3){bcand_y[1]}},bcand_y,1'b0};
        fmv0[`FMVD_LEN-1:0]          <= {imv0_i[  `IMVD_LEN-1:0]         ,2'b00} + {{(`FMVD_LEN-3){bcand_x[1]}},bcand_x,1'b0};
        fmv1[2*`FMVD_LEN-1:`FMVD_LEN]<= {imv1_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00}  + {{(`FMVD_LEN-3){bcand_y[1]}},bcand_y,1'b0};
        fmv1[`FMVD_LEN-1:0]          <= {imv1_i[  `IMVD_LEN-1:0]         ,2'b00} + {{(`FMVD_LEN-3){bcand_x[1]}},bcand_x,1'b0};
      end
      else
        if( !switch_bcandi ) begin
          fmv0[2*`FMVD_LEN-1:`FMVD_LEN]<= {imv0_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00}  + {{(`FMVD_LEN-3){bcand_y[1]}},bcand_y,1'b0};
          fmv0[`FMVD_LEN-1:0]          <= {imv0_i[  `IMVD_LEN-1:0]         ,2'b00} + {{(`FMVD_LEN-3){bcand_x[1]}},bcand_x,1'b0};
        end
        else begin
         fmv1[2*`FMVD_LEN-1:`FMVD_LEN] <= {imv1_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00} + {{(`FMVD_LEN-3){bcand_y[1]}},bcand_y,1'b0};
         fmv1[`FMVD_LEN-1:0]           <= {imv1_i[`IMVD_LEN-1:0]           ,2'b00}+ {{(`FMVD_LEN-3){bcand_x[1]}},bcand_x,1'b0};
        end
    end
    else begin
      fmv0 <= fmv0;
      fmv1 <= fmv1;
    end
  end
  else
    if( cost_valid ) begin
     if(working_mode_bcs_i) begin
        fmv0[2*`FMVD_LEN-1:`FMVD_LEN]<= fmv0[2*`FMVD_LEN-1:`FMVD_LEN] + {{(`FMVD_LEN-2){bcand_y[1]}},bcand_y};
        fmv0[`FMVD_LEN-1:0]          <= fmv0[`FMVD_LEN-1:0]           + {{(`FMVD_LEN-2){bcand_x[1]}},bcand_x};
        fmv1[2*`FMVD_LEN-1:`FMVD_LEN]<= fmv1[2*`FMVD_LEN-1:`FMVD_LEN] + {{(`FMVD_LEN-2){bcand_y[1]}},bcand_y};
        fmv1[`FMVD_LEN-1:0]          <= fmv1[`FMVD_LEN-1:0]           + {{(`FMVD_LEN-2){bcand_x[1]}},bcand_x};
      end
      else
        if( !switch_bcandi ) begin
          fmv0[2*`FMVD_LEN-1:`FMVD_LEN]<= fmv0[2*`FMVD_LEN-1:`FMVD_LEN] + {{(`FMVD_LEN-2){bcand_y[1]}},bcand_y};
          fmv0[`FMVD_LEN-1:0]          <= fmv0[`FMVD_LEN-1:0]           + {{(`FMVD_LEN-2){bcand_x[1]}},bcand_x};
        end
        else begin
         fmv1[2*`FMVD_LEN-1:`FMVD_LEN]<= fmv1[2*`FMVD_LEN-1:`FMVD_LEN] + {{(`FMVD_LEN-2){bcand_y[1]}},bcand_y};
         fmv1[`FMVD_LEN-1:0]          <= fmv1[`FMVD_LEN-1:0]           + {{(`FMVD_LEN-2){bcand_x[1]}},bcand_x};
        end
    end
end

assign {mv_y,mv_x} = (half_flag)? ((switch_blk4xn)?{{imv1_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00},{imv1_i[`IMVD_LEN-1:0],2'b00}}:
                                                   {{imv0_i[2*`IMVD_LEN-1:`IMVD_LEN],2'b00},{imv0_i[`IMVD_LEN-1:0],2'b00}}):
                                                   ((switch_blk4xn)?fmv1:fmv0);

assign fmv0_o = fmv0;
assign fmv1_o = fmv1;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    {xHFracl_ip0,yHFracl_ip0} <= 6'd0;
    {xHFracl_ip1,yHFracl_ip1} <= 6'd0;
  end
  else if(half_flag) begin
    if( cost_valid ) begin
      if(working_mode_bcs_i) begin
        {xHFracl_ip0,yHFracl_ip0} <= {{bcand_x,1'b0},{bcand_y,1'b0}};
        {xHFracl_ip1,yHFracl_ip1} <= {{bcand_x,1'b0},{bcand_y,1'b0}};
      end
      else
        if( !switch_bcandi ) begin
          {xHFracl_ip0,yHFracl_ip0} <= {{bcand_x,1'b0},{bcand_y,1'b0}};
        end
        else begin
         {xHFracl_ip1,yHFracl_ip1} <= {{bcand_x,1'b0},{bcand_y,1'b0}};
        end
    end
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    best_candi_valid <= 1'b0;
  else
    best_candi_valid <= (working_mode_bcs_i)?cost_valid:(switch_bcandi&cost_valid);
end
assign best_candi_v_o = best_candi_valid;

assign bcost_valid_o  = cost_valid;
assign bcost_o        = bcost[`BIT_DEPTH+10-1:0];


endmodule
