 /*                                                                      
 Copyright 2019 Blue Liang, liangkangnan@163.com
                                                                         
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

// ram module
module ram(

    input wire clk,
    input wire rst,

    input wire we_i,                   // write enable
    input wire[`MemAddrBus] addr_i,    // addr
    input wire[`MemBus] data_i,

    output reg[`MemBus] data_o         // read data

    );

    reg[`MemBus] _ram[0:`MemNum - 1];


    always @ (posedge clk) begin
        if (we_i == `WriteEnable) begin
            _ram[addr_i[31:2]] <= data_i;
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_o = `ZeroWord;
        end else begin
            data_o = _ram[addr_i[31:2]];
        end
    end

    // always @ (posedge clk) begin
    //     if (rst == `RstEnable) begin
    //         data_o = `ZeroWord;
    //     end else begin
    //         data_o = _ram[addr_i[31:2]];
    //     end
    // end
    
endmodule
