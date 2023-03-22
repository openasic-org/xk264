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

module mc_luma(
       clk_i,
       rst_n_i,
       
       HFracl0_i,
       HFracl1_i,
       
       QFracl0_i,
       QFracl1_i,
//-----------------------------------------------------------------------------
//     interpolator signals
//-----------------------------------------------------------------------------
       end_oneblk_input_i, //signal to interpolator need to shift down 2 cycles still.
       area_co_locate_i,//after delaying 5 cycle, this signal indicates the output candidates are valid.
       end_oneblk_ip_o,
       
       ip0_rpvalid_i,
       ip0_rp0_i,
       ip0_rp1_i,
       ip0_rp2_i,
       ip0_rp3_i,
       ip0_rp4_i,
       ip0_rp5_i,
       ip0_rp6_i,
       ip0_rp7_i,
       ip0_rp8_i,
       ip0_rp9_i,
       
       ip1_rpvalid_i,
       ip1_rp0_i,
       ip1_rp1_i,
       ip1_rp2_i,
       ip1_rp3_i,
       ip1_rp4_i,
       ip1_rp5_i,
       ip1_rp6_i,
       ip1_rp7_i,
       ip1_rp8_i,
       ip1_rp9_i,
       
       half_ip_flag_i,   //1:half refinement, 0:quarter refinement
       
       candi_valid_o,    //output to fme_ctrl for cmb pixels read
//-----------------------------------------------------------------------------
//     mc luma output controll
//-----------------------------------------------------------------------------
       mc_luma_wren_o,
       mc_luma_o
);


// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************
input                     clk_i;
input                     rst_n_i;
input  [3:0]              HFracl0_i;
input  [3:0]              HFracl1_i;
input  [3:0]              QFracl0_i;
input  [3:0]              QFracl1_i;
input                     end_oneblk_input_i;
input                     area_co_locate_i;
output                    end_oneblk_ip_o;
input                     ip0_rpvalid_i;
input  [`BIT_DEPTH-1 :0]  ip0_rp0_i, ip0_rp1_i, ip0_rp2_i, ip0_rp3_i, ip0_rp4_i;
input  [`BIT_DEPTH-1 :0]  ip0_rp5_i, ip0_rp6_i, ip0_rp7_i, ip0_rp8_i, ip0_rp9_i;
input                     ip1_rpvalid_i;
input  [`BIT_DEPTH-1 :0]  ip1_rp0_i, ip1_rp1_i, ip1_rp2_i, ip1_rp3_i, ip1_rp4_i;
input  [`BIT_DEPTH-1 :0]  ip1_rp5_i, ip1_rp6_i, ip1_rp7_i, ip1_rp8_i, ip1_rp9_i;
input                     half_ip_flag_i;
output                    candi_valid_o; 
//mc
output                    mc_luma_wren_o;
output [8*`BIT_DEPTH-1:0] mc_luma_o;



// ********************************************
//                                
//    Register DECLARATION            
//                                      
// ********************************************
reg  [2:0]                xHFracl_ip0, yHFracl_ip0;
reg  [2:0]                xHFracl_ip1, yHFracl_ip1;
reg  [`BIT_DEPTH-1:0]     mc_luma7,mc_luma6,mc_luma5,mc_luma4,mc_luma3,mc_luma2,mc_luma1,mc_luma0;
reg                       mcl_valid;


// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
wire                      ip0_candi_valid;
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

wire  ip1_candi_valid  ; 

///////////////////////////////////////////////////////////////////////////////
//    interpolator
///////////////////////////////////////////////////////////////////////////////
assign candi_valid_o = ip0_candi_valid;

mc_ip_4pel mc_ip0_4pel(
        .clk_i           ( clk_i           ),
        .rst_n_i         ( rst_n_i         ),

        .half_ip_flag_i  ( half_ip_flag_i  ),
        .yHFracl_i       ( {HFracl0_i[3:2],1'b0} ),
        .xHFracl_i       ( {HFracl0_i[1:0],1'b0} ),
        
        .end_oneblk_input_i( end_oneblk_input_i ),
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

mc_ip_4pel mc_ip1_4pel(
        .clk_i           ( clk_i           ),
        .rst_n_i         ( rst_n_i         ),

        .half_ip_flag_i  ( half_ip_flag_i  ),
        .yHFracl_i       ( {HFracl1_i[3:2],1'b0} ),
        .xHFracl_i       ( {HFracl1_i[1:0],1'b0} ),
        
        .end_oneblk_input_i( end_oneblk_input_i ),
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

///////////////////////////////////////////////////////////////////////////////
//    mc luma
///////////////////////////////////////////////////////////////////////////////

always @( * ) begin
  mcl_valid = ip0_candi_valid;
end
    
always @( * ) begin
  if(ip0_candi_valid) begin
      case({QFracl0_i})
        4'b0000: begin
          mc_luma0 = ip0_candi4_0;
          mc_luma1 = ip0_candi4_1;
          mc_luma2 = ip0_candi4_2;
          mc_luma3 = ip0_candi4_3;
        end
        4'b0100: begin
          mc_luma0 = ip0_candi7_0;
          mc_luma1 = ip0_candi7_1;
          mc_luma2 = ip0_candi7_2;
          mc_luma3 = ip0_candi7_3;
        end
        4'b1100: begin
          mc_luma0 = ip0_candi1_0;
          mc_luma1 = ip0_candi1_1;
          mc_luma2 = ip0_candi1_2;
          mc_luma3 = ip0_candi1_3;
        end
        4'b0001: begin
          mc_luma0 = ip0_candi5_0;
          mc_luma1 = ip0_candi5_1;
          mc_luma2 = ip0_candi5_2;
          mc_luma3 = ip0_candi5_3;
        end
        4'b0011: begin
          mc_luma0 = ip0_candi3_0;
          mc_luma1 = ip0_candi3_1;
          mc_luma2 = ip0_candi3_2;
          mc_luma3 = ip0_candi3_3;
        end
        4'b1111: begin
          mc_luma0 = ip0_candi0_0;
          mc_luma1 = ip0_candi0_1;
          mc_luma2 = ip0_candi0_2;
          mc_luma3 = ip0_candi0_3;
        end
        4'b0111: begin
          mc_luma0 = ip0_candi6_0;
          mc_luma1 = ip0_candi6_1;
          mc_luma2 = ip0_candi6_2;
          mc_luma3 = ip0_candi6_3;
        end        
        4'b0101: begin
          mc_luma0 = ip0_candi8_0;
          mc_luma1 = ip0_candi8_1;
          mc_luma2 = ip0_candi8_2;
          mc_luma3 = ip0_candi8_3;
        end 
        4'b1101: begin
          mc_luma0 = ip0_candi2_0;
          mc_luma1 = ip0_candi2_1;
          mc_luma2 = ip0_candi2_2;
          mc_luma3 = ip0_candi2_3;
        end
        default: begin  //edit by xyuan 
          mc_luma0 = 'd0 ;  //mc_luma0;
          mc_luma1 = 'd0 ;  //mc_luma1;
          mc_luma2 = 'd0 ;  //mc_luma2;
          mc_luma3 = 'd0 ;  //mc_luma3;
        end   //end by xyuan 
      endcase
    end
//add by xyuan 
  else  begin
     mc_luma0 = 'd0 ;  //mc_luma0;
     mc_luma1 = 'd0 ;  //mc_luma1;
     mc_luma2 = 'd0 ;  //mc_luma2;
     mc_luma3 = 'd0 ;  //mc_luma3;
  end
//end by xyuan 
end


always @( * ) begin
  if(ip1_candi_valid) begin
      case(QFracl1_i)
        4'b0000: begin
          mc_luma4 = ip1_candi4_0;
          mc_luma5 = ip1_candi4_1;
          mc_luma6 = ip1_candi4_2;
          mc_luma7 = ip1_candi4_3;
        end
        4'b0100: begin
          mc_luma4 = ip1_candi7_0;
          mc_luma5 = ip1_candi7_1;
          mc_luma6 = ip1_candi7_2;
          mc_luma7 = ip1_candi7_3;
        end
        4'b1100: begin
          mc_luma4 = ip1_candi1_0;
          mc_luma5 = ip1_candi1_1;
          mc_luma6 = ip1_candi1_2;
          mc_luma7 = ip1_candi1_3;
        end
        4'b0001: begin
          mc_luma4 = ip1_candi5_0;
          mc_luma5 = ip1_candi5_1;
          mc_luma6 = ip1_candi5_2;
          mc_luma7 = ip1_candi5_3;
        end
        4'b0011: begin
          mc_luma4 = ip1_candi3_0;
          mc_luma5 = ip1_candi3_1;
          mc_luma6 = ip1_candi3_2;
          mc_luma7 = ip1_candi3_3;
        end
        4'b1111: begin
          mc_luma4 = ip1_candi0_0;
          mc_luma5 = ip1_candi0_1;
          mc_luma6 = ip1_candi0_2;
          mc_luma7 = ip1_candi0_3;
        end
        4'b0111: begin
          mc_luma4 = ip1_candi6_0;
          mc_luma5 = ip1_candi6_1;
          mc_luma6 = ip1_candi6_2;
          mc_luma7 = ip1_candi6_3;
        end        
        4'b0101: begin
          mc_luma4 = ip1_candi8_0;
          mc_luma5 = ip1_candi8_1;
          mc_luma6 = ip1_candi8_2;
          mc_luma7 = ip1_candi8_3;
        end 
        4'b1101: begin
          mc_luma4 = ip1_candi2_0;
          mc_luma5 = ip1_candi2_1;
          mc_luma6 = ip1_candi2_2;
          mc_luma7 = ip1_candi2_3;
        end
        default: begin  //edit by xyuan 
          mc_luma4 = 'd0 ;  // mc_luma4;
          mc_luma5 = 'd0 ;  // mc_luma5;
          mc_luma6 = 'd0 ;  // mc_luma6;
          mc_luma7 = 'd0 ;  // mc_luma7;
        end   //end by xyuan 
      endcase
    end
//add by xyuan 
  else begin 
     mc_luma4 = 'd0 ;  
     mc_luma5 = 'd0 ;  
     mc_luma6 = 'd0 ;  
     mc_luma7 = 'd0 ;  
  end 
//end by xyuan 
end
assign mc_luma_o      = {mc_luma7,mc_luma6,mc_luma5,mc_luma4,mc_luma3,mc_luma2,mc_luma1,mc_luma0};
assign mc_luma_wren_o = mcl_valid;

endmodule
