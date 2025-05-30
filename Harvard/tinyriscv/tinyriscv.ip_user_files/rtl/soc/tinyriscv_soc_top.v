 /*                                                                      
 Copyright 2020 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

`include "../core/defines.v"

// tinyriscv soc顶层模块
module tinyriscv_soc_top(

    input  wire         clk             ,
    input  wire         rst             ,

    output reg          over            ,   // 测试是否完成信号
    output reg          succ            ,   // 测试是否成功信号

    output wire         halted_ind      ,   // jtag是否已经halt住CPU信号

    input  wire         uart_debug_pin  ,   // 串口下载使能引脚

    output wire         uart_tx_pin     ,   // UART发送引脚
    input  wire         uart_rx_pin     ,   // UART接收引脚
    inout  wire [1:0]   gpio            ,   // GPIO引脚

    input  wire         jtag_TCK        ,   // JTAG TCK引脚
    input  wire         jtag_TMS        ,   // JTAG TMS引脚
    input  wire         jtag_TDI        ,   // JTAG TDI引脚
    output wire         jtag_TDO        ,   // JTAG TDO引脚

    input  wire         spi_miso        ,   // SPI MISO引脚
    output wire         spi_mosi        ,   // SPI MOSI引脚
    output wire         spi_ss          ,   // SPI SS引脚
    output wire         spi_clk             // SPI CLK引脚

    );


    // core inst interface
    wire[`MemAddrBus]   core_addr_o;
    wire[`MemBus]       core_data_o;
    wire[`MemBus]       core_data_i;
    wire                core_we_o;

    // master 0 interface
    wire[`MemAddrBus] m0_addr_i;
    wire[`MemBus] m0_data_i;
    wire[`MemBus] m0_data_o;
    wire m0_req_i;
    wire m0_we_i;

    // master 1 interface
    wire[`MemAddrBus] m1_addr_i;
    wire[`MemBus] m1_data_i;
    wire[`MemBus] m1_data_o;
    wire m1_req_i;
    wire m1_we_i;

    // master 2 interface
    wire[`MemAddrBus] m2_addr_i;
    wire[`MemBus] m2_data_i;
    wire[`MemBus] m2_data_o;
    wire m2_req_i;
    wire m2_we_i;

    // master 3 interface
    wire[`MemAddrBus] m3_addr_i;
    wire[`MemBus] m3_data_i;
    wire[`MemBus] m3_data_o;
    wire m3_req_i;
    wire m3_we_i;

    // slave 0 interface
    wire[`MemAddrBus] s0_addr_o;
    wire[`MemBus] s0_data_o;
    wire[`MemBus] s0_data_i;
    wire s0_we_o;

    // slave 1 interface
    wire[`MemAddrBus] s1_addr_o;
    wire[`MemBus] s1_data_o;
    wire[`MemBus] s1_data_i;
    wire s1_we_o;

    // slave 2 interface
    wire[`MemAddrBus] s2_addr_o;
    wire[`MemBus] s2_data_o;
    wire[`MemBus] s2_data_i;
    wire s2_we_o;

    // slave 3 interface
    wire[`MemAddrBus] s3_addr_o;
    wire[`MemBus] s3_data_o;
    wire[`MemBus] s3_data_i;
    wire s3_we_o;

    // slave 4 interface
    wire[`MemAddrBus] s4_addr_o;
    wire[`MemBus] s4_data_o;
    wire[`MemBus] s4_data_i;
    wire s4_we_o;

    // slave 5 interface
    wire[`MemAddrBus] s5_addr_o;
    wire[`MemBus] s5_data_o;
    wire[`MemBus] s5_data_i;
    wire s5_we_o;

    // rib
    wire rib_hold_flag_o;

    // jtag
    wire jtag_halt_req_o;
    wire jtag_reset_req_o;
    wire[`RegAddrBus] jtag_reg_addr_o;
    wire[`RegBus] jtag_reg_data_o;
    wire jtag_reg_we_o;
    wire[`RegBus] jtag_reg_data_i;

    // tinyriscv
    wire[`INT_BUS] int_flag;

    // timer0
    wire timer0_int;

    // gpio
    wire[1:0] io_in;
    wire[31:0] gpio_ctrl;
    wire[31:0] gpio_data;

    assign int_flag = {7'h0, timer0_int};

    // 低电平点亮LED
    // 低电平表示已经halt住CPU
    assign halted_ind = ~jtag_halt_req_o;


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            over <= 1'b1;
            succ <= 1'b1;
        end else begin
            over <= ~u_tinyriscv.u_regs.regs[26];  // when = 1, run over
            succ <= ~u_tinyriscv.u_regs.regs[27];  // when = 1, run succ, otherwise fail
        end
    end

    // tinyriscv处理器核模块例化
    tinyriscv u_tinyriscv(
        .clk(clk),
        .rst(rst),
        .rib_ex_addr_o(m0_addr_i),
        .rib_ex_data_i(m0_data_o),
        .rib_ex_data_o(m0_data_i),
        .rib_ex_req_o(m0_req_i),
        .rib_ex_we_o(m0_we_i),

        .rib_pc_addr_o  (m1_addr_i),
        .rib_pc_data_i  (m1_data_o),
`ifdef Harvard
        .rib_pc_req_o   (m1_req_o),
        .inst_we_o      (core_we_o),
        .inst_addr_o    (core_addr_o),
        .inst_data_o    (core_data_o),
        .inst_data_i    (core_data_i),
`endif

        .jtag_reg_addr_i(jtag_reg_addr_o),
        .jtag_reg_data_i(jtag_reg_data_o),
        .jtag_reg_we_i(jtag_reg_we_o),
        .jtag_reg_data_o(jtag_reg_data_i),

        .rib_hold_flag_i(rib_hold_flag_o),
        .axil_hold_flag_i(axil_hold_flag_o),
        .axil_flush_flag_i(axil_flush_flag_o),
        .jtag_halt_flag_i(jtag_halt_req_o),
        .jtag_reset_flag_i(jtag_reset_req_o),

        .int_i(int_flag)
    );

    // rom模块例化
    rom u_rom(
        .clk        (clk),
        .rst        (rst),
`ifdef Harvard
        .we_i       (core_we_o),
        .addr_i     (core_addr_o),
        .data_i     (core_data_o),
        .data_o     (core_data_i),
        .rib_we_i   (s0_we_o),
        .rib_addr_i (s0_addr_o),
        .rib_data_i (s0_data_o),
        .rib_data_o (s0_data_i)
`else
        .we_i       (s0_we_o),
        .addr_i     (s0_addr_o),
        .data_i     (s0_data_o),
        .data_o     (s0_data_i)
`endif
    );

    // ram模块例化
    ram u_ram(
        .clk(clk),
        .rst(rst),
        .we_i(s1_we_o),
        .addr_i(s1_addr_o),
        .data_i(s1_data_o),
        .data_o(s1_data_i)
    );

    // timer模块例化
    timer timer_0(
        .clk(clk),
        .rst(rst),
        .data_i(s2_data_o),
        .addr_i(s2_addr_o),
        .we_i(s2_we_o),
        .data_o(s2_data_i),
        .int_sig_o(timer0_int)
    );

    // uart模块例化
    uart uart_0(
        .clk(clk),
        .rst(rst),
        .we_i(s3_we_o),
        .addr_i(s3_addr_o),
        .data_i(s3_data_o),
        .data_o(s3_data_i),
        .tx_pin(uart_tx_pin),
        .rx_pin(uart_rx_pin)
    );

    // // io0
    // assign gpio[0] = (gpio_ctrl[1:0] == 2'b01)? gpio_data[0]: 1'bz;
    // assign io_in[0] = gpio[0];
    // // io1
    // assign gpio[1] = (gpio_ctrl[3:2] == 2'b01)? gpio_data[1]: 1'bz;
    // assign io_in[1] = gpio[1];

    // // gpio模块例化
    // gpio gpio_0(
    //     .clk(clk),
    //     .rst(rst),
    //     .we_i(s4_we_o),
    //     .addr_i(s4_addr_o),
    //     .data_i(s4_data_o),
    //     .data_o(s4_data_i),
    //     .io_pin_i(io_in),
    //     .reg_ctrl(gpio_ctrl),
    //     .reg_data(gpio_data)
    // );

    // spi模块例化
    spi spi_0(
        .clk(clk),
        .rst(rst),
        .data_i(s5_data_o),
        .addr_i(s5_addr_o),
        .we_i(s5_we_o),
        .data_o(s5_data_i),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss(spi_ss),
        .spi_clk(spi_clk)
    );

    // rib模块例化
    rib u_rib(
        .clk(clk),
        .rst(rst),

        // master 0 interface
        .m0_addr_i(m0_addr_i),
        .m0_data_i(m0_data_i),
        .m0_data_o(m0_data_o),
        .m0_req_i(m0_req_i),
        .m0_we_i(m0_we_i),

        // master 1 interface
        .m1_addr_i(m1_addr_i),
        .m1_data_i(`ZeroWord),
        .m1_data_o(m1_data_o),
`ifdef Harvard
        .m1_req_i(m1_req_o),
`else
        .m1_req_i(`RIB_REQ),
`endif
        .m1_we_i(`WriteDisable),

        // master 2 interface
        .m2_addr_i(m2_addr_i),
        .m2_data_i(m2_data_i),
        .m2_data_o(m2_data_o),
        .m2_req_i(m2_req_i),
        .m2_we_i(m2_we_i),

        // master 3 interface
        .m3_addr_i(m3_addr_i),
        .m3_data_i(m3_data_i),
        .m3_data_o(m3_data_o),
        .m3_req_i(m3_req_i),
        .m3_we_i(m3_we_i),

        // slave 0 interface
        .s0_addr_o(s0_addr_o),
        .s0_data_o(s0_data_o),
        .s0_data_i(s0_data_i),
        .s0_we_o(s0_we_o),

        // slave 1 interface
        .s1_addr_o(s1_addr_o),
        .s1_data_o(s1_data_o),
        .s1_data_i(s1_data_i),
        .s1_we_o(s1_we_o),

        // slave 2 interface
        .s2_addr_o(s2_addr_o),
        .s2_data_o(s2_data_o),
        .s2_data_i(s2_data_i),
        .s2_we_o(s2_we_o),

        // slave 3 interface
        .s3_addr_o(s3_addr_o),
        .s3_data_o(s3_data_o),
        .s3_data_i(s3_data_i),
        .s3_we_o(s3_we_o),

        // slave 4 interface
        .s4_addr_o          (s4_addr_o),
        .s4_data_o          (s4_data_o),
        .s4_data_i          (s4_data_i),
        .s4_we_o            (s4_we_o),
        .s4_req_o           (s4_req_o),

        // slave 5 interface
        .s5_addr_o(s5_addr_o),
        .s5_data_o(s5_data_o),
        .s5_data_i(s5_data_i),
        .s5_we_o(s5_we_o),

        .hold_flag_o(rib_hold_flag_o)
    );

    // 串口下载模块例化
    uart_debug u_uart_debug(
        .clk(clk),
        .rst(rst),
        .debug_en_i(uart_debug_pin),
        .req_o(m3_req_i),
        .mem_we_o(m3_we_i),
        .mem_addr_o(m3_addr_i),
        .mem_wdata_o(m3_data_i),
        .mem_rdata_i(m3_data_o)
    );

    // jtag模块例化
    jtag_top #(
        .DMI_ADDR_BITS(6),
        .DMI_DATA_BITS(32),
        .DMI_OP_BITS(2)
    ) u_jtag_top(
        .clk(clk),
        .jtag_rst_n(rst),
        .jtag_pin_TCK(jtag_TCK),
        .jtag_pin_TMS(jtag_TMS),
        .jtag_pin_TDI(jtag_TDI),
        .jtag_pin_TDO(jtag_TDO),
        .reg_we_o(jtag_reg_we_o),
        .reg_addr_o(jtag_reg_addr_o),
        .reg_wdata_o(jtag_reg_data_o),
        .reg_rdata_i(jtag_reg_data_i),
        .mem_we_o(m2_we_i),
        .mem_addr_o(m2_addr_i),
        .mem_wdata_o(m2_data_i),
        .mem_rdata_i(m2_data_o),
        .op_req_o(m2_req_i),
        .halt_req_o(jtag_halt_req_o),
        .reset_req_o(jtag_reset_req_o)
    );

    //AXI-Lite
    localparam  C_M_START_DATA_VALUE	= 32'h40000000      ;
    localparam  C_M_AXI_ADDR_WIDTH	    = 28                ;
    localparam  C_M_AXI_DATA_WIDTH	    = 32                ;

    wire                                M_AXI_ACLK          ;
    wire                                M_AXI_ARESETN       ;
    wire [C_M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_AWADDR        ;
    wire [2 : 0]                        M_AXI_AWPROT        ;
    wire                                M_AXI_AWVALID       ;
    wire                                M_AXI_AWREADY       ;
    wire [C_M_AXI_DATA_WIDTH-1 : 0]     M_AXI_WDATA         ;
    wire [C_M_AXI_DATA_WIDTH/8-1 : 0]   M_AXI_WSTRB         ;
    wire                                M_AXI_WVALID        ;
    wire                                M_AXI_WREADY        ;
    wire [1 : 0]                        M_AXI_BRESP         ;
    wire                                M_AXI_BVALID        ;
    wire                                M_AXI_BREADY        ;
    wire [C_M_AXI_ADDR_WIDTH-1 : 0]     M_AXI_ARADDR        ;
    wire [2 : 0]                        M_AXI_ARPROT        ;
    wire                                M_AXI_ARVALID       ;
    wire                                M_AXI_ARREADY       ;
    wire [C_M_AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA         ;
    wire [1 : 0]                        M_AXI_RRESP         ;
    wire                                M_AXI_RVALID        ;
    wire                                M_AXI_RREADY        ;
    wire [`Hold_Flag_Bus]               axil_hold_flag_o    ;
    wire [`Flush_Flag_Bus]              axil_flush_flag_o   ;
    
    assign M_AXI_ACLK = clk;
    assign M_AXI_ARESETN = rst;

    assign M_AXI_AWREADY = S_AXI_AWREADY;
    assign M_AXI_WREADY = S_AXI_WREADY;
    assign M_AXI_BRESP = S_AXI_BRESP;
    assign M_AXI_BVALID = S_AXI_BVALID;
    assign M_AXI_ARREADY = S_AXI_ARREADY;
    assign M_AXI_RDATA = S_AXI_RDATA;
    assign M_AXI_RRESP = S_AXI_RRESP;
    assign M_AXI_RVALID = S_AXI_RVALID;

    axil #
    (
        .C_M_START_DATA_VALUE	(C_M_START_DATA_VALUE   ),
        .C_M_AXI_ADDR_WIDTH		(C_M_AXI_ADDR_WIDTH     ),
        .C_M_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH     )
    )
    axil_inst
    (
        .m_addr_i               (s4_addr_o              ),
        .m_data_i               (s4_data_o              ),
        .m_data_o               (s4_data_i              ),
        .m_we_i                 (s4_we_o                ),
        .m_req_i                (s4_req_o               ),
        .M_AXI_ACLK             (M_AXI_ACLK             ),
        .M_AXI_ARESETN          (M_AXI_ARESETN          ),
        .M_AXI_AWADDR           (M_AXI_AWADDR           ),
        .M_AXI_AWPROT           (M_AXI_AWPROT           ),
        .M_AXI_AWVALID          (M_AXI_AWVALID          ),
        .M_AXI_AWREADY          (M_AXI_AWREADY          ),
        .M_AXI_WDATA            (M_AXI_WDATA            ),
        .M_AXI_WSTRB            (M_AXI_WSTRB            ),
        .M_AXI_WVALID           (M_AXI_WVALID           ),
        .M_AXI_WREADY           (M_AXI_WREADY           ),
        .M_AXI_BRESP            (M_AXI_BRESP            ),
        .M_AXI_BVALID           (M_AXI_BVALID           ),
        .M_AXI_BREADY           (M_AXI_BREADY           ),
        .M_AXI_ARADDR           (M_AXI_ARADDR           ),
        .M_AXI_ARPROT           (M_AXI_ARPROT           ),
        .M_AXI_ARVALID          (M_AXI_ARVALID          ),
        .M_AXI_ARREADY          (M_AXI_ARREADY          ),
        .M_AXI_RDATA            (M_AXI_RDATA            ),
        .M_AXI_RRESP            (M_AXI_RRESP            ),
        .M_AXI_RVALID           (M_AXI_RVALID           ),
        .M_AXI_RREADY           (M_AXI_RREADY           ),
        .hold_flag_o            (axil_hold_flag_o       ),
        .flush_flag_o           (axil_flush_flag_o      )
    );

    // AXI-Lite slave
    wire                                S_AXI_ACLK      ;
    wire                                S_AXI_ARESETN   ;
    wire [C_M_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR    ;
    wire [2 : 0]                        S_AXI_AWPROT    ;
    wire                                S_AXI_AWVALID   ;
    wire                                S_AXI_AWREADY   ;
    wire [C_M_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA     ;
    wire [C_M_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB     ;
    wire                                S_AXI_WVALID    ;
    wire                                S_AXI_WREADY    ;
    wire [1 : 0]                        S_AXI_BRESP     ;
    wire                                S_AXI_BVALID    ;
    wire                                S_AXI_BREADY    ;
    wire [C_M_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR    ;
    wire [2 : 0]                        S_AXI_ARPROT    ;
    wire                                S_AXI_ARVALID   ;
    wire                                S_AXI_ARREADY   ;
    wire [C_M_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA     ;
    wire [1 : 0]                        S_AXI_RRESP     ;
    wire                                S_AXI_RVALID    ;
    wire                                S_AXI_RREADY    ;
    assign S_AXI_ACLK    = M_AXI_ACLK;
    assign S_AXI_ARESETN = M_AXI_ARESETN;
    assign S_AXI_AWADDR = M_AXI_AWADDR;
    assign S_AXI_AWPROT = M_AXI_AWPROT;
    assign S_AXI_AWVALID = M_AXI_AWVALID;
    assign S_AXI_WDATA = M_AXI_WDATA;
    assign S_AXI_WSTRB = M_AXI_WSTRB;
    assign S_AXI_WVALID = M_AXI_WVALID;
    assign S_AXI_BREADY = M_AXI_BREADY;
    assign S_AXI_ARADDR = M_AXI_ARADDR;
    assign S_AXI_ARPROT = M_AXI_ARPROT;
    assign S_AXI_ARVALID = M_AXI_ARVALID;
    assign S_AXI_RREADY = M_AXI_RREADY;
    S_AXIL #
    (
        .C_S_AXI_ADDR_WIDTH		(C_M_AXI_ADDR_WIDTH     ),
        .C_S_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH     )
    )
    S_AXIL_u0
    (
        .S_AXI_ACLK             (S_AXI_ACLK             ),
        .S_AXI_ARESETN          (S_AXI_ARESETN          ),
        .S_AXI_AWADDR           (S_AXI_AWADDR           ),
        .S_AXI_AWPROT           (S_AXI_AWPROT           ),
        .S_AXI_AWVALID          (S_AXI_AWVALID          ),
        .S_AXI_AWREADY          (S_AXI_AWREADY          ),
        .S_AXI_WDATA            (S_AXI_WDATA            ),
        .S_AXI_WSTRB            (S_AXI_WSTRB            ),
        .S_AXI_WVALID           (S_AXI_WVALID           ),
        .S_AXI_WREADY           (S_AXI_WREADY           ),
        .S_AXI_BRESP            (S_AXI_BRESP            ),
        .S_AXI_BVALID           (S_AXI_BVALID           ),
        .S_AXI_BREADY           (S_AXI_BREADY           ),
        .S_AXI_ARADDR           (S_AXI_ARADDR           ),
        .S_AXI_ARPROT           (S_AXI_ARPROT           ),
        .S_AXI_ARVALID          (S_AXI_ARVALID          ),
        .S_AXI_ARREADY          (S_AXI_ARREADY          ),
        .S_AXI_RDATA            (S_AXI_RDATA            ),
        .S_AXI_RRESP            (S_AXI_RRESP            ),
        .S_AXI_RVALID           (S_AXI_RVALID           ),
        .S_AXI_RREADY           (S_AXI_RREADY           )
    );

endmodule
