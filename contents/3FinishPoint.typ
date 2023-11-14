= 完成情况及性能参数

我们将赛题对于性能指标的基础和扩展要求、结合我们自身对于项目的理解分列的条目进行整合，并且列表见@tb_is_ok：

#figure(
table(columns:(auto,auto,40pt,auto),
align: horizon,
[*项目名称*],[*实现情况*],[*是否完成*],[*指标详情*],
[*使用高云FPGA板卡*],[使用板卡为：_#link("https://wiki.sipeed.com/hardware/zh/tang/tang-primer-20k/primer-20k.html")[Tang Primer 20K]_],[$checkmark$],[*高云FPGA* ( _#link("http://www.gowinsemi.com.cn/prod_view.aspx?TypeId=10&FId=t3:10:3&Id=167#GW2A")[GW2A-LV18PG256C8/I7]_)],
[*实现摄像头视频传输功能*],[使用MIPI接口实现摄像头并能对应不同场景进行寄存器配置],[$checkmark$],[*CMOS芯片* (_OV5640_)],
[*网络传输能力*],[使用底板板载网卡： 实现百兆以太网功能],[$checkmark$],[*百兆网* (使用芯片 _RTL8201F_)],
[*理论视频传输分辨率*],[综合考虑帧率，使用标清等清晰度传输],[$circle$],[图像尺寸为 *$640 times 480$*],
[*视频传输帧率*],[为保证百兆正常观看，使折率设置为较为流畅的帧率],[$checkmark$],[帧率为 *$eq.gt 19 f p s$*],
[*视频编码方式*],[由于加入特殊图像处理后不足，使用标准的5-6-5 _RGB_ 编码方式],[$times$],[*原始编码* 但抗干扰能力强],
[*多路传输*],[可通过完整的UDP在两块板卡上设置不同IP实现],[$checkmark$],[*一主多从实现*],
[*图像增强功能*],[提供二值化、简单目标识别 边缘识别 滤波处理等功能],[$checkmark$],[*提供多种*],
[*可扩展性*],[可定制画幅 空余大量IO 有通用视频处理接口模块],[$circle$],[*资源足够，未做尝试*],

),
caption: "关键性能指标")<tb_is_ok>