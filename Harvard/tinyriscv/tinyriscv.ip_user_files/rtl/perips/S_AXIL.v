
`timescale 1 ns / 1 ps

	module S_AXIL #
	(
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 28
	)
	(
		// Users to add ports here
		output wire  wren,
		output wire  rden,
		output wire  [C_S_AXI_ADDR_WIDTH-1 : 0] mem_address,
		output wire  [C_S_AXI_DATA_WIDTH-1 : 0] mem_wdata,
		// input  wire  [C_S_AXI_DATA_WIDTH-1 : 0] mem_rdata,
		input  wire  [255 : 0] mem_rdata,
		// User ports ends
		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire  [2 : 0] S_AXI_AWPROT,
		input wire  S_AXI_AWVALID,
		output wire S_AXI_AWREADY,
		input wire  [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WVALID,
		output wire S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire  [2 : 0] S_AXI_ARPROT,
		input wire  S_AXI_ARVALID,
		output wire S_AXI_ARREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg  [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
	wire  							axi_awready;
	wire  							axi_wready;
	reg  [1 : 0] 					axi_bresp;
	reg  							axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	wire  							axi_arready;
	// wire [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
	reg  [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
	reg  [1 : 0] 					axi_rresp;
	reg  							axi_rvalid;

	// I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY		= axi_wready;
	assign S_AXI_BRESP		= axi_bresp;
	assign S_AXI_BVALID		= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA		= axi_rdata;
	assign S_AXI_RRESP		= axi_rresp;
	assign S_AXI_RVALID		= axi_rvalid;

	assign wren 		= axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;  
	assign rden			= axi_arready & S_AXI_ARVALID & ~axi_rvalid;  
	assign mem_address 	= wren ? S_AXI_AWADDR : rden ? S_AXI_ARADDR : 0;
	assign mem_wdata 	= wren ? S_AXI_WDATA : 'd0;
	// assign axi_rdata 	= rden ? mem_rdata : 'd0;

	assign axi_awready 	= 1'b1;
	assign axi_wready 	= 1'b1; 
	assign axi_arready  = 1'b1;               

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	       if (~axi_bvalid && axi_wready && S_AXI_WVALID)
//         if (~axi_bvalid && S_AXI_WVALID)
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)  
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end       

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end      

	// Add user logic here

	reg  [31:0] data0;
	reg  [31:0] data1;
	always @(posedge S_AXI_ACLK ) begin
		if (S_AXI_ARESETN == 1'b0) begin
			data0 <= 32'b0;
			data1 <= 32'b0;
		end
		else begin
			if (wren) begin
				if (S_AXI_AWADDR == 28'h0) begin
					data0 <= S_AXI_WDATA;
				end
				else if (S_AXI_AWADDR == 28'h4) begin
					data1 <= S_AXI_WDATA;
				end
			end
		end
	end

	always @(*) begin
		if (S_AXI_ARESETN == 1'b0) begin
			axi_rdata <= 32'b0;
		end
		else begin
			if (rden) begin
				if (S_AXI_ARADDR == 28'h0) begin
					axi_rdata <= data0;
				end
				else if (S_AXI_ARADDR == 28'h4) begin
					axi_rdata <= data1;
				end
			end
		end
	end
	// User logic ends

	endmodule
