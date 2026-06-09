//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + per-pin push-pull mask, USER_IO widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driven by wrapper; USER_OUT driven by joydb (USER_OUT_DRIVE) below
assign USER_PP  = USER_PP_DRIVE;
assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

assign LED_USER  = ioctl_download;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];
// SNAC cores: replace 1'b0 with the core's SNAC enable expression so SNAC
// preempts the joydb wrapper on shared USER_IO pins. Default 1'b0 is no-op.
wire         snac_active     = 1'b0;
// MT32-pi cores on primary USER_IO: replace 1'b0 with the core's MT32-active
// expression. No MT32-pi on this arcade core, so left at 1'b0.
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire  [15:0] joy_raw_payload;

// [MiSTer-DB9 BEGIN] - DB9 programmable-remap matrix wires
// joydb_*_mapped = MiSTer-standard joystick words (consumed in Layer B);
// db9_remap_* = 0xFD selector stream driven by the hps_io instance.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .joy_raw         ( joy_raw_payload )
);
// [MiSTer-DB9 END]

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd282 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd241 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.INFERNO;;",
	"-;",
	"H0O[9:8],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[5:3],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O[13],Aim+Fire,Off,On;",
	"-;",
	"P1,Pause options;",
	"P1O[25],Pause when OSD is open,On,Off;",
	"P1O[26],Dim video after 10s,On,Off;",
	"-;",
	"O[27],Autosave Hiscores,Off,On;",
	"-;",
	"O[10],Advance,Off,On;",
	"O[11],Auto Up,Off,On;",
	"O[12],High Score Reset,Off,On;",
	"-;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players, 1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"-;",
	"R0,Reset;",
	"J1,Trigger,Start,Coin,Aim Up,Aim Down,Aim Left,Aim Right,Pause;",
	"jn,R,Start,Select,X,B,Y,A,L;",
	"V,v",`BUILD_DATE
};

wire         forced_scandoubler;
wire         direct_video;
wire [ 21:0] gamma_bus;

wire         ioctl_download;
wire         ioctl_upload;
wire         ioctl_upload_req;
wire         ioctl_wr;
wire [ 24:0] ioctl_addr;
wire [  7:0] ioctl_dout;
wire [  7:0] ioctl_din;
wire [ 15:0] ioctl_index;

wire [  1:0] buttons;
wire [127:0] status;
wire [ 10:0] ps2_key;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: rename USB joystick wires
wire [ 31:0] joystick_0_USB, joystick_1_USB;
// [MiSTer-DB9 END]
wire [ 15:0] joystick_l_analog_0, joystick_l_analog_1;
wire [ 15:0] joystick_r_analog_0, joystick_r_analog_1;

// [MiSTer-DB9-Pro BEGIN] - DB controllers muted while OSD is open; remap to Inferno layout
// Inferno standard joystick bit order (from CONF_STR J1,Trigger,Start,Coin,Aim Up,Aim Down,Aim Left,Aim Right,Pause):
//   [3:0]=Run UDLR  [4]=Trigger  [5]=Start  [6]=Coin
//   [7]=Aim Up  [8]=Aim Down  [9]=Aim Left  [10]=Aim Right  [11]=Pause
// joydb raw word (Genesis/Saturn pad): [3:0]=UDLR [4]=B [5]=C [6]=A [7]=Start [8]=Mode [9]=X [10]=Y [11]=Z
// Best-effort digital map for a fundamentally dual-49-way-stick game (NEEDS-HUMAN-REVIEW):
//   Run stick   <- pad D-pad [3:0]
//   Trigger     <- B   (joydb_1[4])
//   Start       <- Start (joydb_1[7])
//   Coin        <- Mode/Select (joydb_1[8])
//   Aim Up      <- A   (joydb_1[6])
//   Aim Down    <- C   (joydb_1[5])
//   Aim Left    <- X   (joydb_1[9])  (6-button only)
//   Aim Right   <- Y   (joydb_1[10]) (6-button only)
//   Pause       <- Z   (joydb_1[11]) (6-button only)
wire [31:0] joystick_0 = joydb_1ena ? (OSD_STATUS ? 32'b0 : joydb_1_mapped[11:0]) : joystick_0_USB;
wire [31:0] joystick_1 = joydb_2ena ? (OSD_STATUS ? 32'b0 : joydb_2_mapped[11:0]) : joydb_1ena ? joystick_0_USB : joystick_1_USB;
// [MiSTer-DB9-Pro END]

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0_USB),
	.joystick_1(joystick_1_USB),
	.joystick_l_analog_0(joystick_l_analog_0),
	.joystick_l_analog_1(joystick_l_analog_1),
	.joystick_r_analog_0(joystick_r_analog_0),
	.joystick_r_analog_1(joystick_r_analog_1),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw
	.joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
	// programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
	.db9_remap_cmd(db9_remap_cmd),
	.db9_remap_byte_cnt(db9_remap_byte_cnt),
	.db9_remap_din(db9_remap_din),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire pll_locked;
wire clk_48, clk_12;
assign clk_sys = clk_12;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_48),
	.outclk_1(clk_12),
	.locked(pll_locked)
);

wire reset = RESET | status[0] | buttons[1];

///////////////////////   INPUTS    ///////////////////////////////

logic [3:0] joyal_1, joyal_2, joyar_1, joyar_2;
logic [3:0] joy_run_1, joy_run_2, joy_aim_1, joy_aim_2;

always_comb begin
		joyal_1[3] = ($signed(joystick_l_analog_0[15:8]) < -20); // Up
		joyal_1[2] = ($signed(joystick_l_analog_0[15:8]) >  20); // Down
		joyal_1[1] = ($signed(joystick_l_analog_0[ 7:0]) < -20); // Left
		joyal_1[0] = ($signed(joystick_l_analog_0[ 7:0]) >  20); // Right

		joyar_1[3] = ($signed(joystick_r_analog_0[15:8]) < -20);
		joyar_1[2] = ($signed(joystick_r_analog_0[15:8]) >  20);
		joyar_1[1] = ($signed(joystick_r_analog_0[ 7:0]) < -20);
		joyar_1[0] = ($signed(joystick_r_analog_0[ 7:0]) >  20);

		joyal_2[3] = ($signed(joystick_l_analog_1[15:8]) < -20);
		joyal_2[2] = ($signed(joystick_l_analog_1[15:8]) >  20);
		joyal_2[1] = ($signed(joystick_l_analog_1[ 7:0]) < -20);
		joyal_2[0] = ($signed(joystick_l_analog_1[ 7:0]) >  20);

		joyar_2[3] = ($signed(joystick_r_analog_1[15:8]) < -20);
		joyar_2[2] = ($signed(joystick_r_analog_1[15:8]) >  20);
		joyar_2[1] = ($signed(joystick_r_analog_1[ 7:0]) < -20);
		joyar_2[0] = ($signed(joystick_r_analog_1[ 7:0]) >  20);
end

always_ff @(posedge clk_48) begin
	if (joyal_1) begin
		joy_run_1[3] <= (joyal_1[3] && joyal_1[0]); // Up-Right
		joy_run_1[2] <= (joyal_1[2] && joyal_1[1]); // Down-Left
		joy_run_1[1] <= (joyal_1[3] && joyal_1[1]); // Up-Left
		joy_run_1[0] <= (joyal_1[2] && joyal_1[0]); // Down-Right
	end else begin
		joy_run_1[3] <= joystick_0[3];
		joy_run_1[2] <= joystick_0[2];
		joy_run_1[1] <= joystick_0[1];
		joy_run_1[0] <= joystick_0[0];
	end
	if (joyal_2) begin
		joy_run_2[3] <= (joyal_2[3] && joyal_2[0]);
		joy_run_2[2] <= (joyal_2[2] && joyal_2[1]);
		joy_run_2[1] <= (joyal_2[3] && joyal_2[1]);
		joy_run_2[0] <= (joyal_2[2] && joyal_2[0]);
	end else begin
		joy_run_2[3] <= joystick_1[3];
		joy_run_2[2] <= joystick_1[2];
		joy_run_2[1] <= joystick_1[1];
		joy_run_2[0] <= joystick_1[0];
	end
end

always_comb begin
	joy_aim_1[3] <= ((joyar_1[3] && joyar_1[0]) | joystick_0[7] ); // X
	joy_aim_1[2] <= ((joyar_1[2] && joyar_1[1]) | joystick_0[8] ); // B
	joy_aim_1[1] <= ((joyar_1[3] && joyar_1[1]) | joystick_0[9] ); // Y
	joy_aim_1[0] <= ((joyar_1[2] && joyar_1[0]) | joystick_0[10]); // A

	joy_aim_2[3] <= ((joyar_2[3] && joyar_2[0]) | joystick_1[7] );
	joy_aim_2[2] <= ((joyar_2[2] && joyar_2[1]) | joystick_1[8] );
	joy_aim_2[1] <= ((joyar_2[3] && joyar_2[1]) | joystick_1[9] );
	joy_aim_2[0] <= ((joyar_2[2] && joyar_2[0]) | joystick_1[10]);
end

// These may look out of order, they are correct though (2,0,1,3)
logic [3:0] btn_run_1, btn_aim_1, btn_run_2, btn_aim_2;
assign btn_run_1 = {joy_run_1[2], joy_run_1[0], joy_run_1[1], joy_run_1[3]};
assign btn_run_2 = {joy_run_2[2], joy_run_2[0], joy_run_2[1], joy_run_2[3]};
assign btn_aim_1 = {joy_aim_1[2], joy_aim_1[0], joy_aim_1[1], joy_aim_1[3]};
assign btn_aim_2 = {joy_aim_2[2], joy_aim_2[0], joy_aim_2[1], joy_aim_2[3]};

logic btn_aimfire_1, btn_aimfire_2;
always_ff @(posedge clk_12) begin
	btn_aimfire_1 <= 0;
	btn_aimfire_2 <= 0;
	if (btn_aim_1[3] | btn_aim_1[2] | btn_aim_1[1] | btn_aim_1[0]) btn_aimfire_1 <= 1;
	if (btn_aim_2[3] | btn_aim_2[2] | btn_aim_2[1] | btn_aim_2[0]) btn_aimfire_2 <= 1;
end

logic aimfire, btn_trigger_1, btn_trigger_2, btn_start_1, btn_start_2, btn_coin, btn_pause;
assign aimfire = status[13];
assign btn_trigger_1 = aimfire ? btn_aimfire_1 : joystick_0[4];
assign btn_trigger_2 = aimfire ? btn_aimfire_2 : joystick_1[4];
assign btn_start_1   = joystick_0[5];
assign btn_start_2   = joystick_1[5];
assign btn_coin      = joystick_0[6]  | joystick_1[6];
assign btn_pause     = joystick_0[11] | joystick_1[11];

///////////////////////   DISPLAY   ///////////////////////////////

logic hblank, vblank;
logic hs, vs;
logic ce_pix;

always @(posedge clk_48) begin
	logic [2:0] div;
	div <= div + 1'd1;
	ce_pix <= !div;
end

logic [3:0] r,g,b,intensity;
logic [7:0] ri,gi,bi;
logic [7:0] color_lut[256] = '{
    8'd19, 8'd21, 8'd23,  8'd25,  8'd26,  8'd29,  8'd32,  8'd35,  8'd38,  8'd43,  8'd49,  8'd56,  8'd65,  8'd76,  8'd96,  8'd108,
    8'd21, 8'd22, 8'd24,  8'd26,  8'd28,  8'd30,  8'd34,  8'd37,  8'd40,  8'd45,  8'd52,  8'd59,  8'd68,  8'd80,  8'd101, 8'd114,
    8'd22, 8'd24, 8'd26,  8'd28,  8'd30,  8'd33,  8'd36,  8'd39,  8'd43,  8'd48,  8'd55,  8'd63,  8'd73,  8'd86,  8'd107, 8'd121,
    8'd24, 8'd25, 8'd27,  8'd29,  8'd32,  8'd35,  8'd38,  8'd42,  8'd46,  8'd52,  8'd59,  8'd67,  8'd77,  8'd91,  8'd114, 8'd129,
    8'd25, 8'd27, 8'd29,  8'd31,  8'd34,  8'd37,  8'd40,  8'd45,  8'd48,  8'd54,  8'd62,  8'd71,  8'd81,  8'd96,  8'd121, 8'd137,
    8'd27, 8'd28, 8'd31,  8'd34,  8'd36,  8'd39,  8'd44,  8'd48,  8'd52,  8'd58,  8'd66,  8'd76,  8'd87,  8'd103, 8'd129, 8'd146,
    8'd29, 8'd31, 8'd34,  8'd36,  8'd39,  8'd43,  8'd47,  8'd52,  8'd56,  8'd63,  8'd72,  8'd82,  8'd94,  8'd111, 8'd140, 8'd158,
    8'd32, 8'd34, 8'd37,  8'd39,  8'd43,  8'd46,  8'd51,  8'd56,  8'd61,  8'd68,  8'd78,  8'd89,  8'd102, 8'd120, 8'd151, 8'd171,
    8'd32, 8'd35, 8'd38,  8'd41,  8'd44,  8'd48,  8'd53,  8'd59,  8'd64,  8'd72,  8'd83,  8'd94,  8'd109, 8'd129, 8'd161, 8'd182,
    8'd36, 8'd38, 8'd42,  8'd45,  8'd48,  8'd53,  8'd59,  8'd65,  8'd70,  8'd79,  8'd90,  8'd104, 8'd119, 8'd141, 8'd177, 8'd201,
    8'd40, 8'd43, 8'd46,  8'd50,  8'd54,  8'd59,  8'd65,  8'd72,  8'd79,  8'd88,  8'd101, 8'd115, 8'd133, 8'd157, 8'd198, 8'd224,
    8'd45, 8'd48, 8'd52,  8'd57,  8'd61,  8'd66,  8'd74,  8'd81,  8'd88,  8'd98,  8'd113, 8'd129, 8'd149, 8'd176, 8'd221, 8'd249,
    8'd50, 8'd54, 8'd58,  8'd64,  8'd68,  8'd75,  8'd83,  8'd91,  8'd99,  8'd111, 8'd128, 8'd146, 8'd169, 8'd200, 8'd249, 8'd253,
    8'd58, 8'd63, 8'd68,  8'd74,  8'd79,  8'd87,  8'd96,  8'd106, 8'd116, 8'd129, 8'd148, 8'd169, 8'd195, 8'd231, 8'd253, 8'd254,
    8'd71, 8'd76, 8'd83,  8'd89,  8'd96,  8'd105, 8'd116, 8'd128, 8'd139, 8'd156, 8'd179, 8'd205, 8'd236, 8'd252, 8'd254, 8'd254,
    8'd91, 8'd97, 8'd105, 8'd114, 8'd123, 8'd133, 8'd147, 8'd161, 8'd176, 8'd196, 8'd223, 8'd249, 8'd252, 8'd254, 8'd254, 8'd255
};

always_ff @(posedge clk_48) begin : colorPalette
    ri = ~| intensity ? 8'd0 : color_lut[{r, intensity}];
    gi = ~| intensity ? 8'd0 : color_lut[{g, intensity}];
    bi = ~| intensity ? 8'd0 : color_lut[{b, intensity}];
end : colorPalette

// Pause functionality
wire [23:0] pause_rgb;
wire pause_cpu_pause;
wire pause_cpu_nvram;
wire pause_cpu = pause_cpu_pause | pause_cpu_nvram;

pause #(8,8,8,12) pause
(
	.clk_sys(clk_12),
	.reset(reset),
	.user_button(btn_pause),
	.pause_request(pause_cpu_nvram), // Pause request from nvram module
	.options(~status[26:25]),
	.OSD_STATUS(OSD_STATUS),
	.r(ri),
	.g(gi),
	.b(bi),
	.pause_cpu(pause_cpu_pause),
	.rgb_out(pause_rgb)
);

// NVRAM (High Score) functionality  
wire [9:0] nvram_address;
wire [3:0] nvram_data_4bit;  // 4-bit data from CMOS RAM
wire [7:0] nvram_data_out;   // 8-bit data for nvram module

// Convert 4-bit CMOS data to 8-bit by padding with zeros
assign nvram_data_out = {4'b0000, nvram_data_4bit};

nvram #(10,3,4,2) nvram
(
	.clk(clk_12),
	.paused(pause_cpu),
	.reset(reset),
	.autosave(status[27]),

	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_index(ioctl_index),
	.ioctl_din(ioctl_din),
	.ioctl_dout(ioctl_dout),
	.OSD_STATUS(OSD_STATUS),

	.nvram_address(nvram_address),
	.nvram_data_out(nvram_data_out),

	.pause_cpu(pause_cpu_nvram)
);

arcade_video #(313,24,1) arcade_video
(
	.*,
	.clk_video(clk_48),

	.RGB_in(pause_rgb),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),
	.fx(status[5:3])
);

wire [7:0] audio;
assign AUDIO_L = {audio, 6'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

///////////////////////    CORE    ///////////////////////////////

williams2 williams2
(
	.clock_12(clk_sys),
	.reset(reset),
	.pause_cpu(pause_cpu),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_i(intensity),
	.video_hblank(hblank), // 48 <-> 1
	.video_vblank(vblank), // 504 <-> 262
	.video_hs(hs),
	.video_vs(vs),

	.audio_out(audio),

	.btn_advance(status[10]),
	.btn_auto_up(status[11]),
	.btn_high_score_reset(status[12]),

	.btn_trigger_1(btn_trigger_1),
	.btn_trigger_2(btn_trigger_2),
	.btn_start_1(btn_start_1),
	.btn_start_2(btn_start_2),
	.btn_coin(btn_coin),

	.btn_run_1(btn_run_1),
	.btn_run_2(btn_run_2),
	.btn_aim_1(btn_aim_1),
	.btn_aim_2(btn_aim_2),

	.sw_coktail_table(),
	.seven_seg(),

	.dbg_out(),

	.dn_addr(ioctl_addr[17:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && (ioctl_index==0 || ioctl_index==4)),
	.dn_index(ioctl_index),

	// NVRAM interface
	.nvram_addr(nvram_address),
	.nvram_data_out(nvram_data_4bit)
);

endmodule
