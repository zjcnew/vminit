# VMware虚拟机Linux系统自动化配置脚本

使用方法：

1.将autovm.sh与install.sh脚本拷贝至虚拟机，执行sh install.sh安装脚本；

2.将主机名、登录密码、网络参数、存储配置等参数传给vminit.sh脚本后打包为ISO镜像，开机后使用虚拟光驱加载自动运行即可。

3.vminit_manual.sh为手动执行脚本，虚拟机开机后提示键入IP地址与登录密码来自动完成配置。