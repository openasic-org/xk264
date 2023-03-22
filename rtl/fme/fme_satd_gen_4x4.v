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
// Filename       : satd_gen_4x4.v
// Author         : Jialiang Liu
// Created        : 2011-03-15
// Description    : 
//                  
//                  
//               
// $Id$ 
//-------------------------------------------------------------------  
`include "enc_defines.v"

module satd_gen_4x4(
       clk_i             ,
       rst_n_i           ,       
       valid_i           ,
       cmb_p0_i,cmb_p1_i ,
       cmb_p2_i,cmb_p3_i ,
       
       sp0_i,sp1_i       ,
       sp2_i,sp3_i       ,

       satd_4x4_o        ,
       satd_4x4_valid_o
);
// ********************************************
//                                             
//    Parameter DECLARATION                    
//                                             
// ********************************************
parameter DIFF_BITS_IN = `BIT_DEPTH+1;

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************    
input                         clk_i              ;
input                         rst_n_i            ;
//CMB pels                                       
input  [`BIT_DEPTH-1   :0]    cmb_p0_i, cmb_p1_i ; 
input  [`BIT_DEPTH-1   :0]    cmb_p2_i, cmb_p3_i ;
input                         valid_i            ;
//subpels                                        
input  [`BIT_DEPTH-1   :0]    sp0_i, sp1_i       ;
input  [`BIT_DEPTH-1   :0]    sp2_i, sp3_i       ;
                                                 
output [DIFF_BITS_IN+5 :0]    satd_4x4_o         ;
output                        satd_4x4_valid_o   ;

// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
wire                             htvalid           ;
wire signed [DIFF_BITS_IN-1  :0] diff0, diff1      ; 
wire signed [DIFF_BITS_IN-1  :0] diff2, diff3      ;
wire signed [DIFF_BITS_IN+4-1:0] hp_ht0_o,hp_ht1_o ;
wire signed [DIFF_BITS_IN+4-1:0] hp_ht2_o,hp_ht3_o ;
//abs 
wire [DIFF_BITS_IN+4-2       :0] abs_ht_o0,abs_ht_o1;
wire [DIFF_BITS_IN+4-2       :0] abs_ht_o2,abs_ht_o3;
//4-input add tree
wire [DIFF_BITS_IN+4-1       :0] sum_st1, sum_st2   ;//st:first
wire [DIFF_BITS_IN+4         :0] sum_st4            ;//st:first
wire                             sum_1s_valid       ;
// ********************************************
//                                             
//    Reg  DECLARATION                         
//                                             
// ********************************************
reg [DIFF_BITS_IN+4-2:0] abs_ht0,abs_ht1    ;
reg [DIFF_BITS_IN+4-2:0] abs_ht2,abs_ht3    ;
reg                      abs_ht_valid       ;
//4-input add tree
reg [1               :0] counter            ;
reg [DIFF_BITS_IN+5  :0] satd_4x4           ;//satd of one row
reg                      satd_4x4_valid     ;



// ********************************************
//                                             
//    Logic DECLARATION                         
//                                             
// ********************************************
    
assign diff0 = {1'b0,cmb_p0_i} - {1'b0,sp0_i};
assign diff1 = {1'b0,cmb_p1_i} - {1'b0,sp1_i};
assign diff2 = {1'b0,cmb_p2_i} - {1'b0,sp2_i};
assign diff3 = {1'b0,cmb_p3_i} - {1'b0,sp3_i};
    
hadamard_trans_2d #(.DIFF_BITS(DIFF_BITS_IN)) HT(
    .clk_i      (clk_i   ),
    .rst_n_i    (rst_n_i ),        
    .valid_i    (valid_i ),
    .diff0_i    (diff0   ),
    .diff1_i    (diff1   ),
    .diff2_i    (diff2   ),
    .diff3_i    (diff3   ),
    .htvalid_o  (htvalid ),
    .ht0_o      (hp_ht0_o),
    .ht1_o      (hp_ht1_o),
    .ht2_o      (hp_ht2_o),
    .ht3_o      (hp_ht3_o)
);

abs #(.INPUT_BITS(DIFF_BITS_IN+4)) abs0(.a_i(hp_ht0_o),.b_o(abs_ht_o0));
abs #(.INPUT_BITS(DIFF_BITS_IN+4)) abs1(.a_i(hp_ht1_o),.b_o(abs_ht_o1));
abs #(.INPUT_BITS(DIFF_BITS_IN+4)) abs2(.a_i(hp_ht2_o),.b_o(abs_ht_o2));
abs #(.INPUT_BITS(DIFF_BITS_IN+4)) abs3(.a_i(hp_ht3_o),.b_o(abs_ht_o3));

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    abs_ht0 <= 0;
    abs_ht1 <= 0;
    abs_ht2 <= 0;
    abs_ht3 <= 0;
  end
  else if(htvalid) begin
    abs_ht0 <= abs_ht_o0;
    abs_ht1 <= abs_ht_o1;
    abs_ht2 <= abs_ht_o2;
    abs_ht3 <= abs_ht_o3;
  end
end
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    abs_ht_valid <= 0;
  else
    abs_ht_valid <= htvalid;
end

assign sum_st1 = abs_ht0 + abs_ht1;
assign sum_st2 = abs_ht2 + abs_ht3;
assign sum_st4 = sum_st1 + sum_st2;
assign sum_1s_valid = abs_ht_valid;

always@(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    satd_4x4 <= 0;
  else
    if(sum_1s_valid)
      satd_4x4 <= ((counter == 2'd0)?{{DIFF_BITS_IN{1'b0}},{6{1'b0}}}:satd_4x4) + {1'b0,sum_st4};
    else
      satd_4x4 <= satd_4x4;
end
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i)
    satd_4x4_valid <= 0;
  else
    satd_4x4_valid <= sum_1s_valid&&(counter == 2'b11);
end
    
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) 
    counter <= 0;
  else
    if(sum_1s_valid)
      counter <= counter + 2'd1;
    else
       counter <= counter;
end
  
wire  [DIFF_BITS_IN+5+1 :0]    satd_4x4_o_w  ;
assign satd_4x4_o_w       = ({1'b0,satd_4x4} + 1'b1)>>1;///这个地方位数不再扩展了，
assign satd_4x4_o  = satd_4x4_o_w[DIFF_BITS_IN+5 :0];

assign satd_4x4_valid_o = satd_4x4_valid;
endmodule

// ---------------------------------------------
//            abs() function
// ---------------------------------------------
module abs
#(parameter INPUT_BITS = `BIT_DEPTH)
(
    a_i,
    b_o
);
    input  [INPUT_BITS-1:0] a_i;
    output [INPUT_BITS-2:0] b_o;
    wire    [INPUT_BITS-1:0] b_o_w ; 
    assign b_o_w = ({(INPUT_BITS-1){a_i[INPUT_BITS-1]}} ^ {a_i[INPUT_BITS-2:0]}) + {{(INPUT_BITS-1){1'b0}},a_i[INPUT_BITS-1]};
    assign b_o = b_o_w[INPUT_BITS-2:0];
endmodule

// ---------------------------------------------
//            hadamard_trans_2d() function
// ---------------------------------------------
module hadamard_trans_2d 
#(parameter DIFF_BITS = `BIT_DEPTH+1)
(
        clk_i,
        rst_n_i,        
        valid_i,
        diff0_i, diff1_i, diff2_i, diff3_i,        
        htvalid_o,
        ht0_o,ht1_o,ht2_o,ht3_o
);
input clk_i;
input rst_n_i;    
input                 valid_i;
input [DIFF_BITS-1:0] diff0_i, diff1_i, diff2_i, diff3_i;    
output                   htvalid_o;
output signed [DIFF_BITS+4-1:0] ht0_o,ht1_o,ht2_o,ht3_o;

wire   signed [DIFF_BITS+2-1:0] ht_o0,ht_o1,ht_o2,ht_o3;
wire                     ht_1d_row_valid;

hadamard_trans_1d #(.INPUT_BITS(DIFF_BITS)) ht_1d_row(
    .valid_i    ( valid_i         ),
    .a_i        ( diff0_i         ),
    .b_i        ( diff1_i         ),
    .c_i        ( diff2_i         ),
    .d_i        ( diff3_i         ),
    
    .valid_o    ( ht_1d_row_valid ),
    .A_o        ( ht_o0           ),
    .B_o        ( ht_o1           ),
    .C_o        ( ht_o2           ),
    .D_o        ( ht_o3           )
);

reg [DIFF_BITS+2-1:0] tp00,tp01,tp02,tp03;
reg [DIFF_BITS+2-1:0] tp10,tp11,tp12,tp13;
reg [DIFF_BITS+2-1:0] tp20,tp21,tp22,tp23;
reg [DIFF_BITS+2-1:0] tp30,tp31,tp32,tp33;

reg [1:0] write_cn,read_cn;
reg       read_available;
reg       lastmode;

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) 
    write_cn <= 0;
  else begin
    if(ht_1d_row_valid) begin
      if(write_cn == 2'd3)
        write_cn <= 0;
      else
        write_cn <= write_cn + 2'd1;
    end
    else
      write_cn <= write_cn;
  end
end

// read counter
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) 
    read_cn <= 0;
  else begin
    if(read_available) begin
      if(read_cn == 2'd3)
        read_cn <= 0;
      else
        read_cn <= read_cn + 2'd1;
    end
    else
      read_cn <= read_cn;
  end
end


reg change_flag;
always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    change_flag    <= 0;
  end
  else begin
    if((write_cn == 2'd3) && ht_1d_row_valid)
      change_flag    <= ~change_flag;
    else
      change_flag <= change_flag;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    read_available  <= 0;
  end
  else begin
    if((write_cn == 2'd3) && ht_1d_row_valid)
      read_available <= 1;
    else
      if(read_cn == 2'd3)
        read_available <= 0;
      else
        read_available <= read_available;
  end
end

always @(posedge clk_i or negedge rst_n_i) begin
  if(!rst_n_i) begin
    tp00 <= 0;tp01 <= 0;tp02 <= 0;tp03 <= 0;
    tp10 <= 0;tp11 <= 0;tp12 <= 0;tp13 <= 0;
    tp20 <= 0;tp21 <= 0;tp22 <= 0;tp23 <= 0;
    tp30 <= 0;tp31 <= 0;tp32 <= 0;tp33 <= 0;
  end
  else begin
    if( change_flag == 0 ) begin
      case(write_cn)
        2'd0: begin
          tp00 <= ht_o0; tp01 <= ht_o1;
          tp02 <= ht_o2; tp03 <= ht_o3;
        end
        2'd1: begin
          tp10 <= ht_o0; tp11 <= ht_o1;
          tp12 <= ht_o2; tp13 <= ht_o3;
        end
        2'd2: begin
          tp20 <= ht_o0; tp21 <= ht_o1;
          tp22 <= ht_o2; tp23 <= ht_o3;
        end
        2'd3: begin
          tp30 <= ht_o0; tp31 <= ht_o1;
          tp32 <= ht_o2; tp33 <= ht_o3;
        end
        default: begin
          tp00 <= tp00;tp01 <= tp01;tp02 <= tp02;tp03 <= tp03;
          tp10 <= tp10;tp11 <= tp11;tp12 <= tp12;tp13 <= tp13;
          tp20 <= tp20;tp21 <= tp21;tp22 <= tp22;tp23 <= tp23;
          tp30 <= tp30;tp31 <= tp31;tp32 <= tp32;tp33 <= tp33;
        end
      endcase
    end
    else begin
      case(write_cn)
        2'd0: begin
          tp00 <= ht_o0; tp10 <= ht_o1;
          tp20 <= ht_o2; tp30 <= ht_o3;
        end
        2'd1: begin
          tp01 <= ht_o0; tp11 <= ht_o1;
          tp21 <= ht_o2; tp31 <= ht_o3;
        end
        2'd2: begin
          tp02 <= ht_o0; tp12 <= ht_o1;
          tp22 <= ht_o2; tp32 <= ht_o3;
        end
        2'd3: begin
          tp03 <= ht_o0; tp13 <= ht_o1;
          tp23 <= ht_o2; tp33 <= ht_o3;
        end
        default: begin
          tp00 <= tp00;tp01 <= tp01;tp02 <= tp02;tp03 <= tp03;
          tp10 <= tp10;tp11 <= tp11;tp12 <= tp12;tp13 <= tp13;
          tp20 <= tp20;tp21 <= tp21;tp22 <= tp22;tp23 <= tp23;
          tp30 <= tp30;tp31 <= tp31;tp32 <= tp32;tp33 <= tp33;
        end
      endcase
    end
  end
end


reg [DIFF_BITS+2-1:0] ht_i0, ht_i1, ht_i2, ht_i3;
always @(*) begin
  if(change_flag  == 1'b0) begin
    case(read_cn)
      2'd0: begin
        ht_i0 = tp00; ht_i1 = tp01; ht_i2 = tp02; ht_i3 = tp03;
      end
      2'd1: begin
        ht_i0 = tp10; ht_i1 = tp11; ht_i2 = tp12; ht_i3 = tp13;
      end
      2'd2: begin
        ht_i0 = tp20; ht_i1 = tp21; ht_i2 = tp22; ht_i3 = tp23;
      end
      2'd3: begin
        ht_i0 = tp30; ht_i1 = tp31; ht_i2 = tp32; ht_i3 = tp33;
      end
      default: begin
        ht_i0 = ht_i0; ht_i1 = ht_i1; ht_i2 = ht_i2; ht_i3 = ht_i3;
      end
    endcase
  end
  else begin
     case(read_cn) 
      2'd0: begin
        ht_i0 = tp00; ht_i1 = tp10; ht_i2 = tp20; ht_i3 = tp30;
      end
      2'd1: begin
        ht_i0 = tp01; ht_i1 = tp11; ht_i2 = tp21; ht_i3 = tp31;
      end
      2'd2: begin
        ht_i0 = tp02; ht_i1 = tp12; ht_i2 = tp22; ht_i3 = tp32;
      end
      2'd3: begin
        ht_i0 = tp03; ht_i1 = tp13; ht_i2 = tp23; ht_i3 = tp33;
      end
      default: begin
        ht_i0 = ht_i0; ht_i1 = ht_i1; ht_i2 = ht_i2; ht_i3 = ht_i3;
      end
    endcase
  end
end

hadamard_trans_1d #(.INPUT_BITS(DIFF_BITS+2)) ht_1d_col(
    .valid_i     ( read_available ),
    .a_i         ( ht_i0 ),
    .b_i         ( ht_i1 ),
    .c_i         ( ht_i2 ),
    .d_i         ( ht_i3 ),
    
    .valid_o     ( htvalid_o ),
    .A_o         ( ht0_o ),
    .B_o         ( ht1_o ),
    .C_o         ( ht2_o ),
    .D_o         ( ht3_o )
);
endmodule

// ---------------------------------------------
//            hadamard_trans_1d() function
// ---------------------------------------------
module hadamard_trans_1d
#(parameter INPUT_BITS=`BIT_DEPTH+1)
(
        valid_i,
        a_i,b_i,c_i,d_i,
        
        valid_o,
        A_o,B_o,C_o,D_o
);
input valid_i;
input signed [INPUT_BITS-1:0] a_i;
input signed [INPUT_BITS-1:0] b_i;
input signed [INPUT_BITS-1:0] c_i;
input signed [INPUT_BITS-1:0] d_i;

output                         valid_o;
output signed [INPUT_BITS+1:0] A_o;
output signed [INPUT_BITS+1:0] B_o;
output signed [INPUT_BITS+1:0] C_o;
output signed [INPUT_BITS+1:0] D_o;

wire signed [INPUT_BITS:0] aplusb;
wire signed [INPUT_BITS:0] aminusb;
wire signed [INPUT_BITS:0] cplusd;
wire signed [INPUT_BITS:0] cminusd;

wire signed [INPUT_BITS-1:0] a;
wire signed [INPUT_BITS-1:0] b;
wire signed [INPUT_BITS-1:0] c;
wire signed [INPUT_BITS-1:0] d;


assign a = a_i;
assign b = b_i;
assign c = c_i;
assign d = d_i;

assign valid_o = valid_i;

assign aplusb  = {a[INPUT_BITS-1],a} + {b[INPUT_BITS-1],b};
assign aminusb = {a[INPUT_BITS-1],a} - {b[INPUT_BITS-1],b};
assign cplusd  = {c[INPUT_BITS-1],c} + {d[INPUT_BITS-1],d};
assign cminusd = {c[INPUT_BITS-1],c} - {d[INPUT_BITS-1],d};


wire signed [INPUT_BITS+1:0] aPbPcPd;
wire signed [INPUT_BITS+1:0] aMbPcMd;
wire signed [INPUT_BITS+1:0] aPbMcPd;
wire signed [INPUT_BITS+1:0] aMbMcMd;


assign aPbPcPd = {aplusb[INPUT_BITS],aplusb}   + {cplusd[INPUT_BITS],cplusd};
assign aMbPcMd = {aminusb[INPUT_BITS],aminusb} + {cminusd[INPUT_BITS],cminusd};
assign aPbMcPd = {aplusb[INPUT_BITS],aplusb}   - {cplusd[INPUT_BITS],cplusd};
assign aMbMcMd = {aminusb[INPUT_BITS],aminusb} - {cminusd[INPUT_BITS],cminusd};

assign A_o = aPbPcPd;
assign B_o = aMbPcMd;
assign C_o = aPbMcPd;
assign D_o = aMbMcMd;

endmodule
