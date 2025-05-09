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


module rom(

    input wire clk,
    input wire rst,

`ifdef Harvard
    input wire rib_we_i, 
    input wire rib_req_i,
    input wire[`MemAddrBus] rib_addr_i,    // addr
    input wire[`MemBus] rib_data_i,
    output reg[`MemBus] rib_data_o,
`endif
    input wire we_i,                   // write enable
    input wire[`MemAddrBus] addr_i,    // addr
    input wire[`MemBus] data_i,
    output reg[`MemBus] data_o         // read data
    
    

    );

    reg[`MemBus] _rom[0:`RomNum - 1];

`ifdef Harvard
    always @ (posedge clk) begin
        if (rib_we_i == `WriteEnable) begin
            _rom[rib_addr_i[31:2]] <= rib_data_i;
        end
        else if (we_i == `WriteEnable) begin
            _rom[addr_i[31:2]] <= data_i;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            if (rib_req_i == 1'b1) begin
                rib_data_o = _rom[rib_addr_i[31:2]];
            end
            else data_o = _rom[addr_i[31:2]];
        end
    end
`else 
    always @ (posedge clk) begin
        if (we_i == `WriteEnable) begin
            _rom[addr_i[31:2]] <= data_i;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            data_o = _rom[addr_i[31:2]];
        end
    end
`endif


    // initial begin
    //     $readmemh ("D:/FPGA/Projects/RISCV/tinyriscv_4/tinyriscv/tinyriscv.sim", _rom);//bin -> txt -> RTL
    // end

endmodule
