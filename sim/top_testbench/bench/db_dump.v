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
// Filename       : db_dump.v
// Author         : fanyibo
// Created        : 2012-04-25
// Description    : dump intra in/out data
//               
// $Id$ 
//------------------------------------------------------------------- 
`ifdef DUMP_DB

integer fp_db ;
integer fp_db_in;   
integer fp_db_out;
integer i_db;

initial begin
    fp_db	  = $fopen("./dump/db.dat","wb");
    fp_db_in  = $fopen("./dump/db_input.dat","wb");
    fp_db_out = $fopen("./dump/db_output.dat","wb");
  end

//--------------------------------------------------------------------------
//	dump db variables                                      
//--------------------------------------------------------------------------
integer     db_ref_cnt;
reg [63:0]	db_ref_r[0:15];

always @(posedge clk) begin
	if (tb_top.u_top.u_db_top.start) begin
		#5;
		$fwrite(fp_db,"\n===== Frame: %d  MB x: %d  y: %d =====\n", tb_top.frame_num,          
																	tb_top.u_top.u_db_top.x, 
																	tb_top.u_top.u_db_top.y);
		// from top
		$fdisplay(fp_db,"$intra_flag        : %h", tb_top.u_top.intra_flag       		);
		$fdisplay(fp_db,"$qp                : %h", tb_top.u_top.db_qp					);
		// from tq
		$fdisplay(fp_db,"$tq_non_zero_luma  : %h", tb_top.u_top.tq_non_zero_luma[15:0]	);
		// from mc
		$fdisplay(fp_db,"$db_4x4_mv         : %h", tb_top.u_top.u_db_top.db_4x4_mv[255:0]);
			
		// from tq rec mem
		$fdisplay(fp_db,"$mem_rec_dat");
		if (tb_top.u_top.u_tq_top.mem_sel)
			for (i_db=0; i_db<24; i_db=i_db+1)
				$fdisplay(fp_db,"Y%2d: %h", i_db, tb_top.u_top.u_tq_top.u_rec_ram_128x24_1.rf_2p_128x24.mem_array[i_db]);
		else
			for (i_db=0; i_db<24; i_db=i_db+1)
				$fdisplay(fp_db,"Y%2d: %h", i_db, tb_top.u_top.u_tq_top.u_rec_ram_128x24_0.rf_2p_128x24.mem_array[i_db]);	
		
		// from fetch_db ref mem
		$fdisplay(fp_db,"$mem_ref_dat");
		if (tb_top.u_top.u_db_top.y=='b0) begin
			for (i_db=0; i_db<8; i_db=i_db+1)
				$fdisplay(fp_db,"%2d: %h%h", i_db, 'hx, 'hx);
		end
		else begin
			for (i_db=0; i_db<8; i_db=i_db+1)
				$fdisplay(fp_db,"%2d: %h", i_db, tb_top.u_top.u_fetch_db.u_db_top_128x16.rf_2p_128x16.mem_array[i_db+(!tb_top.u_top.u_fetch_db.buf_sel)*8]);
		end
	end	
end

//--------------------------------------------------------------------------
//	dump db outputs for data check                    
//
//         Y            U           V           4x4 block
//    5  6  7  8        29 30       31 32       (msb, left)
// 1  9  10 11 12   25  33 34   27  35 36         1  2  3  4
// 2  13 14 15 16   26  37 38   28  39 40         5  6  7  8 
// 3  17 18 19 20								  9  10 11 12
// 4  21 22 23 24								  13 14 15 16 
//														  (lsb, right)                   
//--------------------------------------------------------------------------
integer		fetch_db_cnt;
reg [5:0]   fetch_db_addr_map[1:40];
reg [127:0]	fetch_db_data;

initial begin
		fetch_db_addr_map[6'd1 ] = 6'h23;
		fetch_db_addr_map[6'd2 ] = 6'h27;
		fetch_db_addr_map[6'd3 ] = 6'h2b;
		fetch_db_addr_map[6'd4 ] = 6'h2f;
		fetch_db_addr_map[6'd5 ] = 6'h1c;
		fetch_db_addr_map[6'd6 ] = 6'h1d;
		fetch_db_addr_map[6'd7 ] = 6'h1e;
		fetch_db_addr_map[6'd8 ] = 6'h1f;
		fetch_db_addr_map[6'd9 ] = 6'h00;
		fetch_db_addr_map[6'd10] = 6'h01;
		fetch_db_addr_map[6'd11] = 6'h02;
		fetch_db_addr_map[6'd12] = 6'h03;
		fetch_db_addr_map[6'd13] = 6'h04;
		fetch_db_addr_map[6'd14] = 6'h05;
		fetch_db_addr_map[6'd15] = 6'h06;
		fetch_db_addr_map[6'd16] = 6'h07;
		fetch_db_addr_map[6'd17] = 6'h08;
		fetch_db_addr_map[6'd18] = 6'h09;
		fetch_db_addr_map[6'd19] = 6'h0a;
		fetch_db_addr_map[6'd20] = 6'h0b;
		fetch_db_addr_map[6'd21] = 6'h0c;
		fetch_db_addr_map[6'd22] = 6'h0d;
		fetch_db_addr_map[6'd23] = 6'h0e;
		fetch_db_addr_map[6'd24] = 6'h0f;
		fetch_db_addr_map[6'd25] = 6'h31;
		fetch_db_addr_map[6'd26] = 6'h35;
		fetch_db_addr_map[6'd27] = 6'h33;
		fetch_db_addr_map[6'd28] = 6'h37;
		fetch_db_addr_map[6'd29] = 6'h18;
		fetch_db_addr_map[6'd30] = 6'h19;
		fetch_db_addr_map[6'd31] = 6'h1a;
		fetch_db_addr_map[6'd32] = 6'h1b;
		fetch_db_addr_map[6'd33] = 6'h10;
		fetch_db_addr_map[6'd34] = 6'h11;
		fetch_db_addr_map[6'd35] = 6'h12;
		fetch_db_addr_map[6'd36] = 6'h13;
		fetch_db_addr_map[6'd37] = 6'h14;
		fetch_db_addr_map[6'd38] = 6'h15;
		fetch_db_addr_map[6'd39] = 6'h16;
		fetch_db_addr_map[6'd40] = 6'h17;
end 

always @(posedge clk) begin
	if (tb_top.u_top.u_db_top.start) begin
		$fdisplay(fp_db_out,"===== Frame: %d  MB x: %d  y: %d =====", tb_top.frame_num,          
																	tb_top.u_top.u_db_top.x, 
																	tb_top.u_top.u_db_top.y);	
	end
	
	if (tb_top.u_top.db_done) 
		for (fetch_db_cnt = 1; fetch_db_cnt<='d40; fetch_db_cnt=fetch_db_cnt+1'b1) begin
			fetch_db_data = tb_top.u_top.u_fetch_db.u_db_rec_128x64.rf_2p_128x64.mem_array[fetch_db_addr_map[fetch_db_cnt]^{tb_top.u_top.u_fetch_db.buf_sel, 5'b0}];
			$fdisplay(fp_db_out,"%2d:%h", fetch_db_cnt, 
										   {fetch_db_data[7:0], fetch_db_data[15:8], fetch_db_data[23:16], fetch_db_data[31:24],
										   fetch_db_data[39:32], fetch_db_data[47:40], fetch_db_data[55:48], fetch_db_data[63:56],
										   fetch_db_data[71:64], fetch_db_data[79:72], fetch_db_data[87:80], fetch_db_data[95:88],
										   fetch_db_data[103:96], fetch_db_data[111:104], fetch_db_data[119:112], fetch_db_data[127:120]});	
		end
end

//--------------------------------------------------------------------------
//	dump db all inputs for tb_db                                    
//--------------------------------------------------------------------------
always @(posedge clk) begin
	if (tb_top.u_top.u_db_top.start) begin
		#5;
		// from top
		$fdisplay(fp_db_in,"%h", tb_top.u_top.u_db_top.x				);
		$fdisplay(fp_db_in,"%h", tb_top.u_top.u_db_top.y				);
		$fdisplay(fp_db_in,"%h", tb_top.u_top.intra_flag       			);
		$fdisplay(fp_db_in,"%h", tb_top.u_top.db_qp						);
		// from tq
		$fdisplay(fp_db_in,"%h", tb_top.u_top.tq_non_zero_luma[15:0]	);
		// from mc
		$fdisplay(fp_db_in,"%h", tb_top.u_top.u_db_top.db_4x4_mv[255:0] );			
		// from tq rec mem
		if (tb_top.u_top.u_tq_top.mem_sel)
			for (i_db=0; i_db<24; i_db=i_db+1)
				$fdisplay(fp_db_in,"%h", tb_top.u_top.u_tq_top.u_rec_ram_128x24_1.rf_2p_128x24.mem_array[i_db]);
		else
			for (i_db=0; i_db<24; i_db=i_db+1)
				$fdisplay(fp_db_in,"%h", tb_top.u_top.u_tq_top.u_rec_ram_128x24_0.rf_2p_128x24.mem_array[i_db]);	
		// from fetch_db ref mem 	
		if (tb_top.u_top.u_db_top.y=='b0) begin
			for (i_db=0; i_db<8; i_db=i_db+1)
				$fdisplay(fp_db_in,"%h%h", 'hx, 'hx);
		end
		else begin
			for (i_db=0; i_db<8; i_db=i_db+1)
				$fdisplay(fp_db_in,"%h", tb_top.u_top.u_fetch_db.u_db_top_128x16.rf_2p_128x16.mem_array[i_db+(!tb_top.u_top.u_fetch_db.buf_sel)*8]);
		end
	end		
end

`endif
