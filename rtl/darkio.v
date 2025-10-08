/*
 * Copyright (c) 2018, Marcelo Samsoniuk
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

`timescale 1ns / 1ps
`include "../rtl/config.vh"

module darkio
`ifdef SPI
#(parameter integer SPI_DIV_COEF = 0)
`endif
(
    input         CLK,      // clock
    input         RES,      // reset
    input         HLT,      // halt

    input         XDREQ,
    input         XWR,
    input         XRD,
    input  [3:0]  XBE,
    input  [31:0] XADDR,
    input  [31:0] XATAI,
    output [31:0] XATAO,
    output        XDACK,
    output        XIRQ,

    input         RXD,  // UART receive line
    output        TXD,  // UART transmit line
`ifdef SPI
    output        CSN,  // SPI CSN output (active LOW)
    output        SCK,  // SPI clock output
    inout         MOSI, // SPI master output slave input (default 4-wire); or m/s i/o (3-wire enabled)
    input         MISO, // SPI master data input, slave data output
`endif

`ifdef SIMULATION
    output        ESIMREQ,
    input         ESIMACK,
`endif

    output [31:0] LED,  // on-board leds
    input  [31:0] IPORT,// general-purpose inputs
    output [31:0] OPORT,// general-purpose outputs
    output  [3:0] DEBUG // osciloscope
);

    // io block

    reg [31:0] OPORTFF = 0;
    reg [31:0] LEDFF  = 0;

    reg  [7:0] IREQ = 0;
    reg  [7:0] IACK = 0;

    reg [31:0] TIMERFF = 0;
    reg [31:0] TIMEUS = 0;
    reg [31:0] TIMEUSFF = 0;

    reg [31:0] IOMUXFF = 0;

    wire [7:0] BOARD_IRQ;

    wire [7:0] BOARD_ID = `BOARD_ID;              // board id
    wire [7:0] BOARD_CM = (`BOARD_CK/2000000);    // board clock (MHz)

    wire [7:0] CORE_ID = 0;                       // core id, unused

    wire [31:0] UDATA; // uart data
`ifdef SPI
    wire [31:0] SDATA; // spi data
`endif

    reg [31:0] TIMER = 0;

    reg [1:0] DTACK  = 0;

    always@(posedge CLK)
    begin
        DTACK <= RES ? 0 : DTACK ? DTACK-1 : (XDREQ && XRD) ? 1 : 0; // wait-states

        if(RES)
        begin
            IACK <= 0;
            TIMERFF <= (`BOARD_CK/1000)-1; // timer set to 1kHz by default
        end
        else
        if(XDREQ && XWR)
        begin
            casex(XADDR[4:0])
                5'b00011:   begin
                                //$display("clear io.irq = %x (ireq=%x, iack=%x)",XATAI[32:24],IREQ,IACK);

                                IACK[7] <= XATAI[7+24] ? IREQ[7] : IACK[7];
                                IACK[6] <= XATAI[6+24] ? IREQ[6] : IACK[6];
                                IACK[5] <= XATAI[5+24] ? IREQ[5] : IACK[5];
                                IACK[4] <= XATAI[4+24] ? IREQ[4] : IACK[4];
                                IACK[3] <= XATAI[3+24] ? IREQ[3] : IACK[3];
                                IACK[2] <= XATAI[2+24] ? IREQ[2] : IACK[2];
                                IACK[1] <= XATAI[1+24] ? IREQ[1] : IACK[1];
                                IACK[0] <= XATAI[0+24] ? IREQ[0] : IACK[0];
                            end
                5'b010xx:   begin
                                LEDFF <= XATAI;
                                //$display("*** SIM: current LED=%x bus %x XBE=%b XADDR=%x",LEDFF,XATAI,XBE,XADDR);
                            end
                5'b01100:   TIMERFF <= XATAI[31:0];
                5'b110xx:   begin
                                OPORTFF <= XATAI;
                                //$display("*** SIM: current OPORT=%x bus %x XBE=%b XADDR=%x",OPORTFF,XATAI,XBE,XADDR);
                            end
            endcase
        end

        if(RES)
        begin
            IREQ     <= 0;
            TIMEUSFF <= (`BOARD_CK/1000000)-1; // usec timer
            TIMER    <= 0;
            TIMEUS   <= 0;
        end
        else
        if(TIMERFF)
        begin
            TIMER <= TIMER ? TIMER-1 : TIMERFF;

            if(TIMER==0 && IREQ==IACK)
            begin
                IREQ[7] <= !IACK[7];

                //$display("timr0 set");
            end

            TIMEUSFF <= TIMEUSFF ? TIMEUSFF-1 : (`BOARD_CK/1000000)-1; // usec timer
            TIMEUS   <= !TIMEUSFF ? TIMEUS + 1'b1 : TIMEUS;
        end

        if(XDREQ && XRD)
        begin
            casex(XADDR[4:0])

        `ifdef __BIG__
                5'b000xx:   IOMUXFF <= { BOARD_ID, BOARD_CM, CORE_ID, BOARD_IRQ };
        `else
                5'b000xx:   IOMUXFF <= { BOARD_IRQ, CORE_ID, BOARD_CM, BOARD_ID };
        `endif

                5'b001xx:   IOMUXFF <= UDATA; // from uart
                5'b010xx:   IOMUXFF <= LEDFF;
                5'b011xx:   IOMUXFF <= TIMERFF;
                5'b100xx:   IOMUXFF <= TIMEUS;
                5'b101xx:   IOMUXFF <= IPORT;
                5'b110xx:   IOMUXFF <= OPORTFF;
`ifdef SPI
                5'b111xx:   IOMUXFF <= SDATA; // from spi
`endif
            endcase
        end
    end

    assign XATAO = IOMUXFF;
    assign XDACK = DTACK==1||(XDREQ&&XWR);

    assign BOARD_IRQ = IREQ^IACK;
    
    assign XIRQ = |BOARD_IRQ;
    
`ifndef __TESTMODE__
    assign LED = LEDFF;
`endif
    assign OPORT = OPORTFF;

    // darkuart

    wire [3:0] UDEBUG;

    darkuart
    uart0
    (
      .CLK(CLK),
      .RES(RES),
      .RD(!HLT && XRD && XDREQ && XADDR[4:2]==1),
      .WR(!HLT && XWR && XDREQ && XADDR[4:2]==1),
`ifdef __BIG__
      .BE({XBE[0],XBE[1],XBE[2],XBE[3]}),
      .DATAI({XATAI[7:0],XATAI[15:8],XATAI[23:16],XATAI[31:24]}),
      .DATAO({UDATA[7:0],UDATA[15:8],UDATA[23:16],UDATA[31:24]}),
`else
      .BE(XBE),
      .DATAI(XATAI),
      .DATAO(UDATA),
`endif
      //.IRQ(UART_IRQ),

`ifndef __TESTMODE__
      .RXD(RXD),
      .TXD(TXD),
`endif		
`ifdef SIMULATION
      .ESIMREQ(ESIMREQ),
      .ESIMACK(ESIMACK),
`endif
      .DEBUG(UDEBUG)
    );

`ifdef SPI
    // darkspi

    wire [3:0] SDEBUG;

    darkspi
    #(.DIV_COEF(SPI_DIV_COEF))
    spi0
    (
      .CLK(CLK),
      .RES(RES),
      .RD(!HLT && XRD && XDREQ && XADDR[4:2]==7),
      .WR(!HLT && XWR && XDREQ && XADDR[4:2]==7),
      .BE(XBE),
      .DATAI(XATAI),
      .DATAO(SDATA),
      //.IRQ(SPI_IRQ),

      .CSN(CSN),        // SPI CSN output (active LOW)
      .SCK(SCK),        // SPI clock output
      .MOSI(MOSI),      // SPI master data output, slave data input
      .MISO(MISO),      // SPI master data input, slave data output

`ifdef SIMULATION
//      .ESIMREQ(ESIMREQ),
      .ESIMACK(ESIMACK),
`endif
      .DEBUG(SDEBUG)
    );
`endif

    assign DEBUG = { XDREQ,XRD,XWR,XDACK };

endmodule
