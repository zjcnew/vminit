vminit v1.94 [![Build Status](https://img.shields.io/travis/rust-lang/rust/master.svg?branch=master)](https://github.com/zjcnew/vminit) [![QQ-619877197](https://img.shields.io/badge/QQ-619877197-red.svg?qq=619877197)](tencent://AddContact/?fromId=50&fromSubId=1&subcmd=all&uin=619877197)
========================
使用Shell编写的支持VMware Workstation虚拟机针对Linux系统实现自动化配置，支持CentOS、Red Hat、openSuSE、Ubuntu、Debian、FreeBSD系统！

环境需求
------------------------
  CentOS/Red Hat、Ubuntu/Debian系统安装 sed gawk parted grep ntp ntpdate util-linux-ng iproute 软件包；openSUSE系统安装 postgresql92-contrib 软件包；FreeBSD系统安装 zfs expect cksum gflags 软件包。

文件说明
------------------------
  autovm.sh  添加到开机自启动运行
  install.sh 自动部署autovm.sh脚本到系统
  vminit.sh  自动运行主程序
  
使用方法
------------------------

	1.将autovm.sh与install.sh脚本拷贝至虚拟机系统，执行sh install.sh安装脚本；

	2.将主机名、登录密码、网络参数、存储配置等参数传给vminit.sh脚本后打包为ISO镜像，虚拟机开机后使用虚拟光驱加载自动运行即可。
	
		参数实例：
	
			HN_MOD=webserver				#系统主机名
			PS_MOD=password					#系统登录密码
			IP_MOD=192.168.80.203,10.98.80.203			#外网ip地址，内网ip地址（英文逗号分隔）
			MS_MOD=255.255.255.0,255.255.255.0			#外网掩码，内网掩码（英文逗号分隔）
			GW_MOD=192.168.80.1				#外网网关
			DN_MOD=202.96.134.133,202.96.128.86			#DNS服务器ip地址
			FM_MOD=YES						#是否对数据盘分区格式化
