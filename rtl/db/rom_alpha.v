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
// Filename       : bs.v
// Author         : shen weiwei
// Created        : 2011-01-07
// Description    : Where does this file get inputs and send outputs?
// What does the guts of this file accomplish, and how does it do it?
// What module(s) does this file instantiate?
//               
// $Id$ 
//------------------------------------------------------------------- 
`include "enc_defines.v"

module rom_alpha ( address_i, q_o );

input [5:0] address_i;

output [7:0] q_o;
reg [7:0] q_o;

always@(address_i)
begin
	case(address_i)
	6'd16:q_o = 8'd4;
	6'd17:q_o = 8'd4;
	6'd18:q_o = 8'd5;
	6'd19:q_o = 8'd6;
	6'd20:q_o = 8'd7;
	6'd21:q_o = 8'd8;
	6'd22:q_o = 8'd9;
	6'd23:q_o = 8'd10;
	6'd24:q_o = 8'd12;
	6'd25:q_o = 8'd13;
	6'd26:q_o = 8'd15;
	6'd27:q_o = 8'd17;
	6'd28:q_o = 8'd20;
	6'd29:q_o = 8'd22;
	6'd30:q_o = 8'd25;
	6'd31:q_o = 8'd28;
	6'd32:q_o = 8'd32;
	6'd33:q_o = 8'd36;
	6'd34:q_o = 8'd40;
	6'd35:q_o = 8'd45;
	6'd36:q_o = 8'd50;
	6'd37:q_o = 8'd56;
	6'd38:q_o = 8'd63;
	6'd39:q_o = 8'd71;
	6'd40:q_o = 8'd80;
	6'd41:q_o = 8'd90;
	6'd42:q_o = 8'd101;
	6'd43:q_o = 8'd113;
	6'd44:q_o = 8'd127;
	6'd45:q_o = 8'd144;
	6'd46:q_o = 8'd162;
	6'd47:q_o = 8'd182;
	6'd48:q_o = 8'd203;
	6'd49:q_o = 8'd226;
	6'd50:q_o = 8'd255;
	6'd51:q_o = 8'd255;
	default: q_o = 0;
endcase
end

endmodule

