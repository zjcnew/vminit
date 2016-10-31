# VMware虚拟机Linux系统自动化配置脚本

使用方法：

将autovm.sh与install.sh脚本拷贝至虚拟机，执行sh install.sh安装脚本；

将主机名、登录密码、网络参数、存储配置等参数传给vminit.sh脚本后打包为ISO镜像，开机后使用虚拟光驱加载自动运行即可。

vminit_manual.sh为手动执行脚本，开机后提示键入IP地址与登录密码自动完成配置。