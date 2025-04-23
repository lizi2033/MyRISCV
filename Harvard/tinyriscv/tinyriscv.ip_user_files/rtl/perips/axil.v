`include "../core/defines.v"

module axil #
(
    parameter           C_M_START_DATA_VALUE	= 32'h40000000  ,
    parameter integer   C_M_AXI_ADDR_WIDTH	    = 32            ,
    parameter integer   C_M_AXI_DATA_WIDTH	    = 32                       
)
(
//  rib  intrerface
input   [`MemAddrBus]                   m_addr_i        ,      // 从设备读、写地址
input   [`MemBus]                       m_data_i        ,      // 从设备写数据
output  [`MemBus]                       m_data_o        ,      // 从设备读取到的数据
input                                   m_we_i          ,      // 从设备写标志
input                                   m_req_i         ,

//  AXI intrerface
input                                   M_AXI_ACLK      ,
input                                   M_AXI_ARESETN   ,
output  [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR    ,
output  [2 : 0]                         M_AXI_AWPROT    ,
output                                  M_AXI_AWVALID   ,
input                                   M_AXI_AWREADY   ,
output  [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA     ,
output  [C_M_AXI_DATA_WIDTH/8-1 : 0]    M_AXI_WSTRB     ,
output                                  M_AXI_WVALID    ,
input                                   M_AXI_WREADY    ,
input   [1 : 0]                         M_AXI_BRESP     ,
input                                   M_AXI_BVALID    ,
output                                  M_AXI_BREADY    ,
output  [C_M_AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR    ,
output  [2 : 0]                         M_AXI_ARPROT    ,
output                                  M_AXI_ARVALID   ,
input                                   M_AXI_ARREADY   ,
input   [C_M_AXI_DATA_WIDTH-1 : 0]      M_AXI_RDATA     ,
input   [1 : 0]                         M_AXI_RRESP     ,
input                                   M_AXI_RVALID    ,
output                                  M_AXI_RREADY    ,

//  User
output  [`Hold_Flag_Bus]                hold_flag_o     ,
output  [`Flush_Flag_Bus]               flush_flag_o    
);
  
reg                                     axi_awvalid     ;
reg                                     axi_wvalid      ;
reg  [C_M_AXI_ADDR_WIDTH-1 : 0]         axi_awaddr      ;
reg  [C_M_AXI_DATA_WIDTH-1 : 0]         axi_wdata       ;
reg                                     axi_bready      ;
reg                                     axi_arvalid     ;
reg  [C_M_AXI_ADDR_WIDTH-1 : 0]         axi_araddr      ;
reg                                     axi_rready      ;

reg  [`MemBus]                          m_data          ;

assign M_AXI_AWPROT  = 'd0                              ; 
assign M_AXI_WSTRB   = {C_M_AXI_DATA_WIDTH{1'b1}}       ;
assign M_AXI_ARPROT  = 'd0                              ;
assign M_AXI_AWVALID = axi_awvalid                      ;
assign M_AXI_WVALID  = axi_wvalid                       ;
assign M_AXI_AWADDR  = axi_awaddr                       ;
assign M_AXI_WDATA   = axi_wdata                        ;
assign M_AXI_BREADY  = axi_bready                       ;
assign M_AXI_ARVALID = axi_arvalid                      ;
assign M_AXI_ARADDR  = axi_araddr                       ;
assign M_AXI_RREADY  = axi_rready                       ;

assign m_data_o = m_data;

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        axi_awvalid <= 1'b0;
    end 
    else begin
        if (M_AXI_AWREADY && axi_awvalid) begin
            axi_awvalid <= 1'b0;
        end
        else if (m_req_i && m_we_i) begin
            axi_awvalid <= 1'b1;
        end
    end
end

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        axi_wvalid <= 1'b0;
    end 
    else begin
        if (M_AXI_WREADY && axi_wvalid) begin
            axi_wvalid <= 1'b0;
        end
        else if (m_req_i && m_we_i) begin
            axi_wvalid <= 1'b1;
        end
    end
end

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        // axi_awaddr <= C_M_START_DATA_VALUE;
        axi_awaddr <= 'd0;
        axi_wdata <= 'd0;
    end
    else begin
        if (m_req_i && m_we_i) begin
            axi_awaddr <= m_addr_i;
            axi_wdata <= m_data_i;
        end
    end
end

always @(posedge M_AXI_ACLK) begin                                                                
	if (!M_AXI_ARESETN) begin                                                            
	    axi_bready <= 1'b0;
	end
    else begin
        if (M_AXI_BVALID && ~axi_bready) begin                                                            
            axi_bready <= 1'b1;
        end        
        else if (axi_bready) begin                                                            
            axi_bready <= 1'b0;
        end
        else begin
            axi_bready <= axi_bready;
        end
    end 
end

//  read
always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        axi_arvalid <= 1'b0;
    end 
    else begin
        if (M_AXI_ARREADY && axi_arvalid) begin
            axi_arvalid <= 1'b0;
        end
        else if (m_req_i && ~m_we_i) begin
            axi_arvalid <= 1'b1;
        end
    end
end

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        axi_rready <= 1'b0;
    end 
    else begin
        if (M_AXI_RVALID && ~axi_rready) begin
            axi_rready <= 1'b1; 
        end
        else if (axi_rready) begin
            axi_rready <= 1'b0;
        end
    end
end

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        axi_araddr <= 'd0;
    end
    else begin
        if (m_req_i && ~m_we_i) begin
            axi_araddr <= m_addr_i;
        end
    end
end

always @(*) begin
    if (!M_AXI_ARESETN) begin
        m_data <= 'd0;
    end
    else begin
        if (M_AXI_RVALID && M_AXI_RREADY) begin
            m_data <= M_AXI_RDATA;
        end
    end
end

//  Hold
localparam [3:0]    IDLE    = 'h00;
localparam [3:0]    WRITE   = 'h01;
localparam [3:0]    READ    = 'h02;
localparam [3:0]    FINISH  = 'h03;

reg  [3:0]  state       ;
reg  [3:0]  next_state  ;
reg  [`Hold_Flag_Bus] hold_flag;

assign hold_flag_o = hold_flag;
assign flush_flag_o = `Flush_None;

always @(*) begin
    if (!M_AXI_ARESETN) begin
        hold_flag = `Hold_None;
    end
    else begin
        if(state == FINISH) begin
            hold_flag = `Hold_Ex;
        end
        else if (m_req_i || (state != IDLE)) begin
            hold_flag = `Hold_Mem;
        end
        else begin
            hold_flag = `Hold_None;
        end
    end
end

always @(posedge M_AXI_ACLK ) begin
    if (!M_AXI_ARESETN) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    if (!M_AXI_ARESETN) begin
        next_state = IDLE;
    end
    else begin
        case (state)
            IDLE: begin
                if (m_req_i) begin
                    if (m_we_i) begin
                        next_state = WRITE;
                    end
                    else next_state = READ;
                end
                else next_state = IDLE;
            end
            WRITE: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    next_state = FINISH;
                end
                else next_state = WRITE;
            end
            READ: begin
                if (M_AXI_RVALID && M_AXI_RREADY) begin
                    next_state = FINISH;
                end
                else next_state = READ;
            end
            FINISH: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
end

endmodule