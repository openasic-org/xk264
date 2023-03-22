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
// Filename       : db_top.v
// Author         : shen weiwei
// Created        : 2013-08-23
// Description    : deblocking filter top
//               
// $Id$ 
//------------------------------------------------------------------- 

module db_top( clk, rst, start,
            x, y, QP,
			  
            
            transform_type_C,  
            mb_mode,               
            non_zero_count,
            
            db_mv,//bs
            
			ram_c,//ycbcr
			radd_c,
			ren_c,
			ram_c_former,
			wadd_c,
			wen_c,
			
			ram_t,
			radd_t,
			ren_t,
			
			ram_out,
			wadd_out,
			wen_out,
			
			db_done
			
           );

// ********************************************
//                                             
//    INPUT / OUTPUT DECLARATION               
//                                             
// ********************************************

input clk, rst, start;
input [5:0] QP;
input [7:0] x, y;


input transform_type_C;                             //bs
input mb_mode;

input [15:0] non_zero_count;

input[255:0] db_mv; 

//////new part          
input       [127:0] ram_c;
output reg  [4:0]   radd_c;
output              ren_c;
output      [127:0] ram_c_former;
output reg  [4:0]   wadd_c;
output              wen_c;
      
input       [127:0] ram_t;
output      [2:0]   radd_t;
output              ren_t;
     
output      [127:0] ram_out;
output      [5:0]   wadd_out;
output              wen_out;
      
output      db_done;


// ********************************************
//                                             
//    Wire DECLARATION                         
//                                             
// ********************************************
           
//bs 
wire [2:0] bs_luma;
wire [2:0] bs_chroma_1;
wire [2:0] bs_chroma_2;

wire [27:0] code_T;
wire [8:0]  add_T;
wire        read_en_T;
wire [27:0] code_T_out;
wire [8:0]  add_out_T;
wire        write_en_T;                    

//input reg buf
reg	[255:0]	db_4x4_mv         ;
reg			mbtype_C		  ;
reg			non_zero_count_C1 ;
reg			non_zero_count_C2 ;
reg			non_zero_count_C3 ;
reg			non_zero_count_C4 ;
reg			non_zero_count_C5 ;
reg			non_zero_count_C6 ;
reg			non_zero_count_C7 ;
reg			non_zero_count_C8 ;
reg			non_zero_count_C9 ;
reg			non_zero_count_C10;
reg			non_zero_count_C11;
reg			non_zero_count_C12;
reg			non_zero_count_C13;
reg			non_zero_count_C14;
reg			non_zero_count_C15;
reg			non_zero_count_C16;

wire [19:0]	mv_C1 ;
wire [19:0]	mv_C2 ;
wire [19:0]	mv_C3 ;
wire [19:0]	mv_C4 ;
wire [19:0]	mv_C5 ;
wire [19:0]	mv_C6 ;
wire [19:0]	mv_C7 ;
wire [19:0]	mv_C8 ;
wire [19:0]	mv_C9 ;
wire [19:0]	mv_C10;
wire [19:0]	mv_C11;
wire [19:0]	mv_C12;
wire [19:0]	mv_C13;
wire [19:0]	mv_C14;
wire [19:0]	mv_C15;
wire [19:0]	mv_C16;

// ********************************************
//                                             
//    Sub Modules                              
//                                             
// ********************************************
//--------------- buff input register data -----------------//
always @(posedge clk or negedge rst) begin
	if (!rst) begin
		db_4x4_mv		   <= 256'b0;
		mbtype_C		   <= 1'b0;
		non_zero_count_C1  <= 1'b0;
		non_zero_count_C2  <= 1'b0;
		non_zero_count_C3  <= 1'b0;
		non_zero_count_C4  <= 1'b0;
		non_zero_count_C5  <= 1'b0;
		non_zero_count_C6  <= 1'b0;
		non_zero_count_C7  <= 1'b0;
		non_zero_count_C8  <= 1'b0;
		non_zero_count_C9  <= 1'b0;
		non_zero_count_C10 <= 1'b0;
		non_zero_count_C11 <= 1'b0;
		non_zero_count_C12 <= 1'b0;
		non_zero_count_C13 <= 1'b0;
		non_zero_count_C14 <= 1'b0;
		non_zero_count_C15 <= 1'b0;
		non_zero_count_C16 <= 1'b0;                       		
	end
	else if (start) begin
	    db_4x4_mv          <= db_mv              ;
		mbtype_C		   <= mb_mode		     ;
		non_zero_count_C1  <= non_zero_count[0 ] ;
		non_zero_count_C2  <= non_zero_count[1 ] ;
		non_zero_count_C3  <= non_zero_count[4 ] ;
		non_zero_count_C4  <= non_zero_count[5 ] ;
		non_zero_count_C5  <= non_zero_count[2 ] ;
		non_zero_count_C6  <= non_zero_count[3 ] ;
		non_zero_count_C7  <= non_zero_count[6 ] ;
		non_zero_count_C8  <= non_zero_count[7 ] ;
		non_zero_count_C9  <= non_zero_count[8 ] ;
		non_zero_count_C10 <= non_zero_count[9 ] ;
		non_zero_count_C11 <= non_zero_count[12] ;
		non_zero_count_C12 <= non_zero_count[13] ;
		non_zero_count_C13 <= non_zero_count[10] ;
		non_zero_count_C14 <= non_zero_count[11] ;
		non_zero_count_C15 <= non_zero_count[14] ;
		non_zero_count_C16 <= non_zero_count[15] ;
	end
end
// mv = (mv_y, mv_x)
assign mv_C16  = {{2{db_4x4_mv[15*2*8+15]}}, db_4x4_mv[15*2*8+15 : 15*2*8+8], {2{db_4x4_mv[15*2*8+7]}}, db_4x4_mv[15*2*8+7 : 15*2*8]};
assign mv_C15  = {{2{db_4x4_mv[14*2*8+15]}}, db_4x4_mv[14*2*8+15 : 14*2*8+8], {2{db_4x4_mv[14*2*8+7]}}, db_4x4_mv[14*2*8+7 : 14*2*8]};
assign mv_C12  = {{2{db_4x4_mv[13*2*8+15]}}, db_4x4_mv[13*2*8+15 : 13*2*8+8], {2{db_4x4_mv[13*2*8+7]}}, db_4x4_mv[13*2*8+7 : 13*2*8]};
assign mv_C11  = {{2{db_4x4_mv[12*2*8+15]}}, db_4x4_mv[12*2*8+15 : 12*2*8+8], {2{db_4x4_mv[12*2*8+7]}}, db_4x4_mv[12*2*8+7 : 12*2*8]};
assign mv_C14  = {{2{db_4x4_mv[11*2*8+15]}}, db_4x4_mv[11*2*8+15 : 11*2*8+8], {2{db_4x4_mv[11*2*8+7]}}, db_4x4_mv[11*2*8+7 : 11*2*8]};
assign mv_C13  = {{2{db_4x4_mv[10*2*8+15]}}, db_4x4_mv[10*2*8+15 : 10*2*8+8], {2{db_4x4_mv[10*2*8+7]}}, db_4x4_mv[10*2*8+7 : 10*2*8]};
assign mv_C10  = {{2{db_4x4_mv[ 9*2*8+15]}}, db_4x4_mv[ 9*2*8+15 :  9*2*8+8], {2{db_4x4_mv[ 9*2*8+7]}}, db_4x4_mv[ 9*2*8+7 :  9*2*8]};
assign mv_C9   = {{2{db_4x4_mv[ 8*2*8+15]}}, db_4x4_mv[ 8*2*8+15 :  8*2*8+8], {2{db_4x4_mv[ 8*2*8+7]}}, db_4x4_mv[ 8*2*8+7 :  8*2*8]};
assign mv_C8   = {{2{db_4x4_mv[ 7*2*8+15]}}, db_4x4_mv[ 7*2*8+15 :  7*2*8+8], {2{db_4x4_mv[ 7*2*8+7]}}, db_4x4_mv[ 7*2*8+7 :  7*2*8]};
assign mv_C7   = {{2{db_4x4_mv[ 6*2*8+15]}}, db_4x4_mv[ 6*2*8+15 :  6*2*8+8], {2{db_4x4_mv[ 6*2*8+7]}}, db_4x4_mv[ 6*2*8+7 :  6*2*8]};
assign mv_C4   = {{2{db_4x4_mv[ 5*2*8+15]}}, db_4x4_mv[ 5*2*8+15 :  5*2*8+8], {2{db_4x4_mv[ 5*2*8+7]}}, db_4x4_mv[ 5*2*8+7 :  5*2*8]};
assign mv_C3   = {{2{db_4x4_mv[ 4*2*8+15]}}, db_4x4_mv[ 4*2*8+15 :  4*2*8+8], {2{db_4x4_mv[ 4*2*8+7]}}, db_4x4_mv[ 4*2*8+7 :  4*2*8]};
assign mv_C6   = {{2{db_4x4_mv[ 3*2*8+15]}}, db_4x4_mv[ 3*2*8+15 :  3*2*8+8], {2{db_4x4_mv[ 3*2*8+7]}}, db_4x4_mv[ 3*2*8+7 :  3*2*8]};
assign mv_C5   = {{2{db_4x4_mv[ 2*2*8+15]}}, db_4x4_mv[ 2*2*8+15 :  2*2*8+8], {2{db_4x4_mv[ 2*2*8+7]}}, db_4x4_mv[ 2*2*8+7 :  2*2*8]};
assign mv_C2   = {{2{db_4x4_mv[ 1*2*8+15]}}, db_4x4_mv[ 1*2*8+15 :  1*2*8+8], {2{db_4x4_mv[ 1*2*8+7]}}, db_4x4_mv[ 1*2*8+7 :  1*2*8]};
assign mv_C1   = {{2{db_4x4_mv[ 0*2*8+15]}}, db_4x4_mv[ 0*2*8+15 :  0*2*8+8], {2{db_4x4_mv[ 0*2*8+7]}}, db_4x4_mv[ 0*2*8+7 :  0*2*8]};




/////////////////////////////////////////////////////////////////////
wire [1:0] state;
wire [2:0] count_bs;
wire [5:0] count_y;
wire [5:0] count_cbcr;

wire [5:0] qp_1;
wire [5:0] qp_2;

   bs bs1 ( .clk(clk), 
			.rst(rst), 
			.x(x), .y(y), 
			.qp_c(QP),
			.state(state),
			.count_bs(count_bs),
			.count_y(count_y),
			.count_cbcr(count_cbcr),
			.code_T(code_T),
            .transform_type_C(transform_type_C),  .mbtype_C(mbtype_C),   
            
            .non_zero_count_C1 (non_zero_count_C1 ),  .non_zero_count_C2 (non_zero_count_C2 ),  .non_zero_count_C3 (non_zero_count_C3 ),  .non_zero_count_C4 (non_zero_count_C4 ),
            .non_zero_count_C5 (non_zero_count_C5 ),  .non_zero_count_C6 (non_zero_count_C6 ),  .non_zero_count_C7 (non_zero_count_C7 ),  .non_zero_count_C8 (non_zero_count_C8 ), 
            .non_zero_count_C9 (non_zero_count_C9 ),  .non_zero_count_C10(non_zero_count_C10),  .non_zero_count_C11(non_zero_count_C11),  .non_zero_count_C12(non_zero_count_C12),
            .non_zero_count_C13(non_zero_count_C13),  .non_zero_count_C14(non_zero_count_C14),  .non_zero_count_C15(non_zero_count_C15),  .non_zero_count_C16(non_zero_count_C16),
            
            .mv_C1 (mv_C1 ),  .mv_C2 (mv_C2 ),  .mv_C3 (mv_C3 ), .mv_C4 (mv_C4 ), 
            .mv_C5 (mv_C5 ),  .mv_C6 (mv_C6 ),  .mv_C7 (mv_C7 ), .mv_C8 (mv_C8 ),
            .mv_C9 (mv_C9 ),  .mv_C10(mv_C10),  .mv_C11(mv_C11), .mv_C12(mv_C12),
            .mv_C13(mv_C13),  .mv_C14(mv_C14),  .mv_C15(mv_C15), .mv_C16(mv_C16),   

            .code_T_out(code_T_out), .add_out_T(add_out_T), .write_en_T(write_en_T),
            .add_T(add_T), .read_en_T(read_en_T),
           
            .bs_luma(bs_luma),
            .bs_chroma_1(bs_chroma_1),
			.bs_chroma_2(bs_chroma_2),
			
			.qp_1(qp_1),
			.qp_2(qp_2)
            
            );


    wire [8:0] ram_addr;
    assign ram_addr = write_en_T ? add_out_T : add_T;
	
	wire chip_en_code = ((write_en_T==1'b1)||(read_en_T==1'b1)) ? 1'b0 : 1'b1;
    
    //db_ram_22x44 ram_code ( 
	db_ram_1p_28x480 ram_code (                              ///1920x1088
							 .clk   (clk),
							 .cen_i (chip_en_code),
							 .oen_i (1'b0),
							 .wen_i (~write_en_T),
							 .addr_i(ram_addr),
	                         .data_i(code_T_out),
	                         .data_o(code_T)	
	
    );    
                 


wire [127:0] ram_l;				  
wire [2:0] radd_l;			  
wire ren_l;			  
wire [127:0] ram_l_former;			  
wire [2:0] wadd_l;			  
wire wen_l;	


wire [2:0] left_addr;
assign left_addr = wen_l ? wadd_l : radd_l;
	
wire chip_en_l = ((ren_l==1'b1)||(wen_l==1'b1)) ? 1'b0 : 1'b1;

    db_ram_1p_128x8 ram_left(                             ///4 for luma, 4 for chroma
							 .clk   (clk),
							 .cen_i (chip_en_l),
							 .oen_i (1'b0),
							 .wen_i (~wen_l),
							 .addr_i(left_addr),
	                         .data_i(ram_l_former),
	                         .data_o(ram_l)	
	
	);    



wire select;

wire [7:0] p3_0_i, p2_0_i, p1_0_i, p0_0_i, q0_0_i, q1_0_i, q2_0_i, q3_0_i;
wire [7:0] p3_1_i, p2_1_i, p1_1_i, p0_1_i, q0_1_i, q1_1_i, q2_1_i, q3_1_i;
wire [7:0] p3_2_i, p2_2_i, p1_2_i, p0_2_i, q0_2_i, q1_2_i, q2_2_i, q3_2_i;
wire [7:0] p3_3_i, p2_3_i, p1_3_i, p0_3_i, q0_3_i, q1_3_i, q2_3_i, q3_3_i;
                                                                        
wire [7:0] p3_0_o, p2_0_o, p1_0_o, p0_0_o, q0_0_o, q1_0_o, q2_0_o, q3_0_o;
wire [7:0] p3_1_o, p2_1_o, p1_1_o, p0_1_o, q0_1_o, q1_1_o, q2_1_o, q3_1_o;
wire [7:0] p3_2_o, p2_2_o, p1_2_o, p0_2_o, q0_2_o, q1_2_o, q2_2_o, q3_2_o;
wire [7:0] p3_3_o, p2_3_o, p1_3_o, p0_3_o, q0_3_o, q1_3_o, q2_3_o, q3_3_o;

			  
wire [4:0] read_addr;					  
always@(*)begin
	case(read_addr)
		5'd0 : radd_c = 5'd0;
	    5'd1 : radd_c = 5'd1;
	    5'd2 : radd_c = 5'd4;
	    5'd3 : radd_c = 5'd5;
	    5'd4 : radd_c = 5'd2;
	    5'd5 : radd_c = 5'd3;
	    5'd6 : radd_c = 5'd6;
	    5'd7 : radd_c = 5'd7;
	    5'd8 : radd_c = 5'd8;
	    5'd9 : radd_c = 5'd9;
	    5'd10: radd_c = 5'd12;
	    5'd11: radd_c = 5'd13;
	    5'd12: radd_c = 5'd10;
	    5'd13: radd_c = 5'd11;
	    5'd14: radd_c = 5'd14;
	    5'd15: radd_c = 5'd15;
		default: radd_c = read_addr;	
	endcase
end

wire [4:0] write_addr;	
always@(*)begin
	case(write_addr)
		5'd0 : wadd_c = 5'd0;
	    5'd1 : wadd_c = 5'd1;
	    5'd2 : wadd_c = 5'd4;
	    5'd3 : wadd_c = 5'd5;
	    5'd4 : wadd_c = 5'd2;
	    5'd5 : wadd_c = 5'd3;
	    5'd6 : wadd_c = 5'd6;
	    5'd7 : wadd_c = 5'd7;
	    5'd8 : wadd_c = 5'd8;
	    5'd9 : wadd_c = 5'd9;
	    5'd10: wadd_c = 5'd12;
	    5'd11: wadd_c = 5'd13;
	    5'd12: wadd_c = 5'd10;
	    5'd13: wadd_c = 5'd11;
	    5'd14: wadd_c = 5'd14;
	    5'd15: wadd_c = 5'd15;
		default: wadd_c = write_addr;	
	endcase
end


wire [127:0] ram_c_order = {ram_c[7:0],ram_c[15:8],ram_c[23:16],ram_c[31:24],ram_c[39:32],ram_c[47:40],ram_c[55:48],ram_c[63:56],ram_c[71:64],ram_c[79:72],ram_c[87:80],ram_c[95:88],ram_c[103:96],ram_c[111:104],ram_c[119:112],ram_c[127:120]};
wire [127:0] ram_t_order = {ram_t[7:0],ram_t[15:8],ram_t[23:16],ram_t[31:24],ram_t[39:32],ram_t[47:40],ram_t[55:48],ram_t[63:56],ram_t[71:64],ram_t[79:72],ram_t[87:80],ram_t[95:88],ram_t[103:96],ram_t[111:104],ram_t[119:112],ram_t[127:120]};

wire [127:0] ram_1;
wire [127:0] ram_2;

wire [127:0] ram_c_former ={ram_1[7:0],ram_1[15:8],ram_1[23:16],ram_1[31:24],ram_1[39:32],ram_1[47:40],ram_1[55:48],ram_1[63:56],ram_1[71:64],ram_1[79:72],ram_1[87:80],ram_1[95:88],ram_1[103:96],ram_1[111:104],ram_1[119:112],ram_1[127:120]};
wire [127:0] ram_out      ={ram_2[7:0],ram_2[15:8],ram_2[23:16],ram_2[31:24],ram_2[39:32],ram_2[47:40],ram_2[55:48],ram_2[63:56],ram_2[71:64],ram_2[79:72],ram_2[87:80],ram_2[95:88],ram_2[103:96],ram_2[111:104],ram_2[119:112],ram_2[127:120]};
 
	db_control contol( .clk(clk),
							  .rst(rst),
							  
							  .start(start),
							  .x(x),
							  .y(y),
							  
							  .ram_c(ram_c_order),
							  .radd_c(read_addr),
							  .ren_c(ren_c),
							  .ram_c_former(ram_1),
							  .wadd_c(write_addr),
							  .wen_c(wen_c),
							  
							  .ram_l(ram_l),
							  .radd_l(radd_l),
							  .ren_l(ren_l),
							  .ram_l_former(ram_l_former),
							  .wadd_l(wadd_l),
							  .wen_l(wen_l),
							  
							  .ram_t(ram_t_order),
							  .radd_t(radd_t),
							  .ren_t(ren_t),							  
							  
							  .ram_out(ram_2),
							  .wadd_out(wadd_out),
							  .wen_out(wen_out),
							  
							  .p3_0_i(p3_0_i), .p2_0_i(p2_0_i), .p1_0_i(p1_0_i), .p0_0_i(p0_0_i), .q0_0_i(q0_0_i), .q1_0_i(q1_0_i), .q2_0_i(q2_0_i), .q3_0_i(q3_0_i),
							  .p3_1_i(p3_1_i), .p2_1_i(p2_1_i), .p1_1_i(p1_1_i), .p0_1_i(p0_1_i), .q0_1_i(q0_1_i), .q1_1_i(q1_1_i), .q2_1_i(q2_1_i), .q3_1_i(q3_1_i),
							  .p3_2_i(p3_2_i), .p2_2_i(p2_2_i), .p1_2_i(p1_2_i), .p0_2_i(p0_2_i), .q0_2_i(q0_2_i), .q1_2_i(q1_2_i), .q2_2_i(q2_2_i), .q3_2_i(q3_2_i),
							  .p3_3_i(p3_3_i), .p2_3_i(p2_3_i), .p1_3_i(p1_3_i), .p0_3_i(p0_3_i), .q0_3_i(q0_3_i), .q1_3_i(q1_3_i), .q2_3_i(q2_3_i), .q3_3_i(q3_3_i),
							                                                                                                                                        
							  .p3_0_o(p3_0_o), .p2_0_o(p2_0_o), .p1_0_o(p1_0_o), .p0_0_o(p0_0_o), .q0_0_o(q0_0_o), .q1_0_o(q1_0_o), .q2_0_o(q2_0_o), .q3_0_o(q3_0_o),
							  .p3_1_o(p3_1_o), .p2_1_o(p2_1_o), .p1_1_o(p1_1_o), .p0_1_o(p0_1_o), .q0_1_o(q0_1_o), .q1_1_o(q1_1_o), .q2_1_o(q2_1_o), .q3_1_o(q3_1_o),
							  .p3_2_o(p3_2_o), .p2_2_o(p2_2_o), .p1_2_o(p1_2_o), .p0_2_o(p0_2_o), .q0_2_o(q0_2_o), .q1_2_o(q1_2_o), .q2_2_o(q2_2_o), .q3_2_o(q3_2_o),
							  .p3_3_o(p3_3_o), .p2_3_o(p2_3_o), .p1_3_o(p1_3_o), .p0_3_o(p0_3_o), .q0_3_o(q0_3_o), .q1_3_o(q1_3_o), .q2_3_o(q2_3_o), .q3_3_o(q3_3_o),		

							  .select(select),
							  
							  .state(state),
							  .count_bs(count_bs),
							  .count_y(count_y),
							  .count_cbcr(count_cbcr),
							  
							  .db_done(db_done)
							  
							  );




	db_filter filter( .clk(clk),
					    .rst(rst), 
					    
						.bs_luma(bs_luma),
						.bs_chroma_1(bs_chroma_1),
						.bs_chroma_2(bs_chroma_2),
						
                        .qp1_i(qp_1), .qp2_i(qp_2),
					    .select(select),
					    
					    .p3_1_i(p3_0_o), .p2_1_i(p2_0_o), .p1_1_i(p1_0_o), .p0_1_i(p0_0_o), .q0_1_i(q0_0_o), .q1_1_i(q1_0_o), .q2_1_i(q2_0_o), .q3_1_i(q3_0_o),
                        .p3_2_i(p3_1_o), .p2_2_i(p2_1_o), .p1_2_i(p1_1_o), .p0_2_i(p0_1_o), .q0_2_i(q0_1_o), .q1_2_i(q1_1_o), .q2_2_i(q2_1_o), .q3_2_i(q3_1_o),
                        .p3_3_i(p3_2_o), .p2_3_i(p2_2_o), .p1_3_i(p1_2_o), .p0_3_i(p0_2_o), .q0_3_i(q0_2_o), .q1_3_i(q1_2_o), .q2_3_i(q2_2_o), .q3_3_i(q3_2_o),
                        .p3_4_i(p3_3_o), .p2_4_i(p2_3_o), .p1_4_i(p1_3_o), .p0_4_i(p0_3_o), .q0_4_i(q0_3_o), .q1_4_i(q1_3_o), .q2_4_i(q2_3_o), .q3_4_i(q3_3_o),
					                                                                                          
					    .p3_1_o(p3_0_i), .p2_1_o(p2_0_i), .p1_1_o(p1_0_i), .p0_1_o(p0_0_i), .q0_1_o(q0_0_i), .q1_1_o(q1_0_i), .q2_1_o(q2_0_i), .q3_1_o(q3_0_i),
                        .p3_2_o(p3_1_i), .p2_2_o(p2_1_i), .p1_2_o(p1_1_i), .p0_2_o(p0_1_i), .q0_2_o(q0_1_i), .q1_2_o(q1_1_i), .q2_2_o(q2_1_i), .q3_2_o(q3_1_i),
                        .p3_3_o(p3_2_i), .p2_3_o(p2_2_i), .p1_3_o(p1_2_i), .p0_3_o(p0_2_i), .q0_3_o(q0_2_i), .q1_3_o(q1_2_i), .q2_3_o(q2_2_i), .q3_3_o(q3_2_i),
                        .p3_4_o(p3_3_i), .p2_4_o(p2_3_i), .p1_4_o(p1_3_i), .p0_4_o(p0_3_i), .q0_4_o(q0_3_i), .q1_4_o(q1_3_i), .q2_4_o(q2_3_i), .q3_4_o(q3_3_i)
                    
                        );							  
					  
	  


endmodule
