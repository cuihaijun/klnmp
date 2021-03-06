#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install klnmp"
    exit 1
fi

set -e
SOFTS=0
INSTALLED=0
basepath=$(cd `dirname $0`; pwd)
mariadb_user=mysql
clear
echo
echo "========================================================================="
echo "           klnmp For linux 2017"
echo "========================================================================="
echo
echo "更多信息请访问  http://www.klnmp.net/"
echo "========================================================================="
echo

function output() {
    #statement
    echo $@
}

# check memory is or not enough
function check_memory_and_swap(){
    phymem=`free | grep "Mem:" |awk '{print $2}'`
    echo "检查内存大小:${phymem}..."
    echo
    if [ "$phymem" -le "1024000" ]; then
        echo "内存不足，调整swap ..."
        swapoff -a
        dd if=/dev/zero of=/swapfile bs=1M count=2048
        mkswap /swapfile
        chmod -R 600 /swapfile
        swapon /swapfile
    fi
    # TODO swap检查机制
}

function install_prepare() {
    #statements
    echo "开始安装前的准备工作 ..."
    echo
    if [ ! -f "/klnmp/.prepare" ] || [ `cat /klnmp/.prepare` -ne "1" ]; then
        yum install -y epel-release && yum -y update
        yum install -y wget vim gcc cmake make gcc-c++ openssl openssl-devel.x86_64 lsof chkconfig psmisc
        echo "创建klnmp项目 ..."
        echo
        mkdir -p /klnmp /klnmp/www /klnmp/log /klnmp/log/php /klnmp/log/mariadb /klnmp/log/nginx && chmod -R 777 /klnmp/log
        echo "1" > /klnmp/.prepare
    fi
}

function uninstall(){
    echo "停止mysql"
        /etc/init.d/mysqld stop
    echo

    echo "停止php-fpm"
        killall -9 php-fpm
    echo

    echo "停止nginx"
        killall -9 nginx
    echo
    echo "卸载 klnmp ..."

    rm -rf /klnmp/php-7.1.4 /klnmp/nginx-1.12.0 /klnmp/nginx-1.12.0 /klnmp/jemalloc-4.2.0 /klnmp/mariadb-10.1.22 /klnmp/log /etc/init.d/mysqld
    cd && rm -rf php* nginx* mariadb* jemalloc*
    
    echo
    echo "卸载 klnmp 完成"
}

function install_php7() {
    #statements
    echo "开始安装php-$1 ..."
    echo
    groupadd www && useradd -g www www && cd
    yum install -y  libmcrypt.x86_64 libmcrypt-devel.x86_64 mcrypt.x86_64 mhash libxml2 libxml2-devel.x86_64  curl-devel libjpeg-devel libpng-devel freetype-devel gd gd-devel

    ln -sf /klnmp/mariadb-10.1.22/lib/libmysqlclient.so /usr/lib64/ && ln -sf /klnmp/mariadb-10.1.22/lib/libmysqlclient.so.18 /usr/lib64/
    echo -e "\n/usr/local/lib\n/usr/local/lib64\n/usr/local/related/libmcrypt/lib/\n" >> /etc/ld.so.conf.d/local.conf && ldconfig -v

    wget http://cn2.php.net/distributions/php-$1.tar.gz && tar zxvf php-$1.tar.gz && cd php-$1

    #64位系统添加--with-libdir=lib64参数
    ./configure --prefix=/klnmp/php-$1 --with-config-file-path=/klnmp/php-$1/etc --with-mysqli=/klnmp/mariadb-10.1.22/bin/mysql_config --with-iconv --with-zlib \
      --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-fpm --enable-mbstring \
      --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --enable-opcache --with-pdo-mysql --enable-maintainer-zts \
      --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd --enable-ftp --enable-session --with-gettext --with-jpeg-dir --with-freetype-dir --without-gdbm --disable-fileinfo --with-mcrypt \
      --with-iconv --with-libdir=lib64 && make || (echo "php configure 失败！";uninstall)  && make install || (echo "编译 php 失败！";uninstall) && make clean || (echo "安装 php 失败！";uninstall)

    echo -e "\nexport PATH=/klnmp/php-$1/bin:/klnmp/php-$1/sbin:$PATH\n" >> /etc/profile && source /etc/profile

    mv /klnmp/php-$1/etc/php-fpm.d/www.conf.default /klnmp/php-$1/etc/php-fpm.d/www.conf.default.bak

    cp -rf $basepath/config/php-fpm.conf /klnmp/php-$1/etc/php-fpm.conf && cp -rf $basepath/config/php.ini /klnmp/php-$1/etc/php.ini && cp -rf $basepath/config/www.conf /klnmp/php-$1/etc/php-fpm.d/www.conf
}

function install_nginx() {
    #statements
    echo "开始安装nginx-$1 ..."
    echo
    cd
    yum -y install pcre pcre-devel zlib zlib-devel

    wget http://nginx.org/download/nginx-$1.tar.gz && tar zxvf nginx-$1.tar.gz && cd nginx-$1
    if [ "$2" == "y" ]; then
        ./configure --prefix=/klnmp/nginx-$1 --with-http_ssl_module --with-http_stub_status_module --with-threads --with-ld-opt="-L /usr/local/lib64" && make && make install
    else
        ./configure --prefix=/klnmp/nginx-$1 --with-http_ssl_module --with-http_stub_status_module --with-threads  && make || (echo "nginx configure 失败！";uninstall) && make install || (echo "编译 nginx 失败！";uninstall) && make clean || (echo "安装 nginx 失败！";uninstall)
    fi

    mkdir /klnmp/nginx-$1/conf/vhost && mv /klnmp/nginx-$1/conf/nginx.conf /klnmp/nginx-$1/conf/nginx.conf.bak

    cp -rf $basepath/config/nginx.conf /klnmp/nginx-$1/conf/nginx.conf
    cp -rf $basepath/config/index.php /klnmp/www/index.php
}

function install_mariadb() {
    # check user is existed
    egrep "^$mariadb_user" /etc/passwd >& /dev/null
    if [ $? -ne 0 ]
    then
        useradd $mariadb_user
    fi
    # remove existed mysql
    mariadb=`rpm -qa mariadb`    
    if [[ $mariadb =~ "mariadb" ]]; then 
        echo "删除系统自带的mysql："${mariadb}
        rpm -e --nodeps ${mariadb}
    fi
    mariadb=`rpm -qa mysql`    
    if [[ $mariadb =~ "mysql" ]]; then 
        echo "删除系统自带的mysql："${mariadb}
        rpm -e --nodeps ${mariadb}
    fi
    #statements
    echo "开始安装mariadb-$1 ..."
    echo
    cd
    yum install -y ncurses-devel bison ncurses
    mkdir /klnmp/mariadb-$1 /klnmp/mariadb-$1/data /klnmp/mariadb-$1/etc && cd

    #wget https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$1/source/mariadb-$1.tar.gz
    wget http://ftp.hosteurope.de/mirror/archive.mariadb.org//mariadb-$1/source/mariadb-$1.tar.gz
    tar -zxvf mariadb-$1.tar.gz && cd mariadb-$1
    if [ "$2" == "y" ]; then
        cmake . -DCMAKE_INSTALL_PREFIX=/klnmp/mariadb-$1 -DMYSQL_DATADIR=/klnmp/mariadb-$1/data -DSYSCONFDIR=/klnmp/mariadb-$1/etc -DMYSQL_UNIX_ADDR=/klnmp/mariadb-$1/mysql.sock \
        -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1  -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_SPHINX_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLED_LOCAL_INFILE=1 \
        -DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DWITH_SAFEMALLOC=OFF -DENABLE_PROFILING=1 -DWITHOUT_TOKUDB=1 || (echo "mariadb configure 失败！";uninstall)
    else
        cmake . -DCMAKE_INSTALL_PREFIX=/klnmp/mariadb-$1 -DMYSQL_DATADIR=/klnmp/mariadb-$1/data -DSYSCONFDIR=/klnmp/mariadb-$1/etc -DMYSQL_UNIX_ADDR=/klnmp/mariadb-$1/mysql.sock \
        -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1  -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_SPHINX_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLED_LOCAL_INFILE=1 \
        -DENABLE_PROFILING=1 -DWITHOUT_TOKUDB=1 || (echo "mariadb configure 失败！";uninstall)
    fi
    make && make install || (echo "编译 mariadb 失败！";uninstall)  && make clean || (echo "安装 mariadb 失败！";uninstall)

    cd /klnmp/mariadb-$1/scripts && ./mysql_install_db --defaults-file=/klnmp/mariadb-$1/etc/my.cnf --datadir=/klnmp/mariadb-$1/data/ --basedir=/klnmp/mariadb-$1/ --user=mysql && cp ../support-files/mysql.server /etc/rc.d/init.d/mysqld
    #给root用户设置密码klnmproot
    #/klnmp/mariadb-10.1.22/bin/mysqladmin -u root password 'klnmproot'
    #echo "export PATH=$PATH:/klnmp/mariadb-$1/bin" >>/etc/profile && source /etc/profile

    cp -rf $basepath/config/my.cnf /klnmp/mariadb-$1/etc
    chown -R mysql:root /klnmp/mariadb-$1 && chmod -R 775 /klnmp/mariadb-$1
}


function install_jemalloc() {
    #statements
    echo "开始安装jemalloc-$1"
    echo
    mkdir /klnmp/jemalloc-$1
    cd
    wget https://github.com/jemalloc/jemalloc/releases/download/4.2.0/jemalloc-4.2.0.tar.bz2 && tar xf jemalloc-$1.tar.bz2 && cd jemalloc-$1
    ./configure --prefix=/klnmp/jemalloc-$1 && make || (echo "jemalloc configure 失败！";uninstall) && make install || (echo "编译 jemalloc 失败！";uninstall) && make clean || (echo "安装 jemalloc 失败！";uninstall)
    echo -e "\n/klnmp/jemalloc-$1/lib/\n" >> /etc/ld.so.conf.d/local.conf && ldconfig -v
    ln -sf /klnmp/jemalloc-$1/lib/libjemalloc.so.2 /usr/local/lib/libjemalloc.so
}


function start() {
    #statements
    read -p "是否安装php-7.1.4, 请输入 y 或 n 确认:
    yes or not install php-7.1.4, input y or n : " php
    echo

    read -p "是否安装nginx-1.12.0 ,请输入 y 或 n 确认 :
    yes or not install nginx-1.12.0, input y or n : " web
    echo

    read -p "是否安装 mariadb-10.1.22 ,请输入 y 或 n 确认 :
    yes or not install mariadb, input y or n : " db
    echo

    read -p "是否安装内存优化工具 jemalloc-4.2.0  ,请输入 y 或 n 确认 :
    yes or not install mariadb, input y or n : " memory
    echo

    if [ "$php" == "y" ] || [ "$php" == "y" ] || [ "$php" == "y" ] || [ "$memory" == "y" ]; then
        install_prepare
        check_memory_and_swap
        let "SOFTS+=1"
    fi

    if [ "$memory" == "y" ]; then
        install_jemalloc 4.2.0
        let "SOFTS+=1"
    fi

    if [ "$db" == "y" ]; then
        install_mariadb 10.1.22 $memory
        let "SOFTS+=1"
    fi

    if [ "$php" == "y" ]; then
        install_php7 7.1.4
        let "SOFTS+=1"
    fi

    if [ "$web" == "y" ]; then
        install_nginx 1.12.0 $memory
        let "SOFTS+=1"
    fi

    cp -rf $basepath/config/klnmp /klnmp/klnmp
    chmod +x /klnmp/klnmp
    echo -e "\nexport PATH=$PATH:/klnmp\n" >>/etc/profile && source /etc/profile
    echo -e "\nsource /etc/profile\n" >>/root/.bashrc && source /root/.bashrc
    #清理安装包
    cd && rm -rf php* nginx* mariadb* jemalloc*
    #清理swap
    #swapoff /swapfile
    #rm /swapfile
    clear
    echo
    echo "========================================================================="
    echo
    echo "安装成功，尽情享受klnmp带来的便利吧..."
    echo 
    echo "mariadb root账户的密码是：klnmproot"
    echo
    echo "klnmp start|stop|restart"
    echo
    echo "========================================================================="
    echo
}
if [ "$1" == "uninstall" ]; then
    uninstall
    exit
fi
# 取消cp别名，使cp能够强制覆盖
#unalias cp
start
#复制完成后恢复别名
#alias cp='cp -i'
