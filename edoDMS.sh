#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: System Operation Tools
#	Version: 2.1.1
#	Author: XyzBeta
#	Blog: https://www.xyzbeta.com
#=================================================

##############变量配置区域#############
#字体颜色
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && Font_color_suffix="\033[0m"
#提示信息
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"

tagfiles="$(pwd)/edoDMS_runtag.txt"
debian_source="/etc/apt/sources.list"
centos_soure="/etc/yum.repos.d/CentOS-Base.repo"
sys_date=$(date "+%Y%m%d_%H%M%S")
docker_version="docker-ce_17.09.0"
sh_version="2.1.1"


##############基础方法区域###########
#判断用户是否具有root 权限
function check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${Green_background_prefix} sudo su ${Font_color_suffix}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

#判断系统发行版本
function check_sys(){
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
	[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
}

#脚本升级
function Update_Sh(){
	echo -e "${Info}当前文件版本为:${sh_version},开始检查是否存在新版本！"
	sh_new_version=$(wget --no-check-certificate -qO- "https://github.com/xyzbeta/edoDMS/blob/master/edoDMS_install.sh"|grep 'sh_version="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_version} ]] && echo -e "文件升级检查,脚本将退出。" && exit 0
	if [[ ${sh_version} == ${sh_new_version} ]]; then
		echo -e "${info}发现新版${sh_new_version},是否进行升级。[Y/n]"
		 read yn
		[[ -z ${yn} ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			 wget --no-check-certificate -N https://github.com/xyzbeta/edoDMS/archive/master.zip && unzip -o master.zip && cd edoDMS-master && chmod u+x *.sh
		else 
		 echo -e "${Tip}取消更新!"
		fi
		echo -e "${Info}脚本已经更新到最新版本:${sh_new_version}"
	else
		echo -e "${Info}当前版本为最新版本。"
	fi
	
	
}


################业务方法区####################
#更新系统镜像源
function updateSource(){
	echo -e "${Info}修改${release}系统的镜像源为阿里云下载源"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
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
		echo -e "${Info}保存系统默认镜像源文件"
		cp ${centos_soure} ${centos_soure}_${sys_date}
		rm -y ${centos_source}
		wget -O CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		yum clean all
		yum makecache
		yum update
	fi
}

#系统安装docker
function installDocker(){
	echo -e "${Info}安装${release}系统所需docker依赖和docker"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		apt-get install -y curl
		apt-get install -y libapparmor1
		apt-get install -y libltdl7
		debhave=$(find / -name ${docker_version}*.deb)
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载${docker_version}并进行安装"
				wget --no-check-certificate https://download.docker.com/linux/debian/dists/jessie/pool/stable/amd64/${docker_version}~ce-0~debian_amd64.deb
				dpkg -i $(find / -name ${docker_version}*.deb)
			else
				echo -e "${Info}${docker_version}版本已经存在，无需下载。现在开始安装"
				dpkg -i ${debhave}
			fi
	elif [[ "${release}" == "centos" || "${release}" == "redhat" ]]; then
		yum install -y curl
		yum install -y libapparmor1
		yum install -y libltdl7
		debhave=$(find / -name ${docker_version}*.rpm)
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载${docker_version}版本并进行安装"
				wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/${docker_version}.ce-1.el7.centos.x86_64.rpm
				rpm -ivh $(find / -name ${docker_version}*.rpm)
			else
				echo -e "${Info}docker版本已经存在，无需下载。现在开始安装"
				rpm -ivh ${debhave}
			fi
	fi
	systemctl enable docker && systemctl restart docker
}

#安装易度系统
function installEdo(){
	until [[ "y" == ${downloadEdo_tag} || "Y" == ${downloadEdo_tag} ]]
	do
	echo -e -n "${Info}开始设置配置文件,请输入文档系统的下载地址(默认地址:192.168.1.112:5000):" &&  read downloadEdo
	[[ -z ${downloadEdo} ]] && downloadEdo="192.168.1.112:5000"
	echo -e -n "${Info}系统获取的镜像下载地址是:${downloadEdo},确认[Y/n]:" &&  read downloadEdo_tag
	done
	echo "{\"insecure-registries\":[\"${downloadEdo}\"]}">/etc/docker/daemon.json
	systemctl restart docker
	echo -e "${Info}下载docker-compose......"
	wget --no-check-certificate https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
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
	rm -f ${tagfiles}
}

#关闭系统防火墙
function stopFirewall(){
	if [[ "${release}" == "centos" ]]; then
		echo -e  "${Tip}防止${release}系统防火墙拦截系统的正常访问,安装时会关闭防火墙,待安装后测试访问正常后,请打开防火墙!"
		systemctl stop firewalld.service
		sleep 4
	elif [[ "${release}" == "ubantu"  ]]; then
		 echo -e  "${Tip}防止${release}系统防火墙拦截系统的正常访问,安装时会关闭防火墙,待安装后测试访问正常后,请打开防火墙!"
		ufw disanble
		sleep 4
	fi
}

#标记调用过的方法,实现脚本重新运行时，已经运行成功的方法将不在重新执行。
function tagFunction(){
	if [[ "0" == $? ]]; then
		[[ -z $(cat ${tagfiles}) ]] && functiontag=1 || functiontag=$(cat ${tagfiles})
		((functiontag++))
		echo ${functiontag} > ${tagfiles}
	fi
}

function edoDMS_ServiceOperation(){
	cd /var/docker_data/compose/
	if [[ $1 == "start" ]]; then
		echo -e "${info}正在启动服务...."
		docker-compose up -d
		echo -e "${Tip}系统所需启动服务较多,请耐心等待1分钟。"
		sleep 1m
	elif [[ $1 == "stop" ]]; then
		echo -e "${info}正在关闭服务...."
		docker-compose down
	elif [[ $1 == "restart" ]]; then
		echo -e "${info}正在重启服务...."
		docker-compose down && docker-compose up -d
		echo -e "${Tip}系统所需启动服务较多,请耐心等待1分钟。"
		sleep 1m
	elif [[ $1 == "status" ]]; then
		docker-compose ps
	else
		echo -e "${Error}参数错误！"
	fi
}

#################业务流程整合区###################
#文档系统，7.0docker版本安装
function edoDMS_docker_install(){
[ ! -f "${tagfiles}" ] && functiontag=1 || functiontag=$(cat ${tagfiles})
case ${functiontag} in
	1)
	stopFirewall
	tagFunction
	;&
	2)
	updateSource
	tagFunction
	;&
	3)
	installDocker
	tagFunction
	;&
	4)
	installEdo
	;;
	*)echo -e "${Error}${tagfiles}标记文件内容错误，请检查！"
esac
}

###################脚本功能执行入口###############
check_sys
check_root
until [[ "0" == ${num} ]]
do
echo && echo -e "edoDMS自动化运维管理脚本 ${Green_font_prefix}[${sh_version}]${Font_color_suffix}
-- XyzBeta | https://github.com/xyzbeta/edoDMS --

 ${Green_font_prefix}1.${Font_color_suffix} 安装 edoDMS
 ${Green_font_prefix}2.${Font_color_suffix} 卸载 edoDMS
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 启动 edoDMS
 ${Green_font_prefix}4.${Font_color_suffix} 停止 edoDMS
 ${Green_font_prefix}5.${Font_color_suffix} 重启 edoDMS
 ${Green_font_prefix}6.${Font_color_suffix} 查看 edoDMS 运行状态
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 升级脚本
 ${Green_font_prefix}0.${Font_color_suffix} 退出
 "
echo && read -p "请输入数字 [0-7]：" num && echo
case "${num}" in
	0)
	exit 0
	;;
	1)
	edoDMS_docker_install
	;;
	2)
	echo -e "${Tip}该功能暂未启用"
	;;
	3)
	edoDMS_ServiceOperation start
	;;
	4)
	edoDMS_ServiceOperation stop
	;;
	5)
	edoDMS_ServiceOperation restart
	;;
	6)
	edoDMS_ServiceOperation status
	;;
	7)
	Update_Sh
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [0-7]"
	;;
esac
done
