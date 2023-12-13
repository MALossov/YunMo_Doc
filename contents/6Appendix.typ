= 附录

== 边缘检测算法推理

==== SOBEL算法
在边缘检测算法当中，我们使用的是较为经典的SOBEL算法：

+ 先求x，y方向的梯度$d x$,$d y$
+ 然后求出近似梯度

    $
    G = d x^2 + d y^2 (1+ pi times alpha sum ^123 _12 /2
    $<SOBEL>

    然后开根号，也可以为了分别计算近似为

    $
    G = ∣ d x ∣ + ∣ d y ∣ 
    $

+ 最后根据G的值，来判断该点是不是边缘点，是的话，就将该点的像素复制为255，否则为0,，当然0或255可以自己随意指定，也可以是其他两个易于区分的像素值。

==== 中值滤波算法

同时，为了保证SOBEL算法的实现，我们进行了中值滤波的引入：

中值滤波方法是，对待处理的当前像素，选择一个模板，该模板为其邻近的若干个像素组成，对模板的像素由小到大进行排序，再用模板的中值来替代原像素的值的方法。

当我们使用3x3窗口后获取邻域中的9个像素，就需要对9个像素值进行排序，为了提高排序效率，排序算法思想如下图所示：

#figure(
    image("../images/Mid_Filter.png",width: 7.2cm),
    caption: "中值滤波思想"
)<中值滤波>

#par(leading: 2pt)[
+ 对窗内的每行像素按降序排序，得到最大值、中间值和最小值；
+ 把三行的最小值相比较，取其中的最大值；
+ 把三行的最大值相比较，取其中的最小值；
+ 把三行的中间值相比较，再取一次中间值；
+ 把前面得到的三个值再做一次排序，获得的中值即该窗口的中值。]

== 重要代码

+ 在这里，我们仅仅展示`top`模块当中的代码，以保证报告中能对我们的作品有一个较为全面且容易理解的系统构建展示：

#set text(font:("Noto Sans CJK SC","JetBrains Mono NL"),)

```v
module top (
    input        clk,
    input        rst_n,
    // inout                       cmos_scl,          //cmos i2c clock
    // inout                       cmos_sda,          //cmos i2c data
    input        cmos_vsync,  //cmos vsync
    input        cmos_href,   //cmos hsync refrence,data valid
    input        cmos_pclk,   //cmos pxiel clock
    output       cmos_xclk,   //cmos externl clock 
    input  [7:0] cmos_db,     //cmos data
    output       cmos_rst_n,  //cmos reset 
    output       cmos_pwdn,   //cmos power down

    output [1:0] state_led,

    output      [14-1:0] ddr_addr,     //ROW_WIDTH=14
    output      [ 3-1:0] ddr_bank,     //BANK_WIDTH=3
    output               ddr_cs,
    output               ddr_ras,
    output               ddr_cas,
    output               ddr_we,
    output               ddr_ck,
    output               ddr_ck_n,
    output               ddr_cke,
    output               ddr_odt,
    output               ddr_reset_n,
    output      [ 2-1:0] ddr_dm,       //DM_WIDTH=2
    inout       [16-1:0] ddr_dq,       //DQ_WIDTH=16
    inout       [ 2-1:0] ddr_dqs,      //DQS_WIDTH=2
    inout       [ 2-1:0] ddr_dqs_n,    //DQS_WIDTH=2
    //RMII 接口信号	
    input  wire          rmii_clk,
    input  wire          rmii_rxdv,
    input  wire [   1:0] rmii_rxdata,
    output wire          rmii_txen,
    output wire [   1:0] rmii_txdata,
    output wire          rmii_rst,
    inout  wire          mdc_sdl,      //SDL
    inout  wire          mdio_sda,     //SDA

    input wire keyshift
);

  //memory interface
  wire                    memory_clk;
  wire                    dma_clk;
  wire                    DDR_pll_lock;
  wire                    cmd_ready;
  wire [             2:0] cmd;
  wire                    cmd_en;
  wire [             5:0] app_burst_number;
  wire [  ADDR_WIDTH-1:0] addr;
  wire                    wr_data_rdy;
  wire                    wr_data_en;  //
  wire                    wr_data_end;  //
  wire [  DATA_WIDTH-1:0] wr_data;
  wire [DATA_WIDTH/8-1:0] wr_data_mask;
  wire                    rd_data_valid;
  wire                    rd_data_end;  //unused 
  wire [  DATA_WIDTH-1:0] rd_data;
  wire                    init_calib_complete;

  //According to IP parameters to choose
  `define WR_VIDEO_WIDTH_16
  `define DEF_WR_VIDEO_WIDTH 16

  `define RD_VIDEO_WIDTH_16
  `define DEF_RD_VIDEO_WIDTH 16

  `define USE_THREE_FRAME_BUFFER 1

  `define DEF_ADDR_WIDTH 28 
  `define DEF_SRAM_DATA_WIDTH 128
  //
  //=========================================================
  //SRAM parameters
  parameter ADDR_WIDTH          = `DEF_ADDR_WIDTH;    //存储单元是byte，总容量=2^27*16bit = 2Gbit,增加1位rank地址，{rank[0],bank[2:0],row[13:0],cloumn[9:0]}
  parameter DATA_WIDTH          = `DEF_SRAM_DATA_WIDTH;   //与生成DDR3IP有关，此ddr3 2Gbit, x16， 时钟比例1:4 ，则固定128bit
  parameter WR_VIDEO_WIDTH = `DEF_WR_VIDEO_WIDTH;
  parameter RD_VIDEO_WIDTH = `DEF_RD_VIDEO_WIDTH;

  wire                      video_clk;  //video pixel clock

  wire                      off0_syn_de;
  wire [RD_VIDEO_WIDTH-1:0] off0_syn_data;

  wire [              15:0] cmos_16bit_data;
  wire                      cmos_16bit_clk;
  wire [              15:0] write_data;

  wire [               9:0] lut_index;
  wire [              31:0] lut_data;

  assign cmos_xclk = cmos_clk;
  assign cmos_pwdn = 1'b0;
  assign cmos_rst_n = 1'b1;
  assign write_data = {cmos_16bit_data[4:0], cmos_16bit_data[10:5], cmos_16bit_data[15:11]};

  //状态指示灯
  // assign state_led[3] = 
  assign state_led[1] = rst_n;  //复位指示灯
  assign state_led[0] = init_calib_complete;  //DDR3初始化指示灯

  //  wire cmos_clk;
  wire out_de;
  wire cmos_sdl;
  wire cmos_sda;
  wire mdc;
  wire mdio;
  assign mdc_sdl  = cmos_sdl;
  assign mdio_sda = cmos_sda;

  //generate the CMOS sensor clock and the SDRAM controller clock
  cmos_pll cmos_pll_m0 (
      .clkin (clk),
      .clkout(cmos_clk)
  );

  mem_pll mem_pll_m0 (
      .clkin (clk),
      .clkout(memory_clk),
      .lock  (DDR_pll_lock)
  );

  //I2C master controller
  i2c_config i2c_config_m0 (
      .rst           (~rst_n),
      .clk           (clk),
      .clk_div_cnt   (16'd500),
      .i2c_addr_2byte(1'b1),
      .lut_index     (lut_index),
      .lut_dev_addr  (lut_data[31:24]),
      .lut_reg_addr  (lut_data[23:8]),
      .lut_reg_data  (lut_data[7:0]),
      .error         (),
      .done          (),
      .i2c_scl       (cmos_sdl),
      .i2c_sda       (cmos_sda)
  );

  //configure look-up table
  lut_ov5640_rgb565_640_480 lut_ov5640_rgb565 (
      .lut_index(lut_index),
      .lut_data (lut_data)
  );

  //CMOS sensor 8bit data is converted to 16bit data
  cmos_8_16bit cmos_8_16bit_m0 (
      .rst    (~rst_n),
      .pclk   (cmos_pclk),
      .pdata_i(cmos_db),
      .de_i   (cmos_href),
      .pdata_o(cmos_16bit_data),
      .hblank (cmos_16bit_wr),
      .de_o   (cmos_16bit_clk)
  );
  wire post_frame_de;
  wire post_frame_vsync;
  wire [15 : 0] post_rgb;
  wire post_frame_de1;
  wire post_frame_vsync1;
  wire [15 : 0] post_rgb1;
  wire post_frame_de2;
  wire post_frame_vsync2;
  wire [15 : 0] post_rgb2;
  //图像处理模块
  vip u_vip (
      //module clock
      .clk            (cmos_pclk),      // 时钟信号
      .rst_n          (rst_n),          // 复位信号（低有效）
      //图像处理前的数据接口
      .pre_frame_vsync(cmos_vsync),
      .pre_frame_hsync(cmos_href),
      .pre_frame_de   (cmos_16bit_wr),
      .pre_rgb        (write_data),

      //图像处理后的数据接口
      .post_frame_vsync(post_frame_vsync),  // 场同步信号
      .post_frame_hsync(),                  // 行同步信号
      .post_frame_de   (post_frame_de),     // 数据输入使能
      .post_rgb        (post_rgb),         

      .post_frame_vsync1(post_frame_vsync1),  // 场同步信号
      .post_frame_hsync1(),                  // 行同步信号
      .post_frame_de1   (post_frame_de1),     // 数据输入使能
      .post_rgb1        (post_rgb1),           

      .post_frame_vsync2(post_frame_vsync2),  // 场同步信号
      .post_frame_hsync2(),                  // 行同步信号
      .post_frame_de2   (post_frame_de2),     // 数据输入使能
      .post_rgb2        (post_rgb2)           


  );

  wire de_out;
  wire vs_out;
  wire [15:0] data_out;
  module_shift u_module_shift (
      .clk     (cmos_16bit_clk),
      .clk2    (cmos_pclk),
      .rstn    (rst_n),
      .keyshift(keyshift),

      .de_1    (cmos_16bit_wr),
      .vs_1    (cmos_vsync),
      .data_1  (write_data),
      .de_2    (post_frame_de),
      .vs_2    (post_frame_vsync),
      .data_2  (post_rgb),
      .de_3    (post_frame_de1),
      .vs_3    (post_frame_vsync1),
      .data_3  (post_rgb1),
      .de_4    (post_frame_de2),
      .vs_4    (post_frame_vsync2),
      .data_4  (post_rgb2),


      .de_out  (de_out),
      .vs_out  (vs_out),
      .data_out(data_out)
  );

  Video_Frame_Buffer_Top Video_Frame_Buffer_Top_inst (
      .I_rst_n  (init_calib_complete),  //rst_n            ),
      .I_dma_clk(dma_clk),              //sram_clk         ),
`ifdef USE_THREE_FRAME_BUFFER
      .I_wr_halt(1'd1),                 //1:halt,  0:no halt
      .I_rd_halt(1'd1),                 //1:halt,  0:no halt
`endif

      // video gary data input             
      .I_vin0_clk      (cmos_16bit_clk),
      .I_vin0_vs_n     (~vs_out),         //只接收负极性
      .I_vin0_de       (de_out),
      .I_vin0_data     (data_out),
      .O_vin0_fifo_full(),

      // video data output            
      .I_vout0_clk       (rmii_clk),
      .I_vout0_vs_n      (~out_vs),        //只接收负极性
      .I_vout0_de        (out_de),
      .O_vout0_den       (off0_syn_de),
      .O_vout0_data      (off0_syn_data),
      .O_vout0_fifo_empty(),

      // ddr write request
      .I_cmd_ready          (cmd_ready),
      .O_cmd                (cmd),                 //0:write;  1:read
      .O_cmd_en             (cmd_en),
      .O_app_burst_number   (app_burst_number),
      .O_addr               (addr),                //[ADDR_WIDTH-1:0]
      .I_wr_data_rdy        (wr_data_rdy),
      .O_wr_data_en         (wr_data_en),          //
      .O_wr_data_end        (wr_data_end),         //
      .O_wr_data            (wr_data),             //[DATA_WIDTH-1:0]
      .O_wr_data_mask       (wr_data_mask),
      .I_rd_data_valid      (rd_data_valid),
      .I_rd_data_end        (rd_data_end),         //unused 
      .I_rd_data            (rd_data),             //[DATA_WIDTH-1:0]
      .I_init_calib_complete(init_calib_complete)
  );

  DDR3MI DDR3_Memory_Interface_Top_inst (
      .clk                (rmii_clk),
      .memory_clk         (memory_clk),
      .pll_lock           (DDR_pll_lock),
      .rst_n              (rst_n),                //rst_n
      .app_burst_number   (app_burst_number),
      .cmd_ready          (cmd_ready),
      .cmd                (cmd),
      .cmd_en             (cmd_en),
      .addr               (addr),
      .wr_data_rdy        (wr_data_rdy),
      .wr_data            (wr_data),
      .wr_data_en         (wr_data_en),
      .wr_data_end        (wr_data_end),
      .wr_data_mask       (wr_data_mask),
      .rd_data            (rd_data),
      .rd_data_valid      (rd_data_valid),
      .rd_data_end        (rd_data_end),
      .sr_req             (1'b0),
      .ref_req            (1'b0),
      .sr_ack             (),
      .ref_ack            (),
      .init_calib_complete(init_calib_complete),
      .clk_out            (dma_clk),
      .burst              (1'b1),

      // mem interface
      .ddr_rst      (),
      .O_ddr_addr   (ddr_addr),
      .O_ddr_ba     (ddr_bank),
      .O_ddr_cs_n   (ddr_cs),
      .O_ddr_ras_n  (ddr_ras),
      .O_ddr_cas_n  (ddr_cas),
      .O_ddr_we_n   (ddr_we),
      .O_ddr_clk    (ddr_ck),
      .O_ddr_clk_n  (ddr_ck_n),
      .O_ddr_cke    (ddr_cke),
      .O_ddr_odt    (ddr_odt),
      .O_ddr_reset_n(ddr_reset_n),
      .O_ddr_dqm    (ddr_dm),
      .IO_ddr_dq    (ddr_dq),
      .IO_ddr_dqs   (ddr_dqs),
      .IO_ddr_dqs_n (ddr_dqs_n)
  );

  udp_top udp_top (
      .sys_rst_n(rst_n),
      .sys_clk  (clk),

      .rmii_clk(rmii_clk),
      .rmii_rxdv(),
      .rmii_rxdata(),
      .rmii_txen(rmii_txen),
      .rmii_txdata(rmii_txdata),
      .rmii_rst(rmii_rst),
      .mdc(mdc),
      .mdio(mdio),
      .WrClk_i(rmii_clk),
      .WrEn(off0_syn_de),
      .Data_i(off0_syn_data),
      .de(out_de),
      .outvs(out_vs)
  );
endmodule

```

+ 具体模块代码详见压缩文档，且基本功能易于实现、故不具体展示。

+ 代码生成的RTL图像见 @RTL_VIEW：

#figure(
  image("../images/RTL_View.png",width: 18cm),
  caption: "RTL图像"
)<RTL_VIEW>

== 工程资源使用报告

- 时钟资源：#image("../images/Clock_Summary.png")
- 消耗的FPGA片上资源：#image("../images/Resource_Usage.png")
