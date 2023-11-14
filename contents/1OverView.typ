= 设计概述

== 设计目的

我们的作品 *云MO监控* 对应的赛题为：*基于高云 FPGA 的网络视频监控系统*，因此，我们的首要目标在于充分发挥`Sipeed Tang Primer 20K`板卡的性能和资源，构建一能够迎合满足赛题需求、同时致力创新发挥，实现较为优秀的网络视频监控系统。我们主要着力于：

+ *以太网发送*：利用底板RMii网卡芯片实现UDP以太网传输
+ *摄像头适配*：利用OV5640实现视频采集
+ *视频处理*：使用高云软核+自主编写Video Processing模块实现

== 应用领域
云MO监控系统具有广泛的应用领域，能够通过通过配套使用兼容的镜头模块、同时通过配置CMOS寄存器，能够达到不同的 *画幅、视角区域* ，*具有较为良好的视角可定制性*。能够灵活 *适用于各类监控场景*。包括但不局限于：家庭安防（一般画幅、分辨能力）、商业区域监控（广画幅、低分辨能力）、仓库管理监控（窄画幅、高分辨能力）等。

同时，云MO监控系统突出了其独特的 *“云墨模式”* 特点。通过巧妙地结合板卡处理，系统能够通过仅保留视频灰度，巧妙地压缩数据，从而提高了网络传输效率和容错能力，优化了监控图像的流畅度。这一创新特点将监控系统的性能提升与数据传输的高可靠性相结合，同时能够借此实现二值化、边缘检测等，能够较好地 *适应光纤较弱*、画面干扰较大等情况的时候，仍能通过板卡自主判断、获取可靠的物品信息。因此，也可以用在特种作业、暗光环境等场所。

== 主要技术特点

云MO监控系统的技术特点体现在多个方面。
+ 首先，系统利用高云FPGA板卡实现了高性能视频采集+摄像头寄存器高度定制化，能够追踪特定场景、配置相应参数，确保监控图像质量。
+ 其次，通过支持多路摄像头接入，系统提供了更丰富的监控视角和更全面的场景覆盖。同时，我们不仅在理论支撑中可以通过座子复用、开关切换的方式进行视角的切换；同时，也通过完整的UDP网络协议实现，让单终端能够通过上位机设置同时访问不同的视角。
+ 再次，在网络传输方面，支持通用RJ45百兆网口，使得数据传输更为迅速和可靠。同时技术成熟、并且帧率达到了该接口条件下的较高水平_（稳定在19fps）_。
+ 最后，在数据处理方面，系统实现了“云墨模式”，能够将图片进行二值化、灰度处理、基本人体识别、边缘检测等，同时应用中值滤波软核等方式、实现了对数据的高度精准和有效处理，为用户提供了更为清晰和有用的监控信息。

== 关键性能指标

在关键性能指标部分，为服务于上述设计目的等内容，我们最终实现如下性能指标：

+ *20fps* 视频传输，在使用CMOS原神5-6-5 $R G B$ 进行颜色发送时，能够具有较好、稳定的流畅度。
+ *标准VGA清晰度* 实现了基于标准$640 times 480$ 分辨率的帧结构
+ *多上位机画面接收* 通过完整的UDP协议和底层协议支持，能够在单个终端当中，实现多画幅接收，借助多下位机实现多路收发。
+ *满速百兆以太网*： 能够通过满速的百兆以太网进行数据图像传输。



== 主要创新点

+ *在底层实现完整的ARP+UDP协议、自动网络链路获取*，支持自由收发，可以通过多上位机和地址设置实现多摄像头同时工作、显示实现。
+ *基本图像处理*，自行构建图像处理接口软核，使用标准的vga传输时序对于图像处理的过程进行封装，能够较好地添加、删改新的软核；并加入按键状态机进入模式切换。
+ *通用滤波模块*：提供通用的滤波、减少资源消耗，实现较好的二值化、边缘识别等图像处理效果。
+ *单键操作*： 使用单按键加状态机进行模式切换，增加易用性、减少操作难度。
