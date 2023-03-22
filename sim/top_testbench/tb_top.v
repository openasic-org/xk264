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
// Filename       : tb_top.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : test bench of encoder
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

`define FRAMEWIDTH 416
`define FRAMEHEIGHT 240
`define GOP_LENGTH 5
`define FRAME_TOTAL 100
`define INIT_QP 27
`define MB_X_TOTAL ((`FRAMEWIDTH + 15) / 16)
`define MB_Y_TOTAL ((`FRAMEHEIGHT + 15) / 16)

`define AUTO_CHECK
//`define DUMP_BS
//`define DUMP_FSDB
//`define DUMP_CUR_MB
//`define DUMP_IME
//`define DUMP_FME
//`define DUMP_MC
//`define DUMP_INTRA
//`define DUMP_TQ
//`define DUMP_CAVLC
//`define DUMP_DB

module tb_top;
// ********************************************
//
//    Parameter DECLARATION
//
// ********************************************
parameter 	DUMP_FILE  = "tb_top.fsdb";
parameter   YUV_FILE   = "./tv/cur_mb_p4.dat";
parameter   CHECK_FILE = "./tv/bs_check.dat";

// ********************************************
//
//    IO DECLARATION
//
// ********************************************
reg 		 					clk, rst_n;
// CMD IN IF
reg								sys_start;      
wire							sys_done;		
reg								sys_intra_flag; 
reg [5:0]						sys_qp;         
reg 							sys_mode;       
reg [`PIC_W_MB_LEN-1:0]   		sys_x_total;    
reg [`PIC_H_MB_LEN-1:0]   		sys_y_total;	
wire							enc_ld_start;
wire [`PIC_W_MB_LEN-1:0]		enc_ld_x;
wire [`PIC_H_MB_LEN-1:0]  		enc_ld_y;
// FIFO IN IF
reg          					rvalid_i;
wire         					rinc_o;
reg  [63:0]  					rdata_i;
// FIFO OUT IF
reg          					wfull_i;
wire         					wvalid_o;
wire [7:0]   					wdata_o;  
// EXT IN/OUT IF
wire                          	ext_start;
reg                          	ext_done ;
wire [2:0]                    	ext_mode;
wire [7:0]						ext_mb_x;  
wire [7:0]						ext_mb_y;
reg          					ext_ren;
reg	        					ext_wen;
reg [3:0]    					ext_addr;     
reg  [127:0] 					ext_data_i;
wire [127:0]                  	ext_data_o;

// ********************************************
//
//    Register DECLARATION
//
// ********************************************
reg  [7:0]   					frame_num;
		 
// ********************************************
//
//    DUT  DECLARATION
//
// ********************************************
//-------------------------------------------------------
// 				DUT                          
//-------------------------------------------------------
top u_top     (
				.clk      			( clk      			),
				.rst_n    			( rst_n    			),
				
				.sys_start			( sys_start		    ),      
				.sys_done			( sys_done		    ),		
				.sys_intra_flag		( sys_intra_flag	), 
				.sys_qp				( sys_qp			),         
				.sys_mode			( sys_mode		    ),       
				.sys_x_total		( sys_x_total	    ),    
				.sys_y_total		( sys_y_total	    ),	
				
				.enc_ld_start		( enc_ld_start		),			
				.enc_ld_x           ( enc_ld_x    		),	
				.enc_ld_y           ( enc_ld_y          ),
				
				.rdata_i  			( rdata_i  			),
				.rvalid_i 			( rvalid_i 			),
				.rinc_o   			( rinc_o   			),
				.wdata_o  			( wdata_o  			),
				.wfull_i  			( wfull_i  			),
				.winc_o	  			( winc_o	 		),
				
				.ext_mb_x_o 		( ext_mb_x 			),         
				.ext_mb_y_o 		( ext_mb_y 			), 
				.ext_start_o		( ext_start			),        
				.ext_done_i 		( ext_done 			),        
				.ext_mode_o 		( ext_mode 			),   
				.ext_wen_i			( ext_wen			),	
				.ext_ren_i		    ( ext_ren           ),
				.ext_addr_i         ( ext_addr          ),
				.ext_data_i         ( ext_data_i        ),
				.ext_data_o         ( ext_data_o        )
);

//-------------------------------------------------------
// 				pixel ram input
//-------------------------------------------------------
reg [31:0]	 					addr_r, cnt;
reg [31:0]   					pixel_ram[1<<25:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	rdata_i  <= 'b0;
	rvalid_i <= 1'b0;
	addr_r   <= 'b0;
    end 
    else if (rinc_o && cnt!='d48) begin
	rdata_i  <= {pixel_ram[2*addr_r+0], pixel_ram[2*addr_r+1]};
	rvalid_i <= 1'b1;
	addr_r   <= addr_r+1;
    end
    else begin
	rdata_i  <= 'b0;
	rvalid_i <= 1'b0;
	addr_r   <= addr_r;
    end  
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
	cnt  <= 'b0;
    end 
    else if (rinc_o) begin
	cnt  <= cnt+1;
    end
    else begin
	cnt  <= 'b0;
    end
end

//-------------------------------------------------------
// 				Ext MEM for P Frame                          
//-------------------------------------------------------  
reg [63:0] ref_mem[1<<25:0];
reg [31:0] ref_mem_addr;

always @(posedge clk) begin
	if (ext_start) begin
		case (ext_mode)
			3'b000: load_db_y();
			3'b010: load_db_uv();
			3'b001: load_y();
			3'b011: load_uv();
			3'b100: store_db_y();
			3'b110: store_db_uv();
			3'b101: store_y();
			3'b111: store_uv();
		endcase
	end
end

initial begin 
	ext_done   		= 'b0;
	ext_wen    		= 'b0;
	ext_ren    		= 'b0;
	ext_addr   		= 'b0;
	ext_data_i 		= 'b0;
	ref_mem_addr 	= 'b0;
end

task load_db_y;
reg[4:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'hc; i_4x4<=4'hf; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b0, ext_mb_y, ext_mb_x, i_4x4[3:0], 1'b0};
			ext_wen      = 1'b1;
			ext_data_i   = {ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]};
			#10;
		end
		
		ext_wen    = 'b0;
		ext_data_i = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task load_db_uv;
reg[3:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h4; i_4x4<=4'h7; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b1, ext_mb_y, ext_mb_x, i_4x4, 1'b0};
			ext_wen      = 1'b1;
			ext_data_i   = {ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]};
			#10;
		end
		
		ext_wen    = 'b0;
		ext_data_i = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task load_y;
reg[4:0] i_4x4;
reg[31:0] a0, a1, a2, a3, b0, b1, b2, b3;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h0; i_4x4<4'hf; i_4x4=i_4x4+2) begin
			ref_mem_addr = {~frame_num[0], 1'b0, ext_mb_y, ext_mb_x, i_4x4[3:0], 1'b0};
			ext_wen      = 1'b1;
			{a1, a0}     = ref_mem[ref_mem_addr+2'd0];
			{a3, a2}     = ref_mem[ref_mem_addr+2'd1];
			{b1, b0}     = ref_mem[ref_mem_addr+2'd2];
			{b3, b2}     = ref_mem[ref_mem_addr+2'd3];
			ext_data_i   = {b0, a0};
			#10;
			ext_data_i   = {b1, a1};
			#10;
			ext_data_i   = {b2, a2};
			#10;
			ext_data_i   = {b3, a3};
			#10;
		end
		
		ext_wen    = 'b0;
		ext_data_i = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task load_uv;
reg[3:0] i_4x4;
reg[31:0] a0, a1, a2, a3, b0, b1, b2, b3;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h0; i_4x4<4'h7; i_4x4=i_4x4+2) begin
			ref_mem_addr = {~frame_num[0], 1'b1, ext_mb_y, ext_mb_x, i_4x4, 1'b0};
			ext_wen      = 1'b1;
			{a1, a0}     = ref_mem[ref_mem_addr+2'd0];
			{a3, a2}     = ref_mem[ref_mem_addr+2'd1];
			{b1, b0}     = ref_mem[ref_mem_addr+2'd2];
			{b3, b2}     = ref_mem[ref_mem_addr+2'd3];
			ext_data_i   = {b0, a0};
			#10;
			ext_data_i   = {b1, a1};
			#10;
			ext_data_i   = {b2, a2};
			#10;
			ext_data_i   = {b3, a3};
			#10;
		end
		
		ext_wen    = 'b0;
		ext_data_i = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task store_db_y;
reg[4:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'hc; i_4x4<=4'hf; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b0, ext_mb_y, ext_mb_x, i_4x4[3:0], 1'b0};
			ext_addr	 = i_4x4;
			ext_ren      = 1'b1;
			#10;
			{ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]}=ext_data_o;
		end
		
		ext_addr   = 'b0;
		ext_ren    = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task store_db_uv;
reg[3:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h4; i_4x4<=4'h7; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b1, ext_mb_y, ext_mb_x, i_4x4, 1'b0};
			ext_addr	 = i_4x4;
			ext_ren      = 1'b1;
			#10;
			{ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]}=ext_data_o;
		end
		
		ext_addr   = 'b0;
		ext_ren    = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task store_y;
reg[4:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h0; i_4x4<=4'hf; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b0, ext_mb_y, ext_mb_x, i_4x4[3:0], 1'b0};
			ext_addr	 = i_4x4;
			ext_ren      = 1'b1;
			#10;
			{ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]}=ext_data_o;
		end
		
		ext_addr   = 'b0;
		ext_ren    = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

task store_uv;
reg[3:0] i_4x4;
	begin    
		ext_done   = 'b0;
		ext_wen    = 'b0;
		ext_ren    = 'b0;
		ext_addr   = 'b0;
		ext_data_i = 'b0;
		
		#5;
		
		for (i_4x4=4'h0; i_4x4<=4'h7; i_4x4=i_4x4+1) begin
			ref_mem_addr = {frame_num[0], 1'b1, ext_mb_y, ext_mb_x, i_4x4, 1'b0};
			ext_addr	 = i_4x4;
			ext_ren      = 1'b1;
			#10;
			{ref_mem[ref_mem_addr+1'b1], ref_mem[ref_mem_addr]}=ext_data_o;
		end
		
		ext_addr   = 'b0;
		ext_ren    = 'b0;
		 
		#10  ext_done = 1'b1;
	#10  ext_done = 1'b0;
	#10;                                                               
	end
endtask

/*
parameter						IDLE = 1'b0,
								RUN  = 1'b1;
wire							ref_sel; // ref frame bank sel for load/store
reg [4:0]						ref_cnt, ref_cnt_r; // load/store count for each 4x1 pixel	
							
reg [63:0]						ref_mem[1<<25:0];
wire							ref_mem_cen;
reg                             ref_mem_wen;
wire [31:0]						ref_mem_addr;    
reg [63:0]						ref_mem_rdata;
reg [63:0]						ref_mem_wdata;
reg [31:0]						reg_4x4_a_0, reg_4x4_a_1, reg_4x4_a_2, reg_4x4_a_3,
								reg_4x4_b_0, reg_4x4_b_1, reg_4x4_b_2, reg_4x4_b_3,
								reg_4x4_c_0, reg_4x4_c_1, reg_4x4_c_2, reg_4x4_c_3,
								reg_4x4_d_0, reg_4x4_d_1, reg_4x4_d_2, reg_4x4_d_3;

reg								ext_curr_state;
reg								ext_next_state;

//------------------- ext FSM -------------------//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ext_curr_state <= IDLE;
		ref_cnt_r <= 'b0;
	end
	else begin 
		ext_curr_state <= ext_next_state;
		ref_cnt_r <= ref_cnt;
	end
end

always @(*) begin
	case (ext_curr_state)
		IDLE: begin 
				if (ext_start) 
					ext_next_state = RUN; 
				else
					ext_next_state = IDLE;
			  end
		RUN : begin 
				if ((ext_mode[1]==1'b0 && ref_cnt==6'h1f) || 
					(ext_mode[1]==1'b1 && ref_cnt==6'hf)) 
					ext_next_state = IDLE;
				else
					ext_next_state = RUN; 
			  end
	endcase
end

//------------------- ext MEM IF -------------------//
// ext mem read/write count (32b mem word wdith)
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		ref_cnt <= 'b0;
	else if (ext_done)
		ref_cnt <= 'b0;
	else if (ext_curr_state==IDLE && ext_next_state == RUN) begin
		if (ext_mode[1:0]==2'b00)
			ref_cnt <= 6'h18;
		else if (ext_mode[1:0]==2'b10)
			ref_cnt <= 6'h8;
		else 
			ref_cnt <= 6'h00;
	end
	else if (ext_curr_state==RUN)
		ref_cnt <= ref_cnt + 1'b1;
end

// ext mem read data
always @(posedge clk) begin
	if (ref_mem_cen && ~ref_mem_wen)
		ref_mem_rdata <= ref_mem[ref_mem_addr];
	else
		ref_mem_rdata <= 'bx; 
end

always @(posedge clk) begin
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b000))
		{reg_4x4_a_1, reg_4x4_a_0} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b001))
		{reg_4x4_a_3, reg_4x4_a_2} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b010))
		{reg_4x4_b_1, reg_4x4_b_0} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b011))
		{reg_4x4_b_3, reg_4x4_b_2} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b100))
		{reg_4x4_c_1, reg_4x4_c_0} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b101))
		{reg_4x4_c_3, reg_4x4_c_2} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b110))
		{reg_4x4_d_1, reg_4x4_d_0} <= ref_mem[ref_mem_addr];
	if (ref_mem_cen && ~ref_mem_wen && (ref_mem_addr[2:0]==3'b111))
		{reg_4x4_d_3, reg_4x4_d_2} <= ref_mem[ref_mem_addr];
end


// ext mem write data
always @(*) begin
	case (ref_cnt_r[0])
		1'b0: ref_mem_wdata = ext_data_o[63:0];
		1'b1: ref_mem_wdata = ext_data_o[127:64];
	endcase
end

always @(posedge clk) begin
	if (ref_mem_cen && ref_mem_wen)
		ref_mem[ref_mem_addr] <= ref_mem_wdata;
end

// ext mem addr, cen, wen
assign ref_sel      = {ext_mode[2], ext_mode[0]} ==2'b01 ? (~frame_num[0]):frame_num[0];
assign ref_mem_addr = {ref_sel, ext_mode[1], ext_mb_y, ext_mb_x, ext_mode[2]?ref_cnt_r:ref_cnt};
assign ref_mem_cen  = ext_mode[2] ? ref_mem_wen : (ext_curr_state==RUN);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)  
		ref_mem_wen  <= 1'b0;
	else if ((ext_curr_state==RUN) && (ext_mode[2]==1'b1))
		ref_mem_wen  <= 1'b1;
	else
		ref_mem_wen  <= 1'b0;
end

//------------------- Arbitor MEM IF -------------------//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		ext_done <= 1'b0;
	else if ((ext_curr_state==IDLE) && ((ext_mode[1]==1'b0 && ref_cnt_r==6'h1f) || 
									    (ext_mode[1]==1'b1 && ref_cnt_r==6'hf)))
		ext_done <= 1'b1; 
	else
		ext_done <= 1'b0;
end

assign ext_ren = (ext_curr_state==RUN) && (ext_mode[2]==1'b1);
	
assign ext_addr = ext_mode[2] ? ref_cnt[4:1] : ref_cnt_r[4:1];	

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		ext_wen <= 1'b0;
	else if ((ext_curr_state==RUN) && (ext_mode[2]==1'b0))
		if (ext_mode[0]==1'b1 && ref_cnt>='h3)
			ext_wen <= 1'b1;
		else if (ext_mode[0]==1'b0 && ref_cnt[0]==1'b1)
			ext_wen <= 1'b1;
		else
			ext_wen <= 1'b0;
	else
		ext_wen <= 1'b0;
end

always @(*) begin
	if (ext_mode[0]==1'b1)
		case (ref_cnt[2:0]) 
			3'b000: ext_data_i = {64'b0, reg_4x4_d_0, reg_4x4_c_0};
			3'b001: ext_data_i = {64'b0, reg_4x4_d_1, reg_4x4_c_1};
			3'b010: ext_data_i = {64'b0, reg_4x4_d_2, reg_4x4_c_2};
			3'b011: ext_data_i = {64'b0, reg_4x4_d_3, reg_4x4_c_3};
			3'b100: ext_data_i = {64'b0, reg_4x4_b_0, reg_4x4_a_0};
			3'b101: ext_data_i = {64'b0, reg_4x4_b_1, reg_4x4_a_1};
			3'b110: ext_data_i = {64'b0, reg_4x4_b_2, reg_4x4_a_2};
		    3'b111: ext_data_i = {64'b0, reg_4x4_b_3, reg_4x4_a_3};
		endcase
	else 
		case (ref_cnt_r[2:0])
			3'b000: ext_data_i = {reg_4x4_a_3, reg_4x4_a_2, reg_4x4_a_1, reg_4x4_a_0};
			3'b001: ext_data_i = {reg_4x4_a_3, reg_4x4_a_2, reg_4x4_a_1, reg_4x4_a_0};
			3'b010: ext_data_i = {reg_4x4_b_3, reg_4x4_b_2, reg_4x4_b_1, reg_4x4_b_0};
			3'b011: ext_data_i = {reg_4x4_b_3, reg_4x4_b_2, reg_4x4_b_1, reg_4x4_b_0};
			3'b100: ext_data_i = {reg_4x4_c_3, reg_4x4_c_2, reg_4x4_c_1, reg_4x4_c_0};
			3'b101: ext_data_i = {reg_4x4_c_3, reg_4x4_c_2, reg_4x4_c_1, reg_4x4_c_0};
			3'b110: ext_data_i = {reg_4x4_d_3, reg_4x4_d_2, reg_4x4_d_1, reg_4x4_d_0};
			3'b111: ext_data_i = {reg_4x4_d_3, reg_4x4_d_2, reg_4x4_d_1, reg_4x4_d_0};
		endcase
end
*/

// ******************************************** 
//                                              
//    TESTbench Logic                           
//                                              
// ******************************************** 
// clk                                          
initial begin                                   
	clk = 1'b0;                                 
	forever #5 clk = ~clk;                     
end                                             

initial begin    
	$readmemh(YUV_FILE, pixel_ram);
	
	$monitor("%d, Frame Number = %d, mb_x_load = %d, mb_y_load = %d \n",
		 $time, frame_num, u_top.mb_x_load, u_top.mb_y_load );
	
	rst_n 	 = 'b0;
	rvalid_i = 'b0;
	rdata_i  = 'b0;
	wfull_i  = 'b0;
	
	sys_start		= 1'b0;     
	sys_intra_flag	= 1'b0;    
	sys_qp			= `INIT_QP;    
	sys_mode		= 1'b0;  // 0:frame mode 1:MB mode    
	sys_x_total	    = `MB_X_TOTAL - 1'd1;    
	sys_y_total	    = `MB_Y_TOTAL - 1'd1;   
	
	frame_num 		= 0;
	
	#10	rst_n	= 1'b1;  
	
	for (frame_num=0; frame_num<`FRAME_TOTAL; frame_num=frame_num+1'b1) begin
		#500;
		if (frame_num%`GOP_LENGTH=='b0)
			start(1); 
		else
			start(0);
		#500;
	end        
	
	$finish;
end

// -------------------------------------------------------
//                   Config Task
// -------------------------------------------------------
task start;
	input intra_flag;
	begin
		if (intra_flag) 
			#100 sys_intra_flag	= 1'b1;
		else 
			#100 sys_intra_flag	= 1'b0; 
	
		     sys_start = 1'b1;        
		#10  sys_start = 1'b0;
	#10  wait(sys_done == 1'b1);                                                               
	end
endtask

// -------------------------------------------------------
//                     DUMP FSDB
// -------------------------------------------------------
`ifdef DUMP_FSDB
initial begin 
	$fsdbDumpfile(DUMP_FILE);
	$fsdbDumpvars;
	$fsdbDumpoff;
	wait(frame_num==0);
	$fsdbDumpon;
end
`endif

// -------------------------------------------------------
//                  DUMP current MB
// -------------------------------------------------------
`ifdef DUMP_CUR_MB
integer f_cmb;
integer cmb_i, cmb_j;
initial begin
	f_cmb = $fopen("./dump/cur_mb.dat ","wb");
end

always @(frame_num)
	$fdisplay(f_cmb, "Frame Number =%3d", frame_num);

always @(posedge clk) begin	
	if (u_top.load_done) begin
		$fwrite(f_cmb, "\nMB_X =%d, MB_Y =%d\n", u_top.mb_x_load, u_top.mb_y_load);
		$fwrite(f_cmb, "==Y==\n");
		for (cmb_i=0; cmb_i<16; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<16; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_y[16*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end
		$fwrite(f_cmb, "==U==\n");
		for (cmb_i=0; cmb_i<8; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<8; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_u[8*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end		
		$fwrite(f_cmb, "==V==\n");
		for (cmb_i=0; cmb_i<8; cmb_i=cmb_i+1) begin
			for (cmb_j=0; cmb_j<8; cmb_j=cmb_j+1) begin
				$fwrite(f_cmb, "%h ", u_top.u_cur_mb.cur_v[8*cmb_i+cmb_j]);
			end
			$fwrite(f_cmb, "\n");
		end		
	end
end
`endif

// -------------------------------------------------------
//                  DUMP bit stream
// -------------------------------------------------------
`ifdef DUMP_BS
integer f_bs;
integer bs_num;
integer wait_cycle;
initial begin
	bs_num = 0;
	f_bs = $fopen("./dump/bs.dat","wb");
end

always @(frame_num)
	$fdisplay(f_bs, "Frame Number =%3d", frame_num);

always @(posedge clk) begin
	if (u_top.winc_o) begin
		bs_num = bs_num + 1;
		$fwrite(f_bs, "%h ", u_top.wdata_o);
		if (!(bs_num%16)) $fdisplay(f_bs, "row = %3d", bs_num>>4);		
		if (u_top.frame_done) begin	
			$fwrite(f_bs, "\n"); 
			bs_num = 0;
		end
	end
end	

// always @(posedge clk) begin
// 	if (u_top.frame_done) begin
// 		wait_cycle <= (u_top.u_bs_buf.bs_cnt_r > u_top.u_bs_buf.bs_cnt_w) ? (u_top.u_bs_buf.bs_cnt_w + 65 - u_top.u_bs_buf.bs_cnt_r) : (u_top.u_bs_buf.bs_cnt_w - u_top.u_bs_buf.bs_cnt_r + 1);
// 	end
// 	else if (u_top.winc_o && wait_cycle) begin
// 		wait_cycle <= wait_cycle - 1;
// 	end
// end

`endif

// -------------------------------------------------------
//                  AUTO CHECK
// -------------------------------------------------------
`ifdef AUTO_CHECK
integer fp_check;
reg [7:0] check_data;

initial begin
	fp_check = $fopen(CHECK_FILE, "r");
end

always @(posedge clk) begin
	if (u_top.winc_o) begin
		$fscanf(fp_check, "%h", check_data);
		if (check_data !== u_top.wdata_o) begin
			 $display("ERROR(MB x:%3d y:%3d): check_data(%h) != bs_data(%h)", u_top.mb_x_ec, u_top.mb_y_ec, check_data, u_top.wdata_o);
			#5000 $finish;
		end
	end	
end

`endif

// -------------------------------------------------------
//                 Include Dump Bench
// -------------------------------------------------------
`include "./bench/ime_dump.v"
`include "./bench/fme_dump.v"
`include "./bench/mc_dump.v"
`include "./bench/intra_dump.v"
`include "./bench/tq_dump.v"
`include "./bench/db_dump.v"
`include "./bench/cavlc_dump.v"

endmodule
