red="\033[31m"
black="\033[0m"

base=/etc/dnat
mkdir $base 2>/dev/null
conf=$base/conf
touch $conf

# wget wget --no-check-certificate -qO natcfg.sh http://blog.arloor.com/sh/iptablesUtils/natcfg.sh && bash natcfg.sh

    clear
    echo "#############################################################"
    echo "# Usage: setup iptables nat rules for domian/ip             #"
    echo "# Website:  http://www.arloor.com/                          #"
    echo "# Author: ARLOOR <admin@arloor.com>                         #"
    echo "# Github: https://github.com/arloor/iptablesUtils           #"
    echo "# 端口都填443目标netflix.com 劫持tcp53dns需本地支持tcp53dns #"
    echo "# smartdns不支持centos自行 https://pymumu.github.io/smartdns#"
    echo "#############################################################"
    echo


setupService(){
    cat > /usr/local/bin/dnat.sh <<"AAAA"
#! /bin/bash
[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;



base=/etc/dnat
mkdir $base 2>/dev/null
conf=$base/conf
firstAfterBoot=1
lastConfig="/iptables_nat.sh"
lastConfigTmp="/iptables_nat.sh_tmp"


####
echo "正在安装依赖...."
yum install -y bind-utils &> /dev/null
apt install -y dnsutils &> /dev/null
echo "Completed：依赖安装完毕"
echo ""
####
turnOnNat(){
    # 开启端口转发
    echo "1. 端口转发开启  【成功】"
    sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
    if [ $? -ne 0 ]; then
        echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
    fi

    #开放FORWARD链
    echo "2. 开放iptbales中的FORWARD链  【成功】"
    arr1=(`iptables -L FORWARD -n  --line-number |grep "REJECT"|grep "0.0.0.0/0"|sort -r|awk '{print $1,$2,$5}'|tr " " ":"|tr "\n" " "`)  #16:REJECT:0.0.0.0/0 15:REJECT:0.0.0.0/0
    for cell in ${arr1[@]}
    do
        arr2=(`echo $cell|tr ":" " "`)  #arr2=16 REJECT 0.0.0.0/0
        index=${arr2[0]}
        echo 删除禁止FOWARD的规则$index
        iptables -D FORWARD $index
    done
    iptables --policy FORWARD ACCEPT
}
turnOnNat



testVars(){
    local localport=$1
    local remotehost=$2
    local remoteport=$3
    # 判断端口是否为数字
    local valid=
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
       echo  -e "${red}本地端口和目标端口请输入数字！！${black}";
       return 1;
    }

    # 检查输入的不是IP
    #if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
     #   local isip=true
     #   local remote=$remotehost
#
 #       echo -e "${red}警告：你输入的目标地址是一个ip!${black}"
  #      return 2;
   # fi
}

dnat(){
     [ "$#" = "3" ]&&{
        local localport=$1
        local remote=$2
        local remoteport=$3

        cat >> $lastConfigTmp <<EOF
iptables -t nat -I OUTPUT  -d 23.246.0.0/18 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 37.77.184.0/21 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 45.57.0.0/17 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 64.120.128.0/17 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 66.197.128.0/17 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 108.175.32.0/20 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 192.173.64.0/18 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 198.38.96.0/19 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 198.45.48.0/20 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 8.41.4.0/24 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 69.53.224.0/19 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 185.2.220.0/22 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 185.9.188.0/22 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 203.75.0.0/16 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 207.45.72.0/22 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -I OUTPUT  -d 208.75.76.0/22 -p tcp --dport $localport -j DNAT --to-destination $remote
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A POSTROUTING -p tcp -d $remote -j SNAT --to-source $localIP
EOF
    }
}

dnatIfNeed(){
  [ "$#" = "3" ]&&{
    local needNat=0
    # 如果已经是ip
    if [ "$(echo  $2 |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
        local remote=$2
    else
        local remote=$(host -t a  $2|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1)
    fi

    if [ "$remote" = "" ];then
            echo Warn:解析失败
          return 1;
     fi
  }||{
      echo "Error: host命令缺失或传递的参数数量有误"
      return 1;
  }
    echo $remote >$base/${1}IP
    dnat $1 $remote $3
}


echo "3. 开始监听域名解析变化"
echo ""
while true ;
do
## 获取本机地址
localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "${localIP}" = "" ]; then
        localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1|head -n 1 )
fi
echo  "本机网卡IP [$localIP]"
cat > $lastConfigTmp <<EOF
iptables -t nat -F OUTPUT
iptables -t nat -F POSTROUTING
EOF
arr1=(`cat $conf`)
for cell in ${arr1[@]}
do
    arr2=(`echo $cell|tr ":" " "|tr ">" " "`)  #arr2=16 REJECT 0.0.0.0/0
    # 过滤非法的行
    [ "${arr2[2]}" != "" -a "${arr2[3]}" = "" ]&& testVars ${arr2[0]}  ${arr2[1]} ${arr2[2]}&&{
        echo "转发规则： ${arr2[0]} => ${arr2[1]}:${arr2[2]}"
        dnatIfNeed ${arr2[0]} ${arr2[1]} ${arr2[2]}
    }
done

lastConfigTmpStr=`cat $lastConfigTmp`
lastConfigStr=`cat $lastConfig`
if [ "$firstAfterBoot" = "1" -o "$lastConfigTmpStr" != "$lastConfigStr" ];then
    echo '更新iptables规则[DOING]'
    source $lastConfigTmp
    cat $lastConfigTmp > $lastConfig
    echo '更新iptables规则[DONE]，新规则如下：'
    echo "###########################################################"
    iptables -L OUTPUT -n -t nat --line-number
    iptables -L POSTROUTING -n -t nat --line-number
    echo "###########################################################"
else
 echo "iptables规则未变更"
fi

firstAfterBoot=0
echo '' > $lastConfigTmp
sleep 60
echo ''
echo ''
echo ''
done    
AAAA
echo 


cat > /lib/systemd/system/dnat.service <<\EOF
[Unit]
Description=动态设置iptables转发规则
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/root/
EnvironmentFile=
ExecStart=/bin/bash /usr/local/bin/dnat.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dnat > /dev/null 2>&1
service dnat stop > /dev/null 2>&1
service dnat start > /dev/null 2>&1
}


## 获取本机地址
localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1 | grep -Ev '(^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.1[6-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.2[0-9]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^172\.3[0-1]{1}[0-9]{0,1}\.[0-9]{1,3}\.[0-9]{1,3}$)|(^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$)')
if [ "${localIP}" = "" ]; then
        localIP=$(ip -o -4 addr list | grep -Ev '\s(docker|lo)' | awk '{print $4}' | cut -d/ -f1|head -n 1 )
fi


addDnat(){
    local localport=
    local remoteport=
    local remotehost=
	local localIP=
    local valid=
    echo -n "本地端口号:" ;read localport
    echo -n "远程端口号:" ;read remoteport
    # echo $localport $remoteport
    # 判断端口是否为数字
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
        echo  -e "${red}本地端口和目标端口请输入数字！！${black}"
        return 1;
    }

    echo -n "目标域名/IP:" ;read remotehost
    # # 检查输入的不是IP
    # if [ "$remotehost" = "" -o "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
    #     isip=true
    #     remote=$remotehost
    #     echo -e "${red}请输入一个ddns域名${black}"
    #     return 1
    # fi

    sed -i "s/^$localport.*/$localport>$remotehost:$remoteport/g" $conf
    [ "$(cat $conf|grep "$localport>$remotehost:$remoteport")" = "" ]&&{
            cat >> $conf <<LINE
$localport>$remotehost:$remoteport
LINE
    }
    echo "成功添加转发规则 $localport>$remotehost:$remoteport"
    setupService
}

rmDnat(){
    local localport=
    echo -n "本地端口号:" ;read localport
    sed -i "/^$localport>.*/d" $conf
    echo "done!"
}

testVars(){
    local localport=$1
    local remotehost=$2
    local remoteport=$3
    # 判断端口是否为数字
    local valid=
    echo "$localport"|[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ] && echo $remoteport |[ -n "`sed -n '/^[0-9][0-9]*$/p'`" ]||{
       # echo  -e "${red}本地端口和目标端口请输入数字！！${black}";
       return 1;
    }

    # # 检查输入的不是IP
    # if [ "$(echo  $remotehost |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" != "" ];then
    #     local isip=true
    #     local remote=$remotehost

    #     # echo -e "${red}警告：你输入的目标地址是一个ip!${black}"
    #     return 2;
    # fi
}

lsDnat(){
    arr1=(`cat $conf`)
for cell in ${arr1[@]}  
do
    arr2=(`echo $cell|tr ":" " "|tr ">" " "`)  #arr2=16 REJECT 0.0.0.0/0
    # 过滤非法的行
    [ "${arr2[2]}" != "" -a "${arr2[3]}" = "" ]&& testVars ${arr2[0]}  ${arr2[1]} ${arr2[2]}&&{
        echo "转发规则： ${arr2[0]}>${arr2[1]}:${arr2[2]}"
    }
done
}




echo  -e "${red}你要做什么呢（请输入数字）？Ctrl+C 退出本脚本${black}"
select todo in 劫持tvnfip 删除转发规则 列出所有转发规则 查看当前iptables配置  安装smartdns 卸载smartdns
do
    case $todo in
    劫持tvnfip)
        addDnat
        #break
        ;;
    删除转发规则)
        rmDnat
        #break
        ;;
    # 增加到IP的转发)
    #     addSnat
    #     #break
    #     ;;
    # 删除到IP的转发)
    #     rmSnat
    #     #break
    #     ;;
    列出所有转发规则)
        lsDnat
        ;;
    查看当前iptables配置)
        echo "###########################################################"
        iptables -L OUTPUT -n -t nat --line-number
        iptables -L POSTROUTING -n -t nat --line-number
        echo "###########################################################"
        ;;
    安装smartdns)
        wget https://github.com/pymumu/smartdns/releases/download/Release33/smartdns.1.2020.09.08-2235.x86_64-debian-all.deb
        dpkg -i smartdns*.deb
        rm -rf smartdns*.deb
        wget https://raw.githubusercontent.com/nameless3721/nash/master/smartdns.conf
        mv -f smartdns.conf /etc/smartdns/
        read -p "输入nf解锁dns默认127.0.0.1" netflix
        [ -z "${netflix}" ] && netflix='127.0.0.1'
        sed -i "s/#server 88.88.88.88 -group nf/server $netflix -group nf/g" /etc/smartdns/smartdns.conf
        apt-get -y install resolvconf
        echo -e "nameserver 127.0.0.1\nnameserver 1.0.0.1" >>/etc/resolvconf/resolv.conf.d/head
        systemctl restart resolvconf
        systemctl restart smartdns
        systemctl enable smartdns		
        ;;
    卸载smartdns)
        dpkg --purge smartdns
        sed -i "s/nameserver 127.0.0.1/ /g" /etc/resolvconf/resolv.conf.d/head
        systemctl restart resolvconf
        apt-get -y remove --purge resolvconf
        ;;
    *)
        echo "如果要退出，请按Ctrl+C"
        ;;
    esac
done
