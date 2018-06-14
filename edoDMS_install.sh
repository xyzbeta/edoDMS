#!/bin/bash
#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: System Operation Tools
#	Version: 2.0
#	Author: XyzBeta
#	Blog: https://www.xyzbeta.com
#=================================================

######################################系统及运维工具常用变量配置区域#################
#字体颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
#提示信息
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

####################################运维工具基础方法区域###########################
#判断用户是否具有root 权限
check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

#判断系统发行版本
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|redhat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|redhat|redhat"; then
		release="centos"
    fi
}

##########################业务方法区########################
#更新系统镜像源
function updateSource(){
	echo -e "${Info}修改${release}系统的镜像源为阿里云下载源"
	sys_date=`date "+%Y%m%d_%H%M%S"`
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		local debian_source="/etc/apt/sources.list"
		echo -e "${Info}保存系统默认镜像源文件"
		cp ${debian_source} ${debian_source}_${sys_date}
		cat /dev/null>${debian_source}
		cat>${debian_source}<<-EOF
			deb http://mirrors.aliyun.com/debian/ jessie main non-free contrib
			deb http://mirrors.aliyun.com/debian/ jessie-updates main non-free contrib
			deb http://mirrors.aliyun.com/debian/ jessie-backports main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie-updates main non-free contrib
			deb-src http://mirrors.aliyun.com/debian/ jessie-backports main non-free contrib
			deb http://mirrors.aliyun.com/debian-security/ jessie/updates main non-free contrib
			deb-src http://mirrors.aliyun.com/debian-security/ jessie/updates main non-free contrib
			deb http://mirrors.aliyun.com/debian wheezy main contrib non-free
			deb-src http://mirrors.aliyun.com/debian wheezy main contrib non-free
			deb http://mirrors.aliyun.com/debian wheezy-updates main contrib non-free
			deb-src http://mirrors.aliyun.com/debian wheezy-updates main contrib non-free
			deb http://mirrors.aliyun.com/debian-security wheezy/updates main contrib non-free
			deb-src http://mirrors.aliyun.com/debian-security wheezy/updates main contrib non-free
		EOF
		echo -e "${Info}源替换完毕,开始进行系统更新"
		apt-get update
	elif [ "${release}" = "centos" || "${release}" == "redhat" ];then
		local centos_soure="/etc/yum.repos.d/CentOS-Base.repo"
		echo -e "${Info}保存系统默认镜像源文件"
		cp ${centos_soure} ${centos_soure}_${sys_date}
		rm -y ${centos_source}
		wget -O CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		yum clean all
		yum makecache
		yum update
	fi
}

function installDocker(){
	echo -e "${Info}安装${release}系统所需docker依赖和docker"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		apt-get install -y curl
		apt-get install -y libapparmor1
		apt-get install -y libltdl7
		debhave=$(find / -name docker-ce_17.09.*.deb)
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载docker17.09版本并进行安装"
				wget https://download.docker.com/linux/debian/dists/jessie/pool/stable/amd64/docker-ce_17.09.0~ce-0~debian_amd64.deb
				dpkg -i $(find / -name docker-ce_17.09.*.deb)
			else
				echo -e "${Info}docker版本已经存在，无需下载。现在开始安装"
				dpkg -i ${debhave}
			fi
	elif [[ "${release}" == "centos" || "${release}" == "redhat" ]]; then
		yum install -y curl
		yum install -y libapparmor1
		yum install -y libltdl7
		debhave=$(find / -name docker-ce_17.09.*.rpm)
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载docker17.09版本并进行安装"
				wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.09.0.ce-1.el7.centos.x86_64.rpm
				rpm -ivh $(find / -name docker-ce_17.09.*.rpm)
			else
				echo -e "${Info}docker版本已经存在，无需下载。现在开始安装"
				rpm -ivh ${debhave}
			fi
	fi
	systemctl enable docker && systemctl restart docker
}

function installEdo(){
	echo -e -n "${Info}开始设置配置文件,请输入文档系统的下载地址(内网地址为:192.168.1.112:5000):" && read downloadEdo
	echo "{\"insecure-registries\":[\"${downloadEdo}\"]}">/etc/docker/daemon.json
	systemctl restart docker
	echo -e "${Info}下载docker-compose......"
	wget https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	mkdir /var/docker_data/
	docker run --rm -v /var/docker_data/:/config ${downloadEdo}/compose && cd /var/docker_data/compose
	echo -e "${Info}开始安装系统"
	sed -i "s/REGISTRY=.*/REGISTRY=${downloadEdo}/g" .env
        cp docker-compose.yml.template docker-compose.yml
	docker-compose up -d
	if [[ ${?} == 0 ]]; then
		echo -e "${Tip}系统所需启动服务较多,请耐心等待3分钟。"
		sleep 3m
		echo -e "############系统安装成功#######################
#${Info}访问地址:http://ip:80
#${Info}运维控制台:http://ip:9099
#${Info}初始账户/密码:admin/admin
#${Info}激活与技术服务:4008-320-399
#############################################"
	fi
}

function stopFirewall(){
	if [[ "${release}" == "centos" ]]; then
		echo -e  "${Tip}防止${release}系统防火墙拦截系统的正常访问,安装时会关闭防火墙,待安装后测试访问正常后,请打开防火墙!"
		systemctl stop firewalld.service
		sleep 4
	fi
}

#####################业务流程入口##########################
check_root
check_sys
stopFirewall
updateSource
installDocker
installEdo
