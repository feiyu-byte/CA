module tlb #(
 	parameter TLBNUM = 16
)
(
 	input clk,
 // search port 0
 	input [ 18:0] 	s0_vpn2,
 	input 			s0_odd_page,
 	input [ 7:0] 	s0_asid,
 	output 			s0_found,
 	output [$clog2(TLBNUM)-1:0] s0_index,
 	output [ 19:0] 	s0_pfn,
 	output [ 2:0] 	s0_c,
 	output 			s0_d,
 	output 			s0_v,
 // search port 1
 	input [ 18:0] 	s1_vpn2,
 	input 			s1_odd_page,
 	input [ 7:0] 	s1_asid,
 	output 			s1_found,
 	output [$clog2(TLBNUM)-1:0] s1_index,
 	output [ 19:0] 	s1_pfn,
 	output [ 2:0] 	s1_c,
 	output 			s1_d,
 	output 			s1_v,
 // write port
 	input we, //w(rite) e(nable)
 	input [$clog2(TLBNUM)-1:0] w_index,
 	input [ 18:0] w_vpn2,
 	input [ 7:0] w_asid,
	input w_g,
 	input [ 19:0] w_pfn0,
 	input [ 2:0] w_c0,
 	input w_d0,
 	input w_v0,
 	input [ 19:0] w_pfn1,
 	input [ 2:0] w_c1,
 	input w_d1,
 	input w_v1,
 // read port
 	input [$clog2(TLBNUM)-1:0] r_index,
 	output [ 18:0] r_vpn2,
 	output [ 7:0] r_asid,
 	output r_g,
 	output [ 19:0] r_pfn0,
 	output [ 2:0] r_c0,
 	output r_d0,
 	output r_v0,
 	output [ 19:0] r_pfn1,
 	output [ 2:0] r_c1,
 	output r_d1,
 	output r_v1
);
	reg [ 18:0] tlb_vpn2 [TLBNUM-1:0];
	reg [ 7:0]  tlb_asid [TLBNUM-1:0];
	reg 		tlb_g [TLBNUM-1:0];
	reg [ 19:0] tlb_pfn0 [TLBNUM-1:0];
	reg [ 2:0]  tlb_c0 [TLBNUM-1:0];
	reg 		tlb_d0 [TLBNUM-1:0];
	reg 		tlb_v0 [TLBNUM-1:0];
	reg [ 19:0] tlb_pfn1 [TLBNUM-1:0];
	reg [ 2:0]  tlb_c1 [TLBNUM-1:0];
	reg 		tlb_d1 [TLBNUM-1:0];
	reg 		tlb_v1 [TLBNUM-1:0];
	//search port 0
	wire [15:0] match0;
	wire [ 2:0] s0_c0;
	wire 		s0_d0;
	wire 		s0_v0;
	wire [ 2:0] s0_c1;
	wire 		s0_d1;
	wire 		s0_v1;
	assign match0[0]  = (s0_vpn2 == tlb_vpn2[0]) && ((s0_asid == tlb_asid[0]) || tlb_g[0]);
	assign match0[1]  = (s0_vpn2 == tlb_vpn2[1]) && ((s0_asid == tlb_asid[1]) || tlb_g[1]);
	assign match0[2]  = (s0_vpn2 == tlb_vpn2[2]) && ((s0_asid == tlb_asid[2]) || tlb_g[2]);
	assign match0[3]  = (s0_vpn2 == tlb_vpn2[3]) && ((s0_asid == tlb_asid[3]) || tlb_g[3]);
	assign match0[4]  = (s0_vpn2 == tlb_vpn2[4]) && ((s0_asid == tlb_asid[4]) || tlb_g[4]);
	assign match0[5]  = (s0_vpn2 == tlb_vpn2[5]) && ((s0_asid == tlb_asid[5]) || tlb_g[5]);
	assign match0[6]  = (s0_vpn2 == tlb_vpn2[6]) && ((s0_asid == tlb_asid[6]) || tlb_g[6]);
	assign match0[7]  = (s0_vpn2 == tlb_vpn2[7]) && ((s0_asid == tlb_asid[7]) || tlb_g[7]);
	assign match0[8]  = (s0_vpn2 == tlb_vpn2[8]) && ((s0_asid == tlb_asid[8]) || tlb_g[8]);
	assign match0[9]  = (s0_vpn2 == tlb_vpn2[9]) && ((s0_asid == tlb_asid[9]) || tlb_g[9]);
	assign match0[10] = (s0_vpn2 == tlb_vpn2[10]) && ((s0_asid == tlb_asid[10]) || tlb_g[10]);
	assign match0[11] = (s0_vpn2 == tlb_vpn2[11]) && ((s0_asid == tlb_asid[11]) || tlb_g[11]);
	assign match0[12] = (s0_vpn2 == tlb_vpn2[12]) && ((s0_asid == tlb_asid[12]) || tlb_g[12]);
	assign match0[13] = (s0_vpn2 == tlb_vpn2[13]) && ((s0_asid == tlb_asid[13]) || tlb_g[13]);
	assign match0[14] = (s0_vpn2 == tlb_vpn2[14]) && ((s0_asid == tlb_asid[14]) || tlb_g[14]);
	assign match0[15] = (s0_vpn2 == tlb_vpn2[15]) && ((s0_asid == tlb_asid[15]) || tlb_g[15]);
	
	assign s0_found = (match0!=0);
	assign s0_index = ({4{match0[0]}}&4'h0) | ({4{match0[1]}}&4'h1) | ({4{match0[2]}}&4'h2) 
					| ({4{match0[3]}}&4'h3) | ({4{match0[4]}}&4'h4) | ({4{match0[5]}}&4'h5) 
					| ({4{match0[6]}}&4'h6) | ({4{match0[7]}}&4'h7) | ({4{match0[8]}}&4'h8) 
					| ({4{match0[9]}}&4'h9) | ({4{match0[10]}}&4'ha) | ({4{match0[11]}}&4'hb) 
					| ({4{match0[12]}}&4'hc) | ({4{match0[13]}}&4'hd) | ({4{match0[14]}}&4'he) | ({4{match0[15]}}&4'hf);

	assign s0_v0 = match0[0]&tlb_v0[0] | match0[1]&tlb_v0[1] | match0[2]&tlb_v0[2] | match0[3]&tlb_v0[3] |
				  match0[4]&tlb_v0[4] | match0[5]&tlb_v0[5] | match0[6]&tlb_v0[6] | match0[7]&tlb_v0[7] |
				  match0[8]&tlb_v0[8] | match0[9]&tlb_v0[9] | match0[10]&tlb_v0[10] | match0[11]&tlb_v0[11] |
				  match0[12]&tlb_v0[12] | match0[13]&tlb_v0[13] | match0[14]&tlb_v0[14] | match0[15]&tlb_v0[15] ;

	assign s0_d0 = match0[0]&tlb_d0[0] | match0[1]&tlb_d0[1] | match0[2]&tlb_d0[2] | match0[3]&tlb_d0[3] |
				  match0[4]&tlb_d0[4] | match0[5]&tlb_d0[5] | match0[6]&tlb_d0[6] | match0[7]&tlb_d0[7] |
				  match0[8]&tlb_d0[8] | match0[9]&tlb_d0[9] | match0[10]&tlb_d0[10] | match0[11]&tlb_d0[11] |
				  match0[12]&tlb_d0[12] | match0[13]&tlb_d0[13] | match0[14]&tlb_d0[14] | match0[15]&tlb_d0[15] ;

	assign s0_c0 = {2{match0[0]}}&tlb_c0[0] | {2{match0[1]}}&tlb_c0[1] | {2{match0[2]}}&tlb_c0[2] | {2{match0[3]}}&tlb_c0[3] |
				  {2{match0[4]}}&tlb_c0[4] | {2{match0[5]}}&tlb_c0[5] | {2{match0[6]}}&tlb_c0[6] | {2{match0[7]}}&tlb_c0[7] |
				  {2{match0[8]}}&tlb_c0[8] | {2{match0[9]}}&tlb_c0[9] | {2{match0[10]}}&tlb_c0[10] | {2{match0[11]}}&tlb_c0[11] |
				  {2{match0[12]}}&tlb_c0[12] | {2{match0[13]}}&tlb_c0[13] | {2{match0[14]}}&tlb_c0[14] | {2{match0[15]}}&tlb_c0[15] ;

	assign s0_v1 = match0[0]&tlb_v1[0] | match0[1]&tlb_v1[1] | match0[2]&tlb_v1[2] | match0[3]&tlb_v1[3] |
				  match0[4]&tlb_v1[4] | match0[5]&tlb_v1[5] | match0[6]&tlb_v1[6] | match0[7]&tlb_v1[7] |
				  match0[8]&tlb_v1[8] | match0[9]&tlb_v1[9] | match0[10]&tlb_v1[10] | match0[11]&tlb_v1[11] |
				  match0[12]&tlb_v1[12] | match0[13]&tlb_v1[13] | match0[14]&tlb_v1[14] | match0[15]&tlb_v1[15] ;

	assign s0_d1 = match0[0]&tlb_d1[0] | match0[1]&tlb_d1[1] | match0[2]&tlb_d1[2] | match0[3]&tlb_d1[3] |
				  match0[4]&tlb_d1[4] | match0[5]&tlb_d1[5] | match0[6]&tlb_d1[6] | match0[7]&tlb_d1[7] |
				  match0[8]&tlb_d1[8] | match0[9]&tlb_d1[9] | match0[10]&tlb_d1[10] | match0[11]&tlb_d1[11] |
				  match0[12]&tlb_d1[12] | match0[13]&tlb_d1[13] | match0[14]&tlb_d1[14] | match0[15]&tlb_d1[15] ;

	assign s0_c1 = {2{match0[0]}}&tlb_c1[0] | {2{match0[1]}}&tlb_c1[1] | {2{match0[2]}}&tlb_c1[2] | {2{match0[3]}}&tlb_c1[3] |
				  {2{match0[4]}}&tlb_c1[4] | {2{match0[5]}}&tlb_c1[5] | {2{match0[6]}}&tlb_c1[6] | {2{match0[7]}}&tlb_c1[7] |
				  {2{match0[8]}}&tlb_c1[8] | {2{match0[9]}}&tlb_c1[9] | {2{match0[10]}}&tlb_c1[10] | {2{match0[11]}}&tlb_c1[11] |
				  {2{match0[12]}}&tlb_c1[12] | {2{match0[13]}}&tlb_c1[13] | {2{match0[14]}}&tlb_c1[14] | {2{match0[15]}}&tlb_c1[15] ;
	assign s0_c = (s0_odd_page)?s0_c1:s0_c0;
	assign s0_d = (s0_odd_page)?s0_d1:s0_d0;
	assign s0_v = (s0_odd_page)?s0_v1:s0_v0;
	assign s0_pfn = {19{match0[0]}}&((s0_odd_page)?tlb_pfn1[0]:tlb_pfn0[0]) | {19{match0[1]}}&((s0_odd_page)?tlb_pfn1[1]:tlb_pfn0[1]) | {19{match0[2]}}&((s0_odd_page)?tlb_pfn1[2]:tlb_pfn0[2]) | {19{match0[3]}}&((s0_odd_page)?tlb_pfn1[3]:tlb_pfn0[3]) |
				    {19{match0[4]}}&((s0_odd_page)?tlb_pfn1[4]:tlb_pfn0[4]) | {19{match0[5]}}&((s0_odd_page)?tlb_pfn1[5]:tlb_pfn0[5]) | {19{match0[6]}}&((s0_odd_page)?tlb_pfn1[6]:tlb_pfn0[6]) | {19{match0[7]}}&((s0_odd_page)?tlb_pfn1[7]:tlb_pfn0[7]) |
				    {19{match0[8]}}&((s0_odd_page)?tlb_pfn1[8]:tlb_pfn0[8]) | {19{match0[9]}}&((s0_odd_page)?tlb_pfn1[9]:tlb_pfn0[9]) | {19{match0[10]}}&((s0_odd_page)?tlb_pfn1[10]:tlb_pfn0[10]) | {19{match0[11]}}&((s0_odd_page)?tlb_pfn1[11]:tlb_pfn0[11]) |
				    {19{match0[12]}}&((s0_odd_page)?tlb_pfn1[12]:tlb_pfn0[12]) | {19{match0[13]}}&((s0_odd_page)?tlb_pfn1[13]:tlb_pfn0[13]) | {19{match0[14]}}&((s0_odd_page)?tlb_pfn1[14]:tlb_pfn0[14]) | {19{match0[15]}}&((s0_odd_page)?tlb_pfn1[15]:tlb_pfn0[15]) ;
//search port 1
	wire [15:0] match1;
	wire [ 2:0] s1_c0;
	wire 		s1_d0;
	wire 		s1_v0;
	wire [ 2:0] s1_c1;
	wire 		s1_d1;
	wire 		s1_v1;
	assign match1[0]  = (s1_vpn2 == tlb_vpn2[0]) && ((s1_asid == tlb_asid[0]) || tlb_g[0]);
	assign match1[1]  = (s1_vpn2 == tlb_vpn2[1]) && ((s1_asid == tlb_asid[1]) || tlb_g[1]);
	assign match1[2]  = (s1_vpn2 == tlb_vpn2[2]) && ((s1_asid == tlb_asid[2]) || tlb_g[2]);
	assign match1[3]  = (s1_vpn2 == tlb_vpn2[3]) && ((s1_asid == tlb_asid[3]) || tlb_g[3]);
	assign match1[4]  = (s1_vpn2 == tlb_vpn2[4]) && ((s1_asid == tlb_asid[4]) || tlb_g[4]);
	assign match1[5]  = (s1_vpn2 == tlb_vpn2[5]) && ((s1_asid == tlb_asid[5]) || tlb_g[5]);
	assign match1[6]  = (s1_vpn2 == tlb_vpn2[6]) && ((s1_asid == tlb_asid[6]) || tlb_g[6]);
	assign match1[7]  = (s1_vpn2 == tlb_vpn2[7]) && ((s1_asid == tlb_asid[7]) || tlb_g[7]);
	assign match1[8]  = (s1_vpn2 == tlb_vpn2[8]) && ((s1_asid == tlb_asid[8]) || tlb_g[8]);
	assign match1[9]  = (s1_vpn2 == tlb_vpn2[9]) && ((s1_asid == tlb_asid[9]) || tlb_g[9]);
	assign match1[10] = (s1_vpn2 == tlb_vpn2[10]) && ((s1_asid == tlb_asid[10]) || tlb_g[10]);
	assign match1[11] = (s1_vpn2 == tlb_vpn2[11]) && ((s1_asid == tlb_asid[11]) || tlb_g[11]);
	assign match1[12] = (s1_vpn2 == tlb_vpn2[12]) && ((s1_asid == tlb_asid[12]) || tlb_g[12]);
	assign match1[13] = (s1_vpn2 == tlb_vpn2[13]) && ((s1_asid == tlb_asid[13]) || tlb_g[13]);
	assign match1[14] = (s1_vpn2 == tlb_vpn2[14]) && ((s1_asid == tlb_asid[14]) || tlb_g[14]);
	assign match1[15] = (s1_vpn2 == tlb_vpn2[15]) && ((s1_asid == tlb_asid[15]) || tlb_g[15]);
	
	assign s1_found = (match1!=0);
	assign s1_index = ({4{match1[0]}}&4'h0) | ({4{match1[1]}}&4'h1) | ({4{match1[2]}}&4'h2) 
					| ({4{match1[3]}}&4'h3) | ({4{match1[4]}}&4'h4) | ({4{match1[5]}}&4'h5) 
					| ({4{match1[6]}}&4'h6) | ({4{match1[7]}}&4'h7) | ({4{match1[8]}}&4'h8) 
					| ({4{match1[9]}}&4'h9) | ({4{match1[10]}}&4'ha) | ({4{match1[11]}}&4'hb) 
					| ({4{match1[12]}}&4'hc) | ({4{match1[13]}}&4'hd) | ({4{match1[14]}}&4'he) | ({4{match1[15]}}&4'hf);
	assign s1_v0 = match1[0]&tlb_v0[0] | match1[1]&tlb_v0[1] | match1[2]&tlb_v0[2] | match1[3]&tlb_v0[3] |
				  match1[4]&tlb_v0[4] | match1[5]&tlb_v0[5] | match1[6]&tlb_v0[6] | match1[7]&tlb_v0[7] |
				  match1[8]&tlb_v0[8] | match1[9]&tlb_v0[9] | match1[10]&tlb_v0[10] | match1[11]&tlb_v0[11] |
				  match1[12]&tlb_v0[12] | match1[13]&tlb_v0[13] | match1[14]&tlb_v0[14] | match1[15]&tlb_v0[15] ;

	assign s1_d0 = match1[0]&tlb_d0[0] | match1[1]&tlb_d0[1] | match1[2]&tlb_d0[2] | match1[3]&tlb_d0[3] |
				  match1[4]&tlb_d0[4] | match1[5]&tlb_d0[5] | match1[6]&tlb_d0[6] | match1[7]&tlb_d0[7] |
				  match1[8]&tlb_d0[8] | match1[9]&tlb_d0[9] | match1[10]&tlb_d0[10] | match1[11]&tlb_d0[11] |
				  match1[12]&tlb_d0[12] | match1[13]&tlb_d0[13] | match1[14]&tlb_d0[14] | match1[15]&tlb_d0[15] ;

	assign s1_c0 = {2{match1[0]}}&tlb_c0[0] | {2{match1[1]}}&tlb_c0[1] | {2{match1[2]}}&tlb_c0[2] | {2{match1[3]}}&tlb_c0[3] |
				  {2{match1[4]}}&tlb_c0[4] | {2{match1[5]}}&tlb_c0[5] | {2{match1[6]}}&tlb_c0[6] | {2{match1[7]}}&tlb_c0[7] |
				  {2{match1[8]}}&tlb_c0[8] | {2{match1[9]}}&tlb_c0[9] | {2{match1[10]}}&tlb_c0[10] | {2{match1[11]}}&tlb_c0[11] |
				  {2{match1[12]}}&tlb_c0[12] | {2{match1[13]}}&tlb_c0[13] | {2{match1[14]}}&tlb_c0[14] | {2{match1[15]}}&tlb_c0[15] ;
	assign s1_v1 = match1[0]&tlb_v1[0] | match1[1]&tlb_v1[1] | match1[2]&tlb_v1[2] | match1[3]&tlb_v1[3] |
				  match1[4]&tlb_v1[4] | match1[5]&tlb_v1[5] | match1[6]&tlb_v1[6] | match1[7]&tlb_v1[7] |
				  match1[8]&tlb_v1[8] | match1[9]&tlb_v1[9] | match1[10]&tlb_v1[10] | match1[11]&tlb_v1[11] |
				  match1[12]&tlb_v1[12] | match1[13]&tlb_v1[13] | match1[14]&tlb_v1[14] | match1[15]&tlb_v1[15] ;

	assign s1_d1 = match1[0]&tlb_d1[0] | match1[1]&tlb_d1[1] | match1[2]&tlb_d1[2] | match1[3]&tlb_d1[3] |
				  match1[4]&tlb_d1[4] | match1[5]&tlb_d1[5] | match1[6]&tlb_d1[6] | match1[7]&tlb_d1[7] |
				  match1[8]&tlb_d1[8] | match1[9]&tlb_d1[9] | match1[10]&tlb_d1[10] | match1[11]&tlb_d1[11] |
				  match1[12]&tlb_d1[12] | match1[13]&tlb_d1[13] | match1[14]&tlb_d1[14] | match1[15]&tlb_d1[15] ;

	assign s1_c1 = {2{match1[0]}}&tlb_c1[0] | {2{match1[1]}}&tlb_c1[1] | {2{match1[2]}}&tlb_c1[2] | {2{match1[3]}}&tlb_c1[3] |
				  {2{match1[4]}}&tlb_c1[4] | {2{match1[5]}}&tlb_c1[5] | {2{match1[6]}}&tlb_c1[6] | {2{match1[7]}}&tlb_c1[7] |
				  {2{match1[8]}}&tlb_c1[8] | {2{match1[9]}}&tlb_c1[9] | {2{match1[10]}}&tlb_c1[10] | {2{match1[11]}}&tlb_c1[11] |
				  {2{match1[12]}}&tlb_c1[12] | {2{match1[13]}}&tlb_c1[13] | {2{match1[14]}}&tlb_c1[14] | {2{match1[15]}}&tlb_c1[15] ;
    assign s1_c = (s1_odd_page)?s1_c1:s1_c0;
	assign s1_d = (s1_odd_page)?s1_d1:s1_d0;
	assign s1_v = (s1_odd_page)?s1_v1:s1_v0;
	assign s1_pfn = {19{match1[0]}}&((s1_odd_page)?tlb_pfn1[0]:tlb_pfn0[0]) | {19{match1[1]}}&((s1_odd_page)?tlb_pfn1[1]:tlb_pfn0[1]) | {19{match1[2]}}&((s1_odd_page)?tlb_pfn1[2]:tlb_pfn0[2]) | {19{match1[3]}}&((s1_odd_page)?tlb_pfn1[3]:tlb_pfn0[3]) |
				    {19{match1[4]}}&((s1_odd_page)?tlb_pfn1[4]:tlb_pfn0[4]) | {19{match1[5]}}&((s1_odd_page)?tlb_pfn1[5]:tlb_pfn0[5]) | {19{match1[6]}}&((s1_odd_page)?tlb_pfn1[6]:tlb_pfn0[6]) | {19{match1[7]}}&((s1_odd_page)?tlb_pfn1[7]:tlb_pfn0[7]) |
				    {19{match1[8]}}&((s1_odd_page)?tlb_pfn1[8]:tlb_pfn0[8]) | {19{match1[9]}}&((s1_odd_page)?tlb_pfn1[9]:tlb_pfn0[9]) | {19{match1[10]}}&((s1_odd_page)?tlb_pfn1[10]:tlb_pfn0[10]) | {19{match1[11]}}&((s1_odd_page)?tlb_pfn1[11]:tlb_pfn0[11]) |
				    {19{match1[12]}}&((s1_odd_page)?tlb_pfn1[12]:tlb_pfn0[12]) | {19{match1[13]}}&((s1_odd_page)?tlb_pfn1[13]:tlb_pfn0[13]) | {19{match1[14]}}&((s1_odd_page)?tlb_pfn1[14]:tlb_pfn0[14]) | {19{match1[15]}}&((s1_odd_page)?tlb_pfn1[15]:tlb_pfn0[15]) ;
// write 
	always @(posedge clk ) begin
		if (we) begin
			tlb_g[w_index] <= w_g;
			tlb_vpn2[w_index] <= w_vpn2;
			tlb_asid[w_index] <= w_asid;
			tlb_pfn0[w_index] <= w_pfn0;
			tlb_pfn1[w_index] <= w_pfn1;
			tlb_c0[w_index] <= w_c0;
			tlb_c1[w_index] <= w_c1;
			tlb_d0[w_index] <= w_d0;
			tlb_d1[w_index] <= w_d1;
			tlb_v0[w_index] <= w_v0;
			tlb_v1[w_index] <= w_v1;
		end
	end
//read
	assign r_vpn2 = tlb_vpn2[r_index];
	assign r_asid = tlb_asid[r_index];
	assign r_g = tlb_g[r_index];
	assign r_c1 = tlb_c1[r_index];
	assign r_c0 = tlb_c0[r_index];
	assign r_d0 = tlb_d0[r_index];
	assign r_d1 = tlb_d1[r_index];
	assign r_v0 = tlb_v0[r_index];
	assign r_v1 = tlb_v1[r_index];
	assign r_pfn1 = tlb_pfn1[r_index];
	assign r_pfn0 = tlb_pfn0[r_index];
endmodule

