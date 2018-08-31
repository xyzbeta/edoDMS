#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 7+/Debian 8+/Ubuntu 16+
#	Description: System Operation Tools
#	Version: 2.1.3
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

basedir=$(cd $(dirname $0); pwd -P)
sys_date=$(date "+%Y%m%d_%H%M%S")
frp_server="frp.xyzbeta.com"
tagfiles="${basedir}/runTag.txt"
docker_version="17.09.0"
sh_version="2.1.3"


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
	sh_new_version=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/xyzbeta/edoDMS/master/edoDMS.sh"|grep 'sh_version="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_version} ]] && echo -e "文件升级检查失败,脚本将退出。" && exit 0
	if [[ ! ${sh_version} == ${sh_new_version} ]]; then
		echo -e "${info}发现新版${sh_new_version},是否进行升级。[Y/n]"
		 read yn
		[[ -z ${yn} ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			 wget --no-check-certificate -N https://raw.githubusercontent.com/xyzbeta/edoDMS/master/edoDMS.sh && chmod u+x *.sh
		else 
		 echo -e "${Tip}取消更新!"
		fi
		echo && echo -e "${Info}脚本已经更新到最新版本:${sh_new_version},请重新运行本脚本" && echo
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
		debian_source=$(find /etc/apt/ -name "sources.list")
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
	elif [[ "${release}" == "centos" || "${release}" == "redhat" ]]; then
		echo -e "${Info}保存系统默认镜像源文件"
		centos_soure=$(find /etc/yum.repos.d/ -name "CentOS-Base.repo")
		cp ${centos_soure} ${centos_soure}_${sys_date}
		rm -f ${centos_source}
		wget --no-check-certificate http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
		rm -rf /var/cache/yum/
		yum makecache
		yum -y update
	fi
}

#系统安装docker
function installDocker(){
	echo -e "${Info}安装${release}系统所需docker依赖和docker"
	if [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		apt-get install -y curl
		apt-get install -y libapparmor1
		apt-get install -y libltdl7
		debhave=$(find / -name "docker*${docker_version}*.deb")
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载${docker_version}并进行安装"
				wget --no-check-certificate https://download.docker.com/linux/debian/dists/jessie/pool/stable/amd64/docker-ce_${docker_version}~ce-0~debian_amd64.deb
				dpkg -i $(find / -name "docker*${docker_version}*.deb")
			else
				echo -e "${Info}"${docker_version}"版本已经存在，无需下载。现在开始安装"
				dpkg -i ${debhave}
			fi
	elif [[ "${release}" == "centos" || "${release}" == "redhat" ]]; then
		yum install -y curl
		yum install -y container-selinux
		yum install -y libtool-ltdl
		debhave=$(find / -name "docker*${docker_version}*.rpm")
			if [ -z "${debhave}" ];then
				echo -e "${Info}下载${docker_version}版本并进行安装"
				wget https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-${docker_version}.ce-1.el7.centos.x86_64.rpm
				rpm -ivh $(find / -name "docker*${docker_version}*.rpm")
			else
				echo -e "${Info}${docker_version}版本已经存在，无需下载。现在开始安装"
				rpm -ivh ${debhave}
			fi
	fi
	systemctl enable docker && systemctl restart docker
}

#安装易度系统
function installEdo(){
	echo "{\"insecure-registries\":[\"192.168.1.112:5000\"]}">/etc/docker/daemon.json
	systemctl restart docker
	echo -e "${Info}下载docker-compose......"
	wget --no-check-certificate https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	mkdir /var/docker_data/
	docker run --rm -v /var/docker_data/:/config docker.easydo.cn:5000/compose && cd /var/docker_data/compose
	sed -i "s/REGISTRY=.*/REGISTRY=docker.easydo.cn:5000/g" .env
	until [[ "y" == ${downloadEdo_tag} || "Y" == ${downloadEdo_tag} ]]
	do
	echo -e -n "${Info}请输入系统配置文件下载地址:" &&  read downloadEdo
	echo -e -n "${Info}确认[Y/n]:" &&  read downloadEdo_tag
	[[ -z ${downloadEdo_tag} ]] && downloadEdo_tag="y"
	done
    #cp docker-compose.yml.template docker-compose.yml
	wget --no-check-certificate ${downloadEdo} -O /var/docker_data/compose/docker-compose.yml
	echo -e "${Info}开始安装系统"
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

#文档系统服务操作
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

#辅助功能(远程维护)
function remote_Help(){
	if [[ "1" == $1 ]]; then
		port=${RANDOM}
		echo -e -n "${Info}认证口令(token):" && read token && echo
		sed -i "s/^token\ =.*/token\ =\ ${token}/g" ${basedir}/frpc/frpc.ini
		sed -i "s/^user\ =.*/user\ =\ ${port}/g" ${basedir}/frpc/frpc.ini
		sed -i "s/^server_addr\ =.*/server_addr\ =\ ${frp_server}/g" ${basedir}/frpc/frpc.ini
		sed -i "s/^remote_port\ =.*/remote_port\ =\ ${port}/g" ${basedir}/frpc/frpc.ini
		cd ${basedir}/frpc/ && chmod +x frpc && nohup ./frpc -c ./frpc.ini &
		sleep 5s
		if [[ ! -z "$(ps -e | grep frpc | awk '{print $1}')" ]]; then
			echo "------------远程维护启动成功----------"
			echo && echo -e "${Green_font_prefix}SSH地址:${Font_color_suffix}${frp_server}  ${Green_font_prefix}SSH端口:${Font_color_suffix}:${port}" &&  echo
		else
			echo -e "${Tip}远程维护启动失败"
		fi
	elif [[ "2" == $1 ]]; then
		pid=$(ps -e | grep frpc | awk '{print $1}')
		if [[ -z ${pid} ]]; then
			echo -e "${Info}服务未启动。"
		else 
			sed -i "s/^token\ =.*/token\ =/g" ${basedir}/frpc/frpc.ini
			kill -9 ${pid}
			echo -e "${Info}服务关闭成功"
		fi
	fi
}

#####################################################################################################
#################业务流程整合区###################
#文档系统，7.0docker版本安装
function edoDMS_docker_install(){
[ ! -f "${tagfiles}" ] && functiontag=1 && touch ${tagfiles} || functiontag=$(cat ${tagfiles})
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

#辅助工具功能整合
function Help_Tools(){
	echo -e "
	${Green_font_prefix}1.${Font_color_suffix} 开启远程支持
	${Green_font_prefix}2.${Font_color_suffix} 关闭远程支持"
	echo && read -p "请输入数字[1-2]:" var
	case ${var} in
	1)
	remote_Help 1
	;;
	2)
	remote_Help 2
	;;
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
 ${Green_font_prefix}8.${Font_color_suffix} 辅助工具
 ${Green_font_prefix}0.${Font_color_suffix} 退出
 "
echo && read -p "请输入数字 [0-8]：" num && echo
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
	8)
	Help_Tools
	;;
	*)
	echo -e "${Error} 请输入正确的数字 [0-8]"
	;;
esac
done
