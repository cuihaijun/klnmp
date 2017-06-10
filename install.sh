#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install klnmp"
    exit 1
fi
basepath=$(cd `dirname $0`; pwd)
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

function install_prepare() {
  #statements
  echo "开始安装前的准备工作 ..."
  echo
  yum install -y epel-release && yum update
  yum install -y wget vim gcc cmake make gcc-c++ openssl openssl-devel.x86_64 lsof chkconfig
  echo "创建klnmp项目 ..."
  echo
  mkdir /klnmp /klnmp/log /klnmp/log/php /klnmp/log/mariadb /klnmp/log/nginx
}

function install_php7() {
  #statements
  echo "开始安装php-$1 ..."
  echo
  cd
  yum install -y  libmcrypt.x86_64 libmcrypt-devel.x86_64 mcrypt.x86_64 mhash libxml2 libxml2-devel.x86_64  curl-devel libjpeg-devel libpng-devel freetype-devel gd gd-devel

  ln -s /klnmp/mariadb-10.1.22/lib/libmysqlclient.so /usr/lib64/ && ln -s /klnmp/mariadb-10.1.22/lib/libmysqlclient.so.18 /usr/lib64/
  echo -e "\n/usr/local/lib\n/usr/local/lib64\n/usr/local/related/libmcrypt/lib/\n" >> /etc/ld.so.conf.d/local.conf && ldconfig -v

  wget http://cn2.php.net/distributions/php-$1.tar.gz && tar zxvf php-$1.tar.gz && cd php-$1

  #64位系统添加--with-libdir=lib64参数
  ./configure --prefix=/klnmp/php-$1 --with-config-file-path=/klnmp/php-$1/etc --with-mysqli=/klnmp/mariadb-10.1.22/bin/mysql_config --with-iconv --with-zlib \
      --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-fpm --enable-mbstring \
      --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --enable-opcache --with-pdo-mysql --enable-maintainer-zts \
      --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd --enable-ftp --enable-session --with-gettext --with-jpeg-dir --with-freetype-dir --without-gdbm --disable-fileinfo --with-mcrypt \
      --with-iconv --with-libdir=lib64 && make && make install

  echo -e "\nexport PATH=/klnmp/php-$1/bin:/klnmp/php-$1/sbin:$PATH\n" >> /etc/profile && source /etc/profile

  mv /klnmp/php-$1/etc/php-fpm.d/www.conf.default /klnmp/php-$1/etc/php-fpm.d/www.conf.default.bak

  cp $basepath/config/php-fpm /etc/init.d/php-fpm && cp $basepath/config/php-fpm.conf /klnmp/php-$1/etc/php-fpm.conf && \
  cp $basepath/config/php.ini /klnmp/php-$1/etc/php.ini && cp $basepath/config/www.conf /klnmp/php-$1/etc/php-fpm.d/www.conf
}

function install_nginx() {
  #statements
  echo "开始安装nginx-$1 ..."
  echo
  cd
  yum -y install pcre pcre-devel zlib zlib-devel

  wget http://nginx.org/download/nginx-$1.tar.gz && tar zxvf nginx-$1.tar.gz && cd nginx-$1
  ./configure --prefix=/klnmp/nginx-$1 --with-http_ssl_module --with-http_stub_status_module --with-threads && make && make install
  mkdir /klnmp/nginx-$1/conf/vhost && mv /klnmp/nginx-$1/conf/nginx.conf /klnmp/nginx-$1/conf/nginx.conf.bak

  cp $basepath/config/nginx.conf /klnmp/nginx-$1/conf/nginx.conf
}

function install_mariadb() {
  #statements
  echo "开始安装mariadb-$1 ..."
  echo
  cd
  yum install -y ncurses-devel bison ncurses
  mkdir /klnmp/mariadb-$1 /klnmp/mariadb-$1/data /klnmp/mariadb-$1/etc && cd

  wget https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-$1/source/mariadb-$1.tar.gz
  tar -zxvf mariadb-$1.tar.gz && cd mariadb-$1
  if ["$2" == "y"]; then
    cmake . -DCMAKE_INSTALL_PREFIX=/klnmp/mariadb-$1 -DMYSQL_DATADIR=/klnmp/mariadb-$1/data -DSYSCONFDIR=/klnmp/mariadb-$1/etc -DMYSQL_UNIX_ADDR=/klnmp/mariadb-$1/mysql.sock \
    -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1  -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_SPHINX_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLED_LOCAL_INFILE=1 \
    -DCMAKE_EXE_LINKER_FLAGS='-ljemalloc' -DWITH_SAFEMALLOC=OFF -DENABLE_PROFILING=1
  else
    cmake . -DCMAKE_INSTALL_PREFIX=/klnmp/mariadb-$1 -DMYSQL_DATADIR=/klnmp/mariadb-$1/data -DSYSCONFDIR=/klnmp/mariadb-$1/etc -DMYSQL_UNIX_ADDR=/klnmp/mariadb-$1/mysql.sock \
    -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1  -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_SPHINX_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_LIBWRAP=0 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DENABLED_LOCAL_INFILE=1 -DENABLE_PROFILING=1
  fi
  make && make install

  cd /klnmp/mariadb-$1/scripts && ./mysql_install_db --datadir=/klnmp/mariadb-$1/data/ --basedir=/klnmp/mariadb-$1/ --user=root && cp ../support-files/mysql.server /etc/rc.d/init.d/mysqld

  echo "export PATH=$PATH:/klnmp/mariadb-$1/bin" >>/etc/profile && source /etc/profile

  cp $basepath/config/my.cnf /klnmp/mariadb-10.1.22/etc
}

function install_jemalloc() {
  #statements
  echo "开始安装jemalloc-$1"
  echo
  cd
  wget https://github.com/jemalloc/jemalloc/releases/download/4.2.0/jemalloc-4.2.0.tar.bz2 && cd jemalloc-4.2.0
  ./configure --prefix=/usr/local/jemalloc && make && make install
  echo -e '\n/usr/local/jemalloc/lib/\n' >> /etc/ld.so.conf.d/local.conf && ldconfig -v
  ln -vs /usr/local/jemalloc/lib/libjemalloc.so.2 /usr/local/lib/libjemalloc.so
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

  if [ "$php" == "y" ] || [ "$php" == "y" ] || [ "$php" == "y" ] || ["$memory" == "y"]; then
    install_prepare
  fi

  if [ "$memory" == "y" ]; then
    install_jemalloc -4.2.0
  fi

  if [ "$db" == "y" ]; then
    install_mariadb 10.1.22 $memory
  fi

  if [ "$php" == "y" ]; then
    install_php7 7.1.4
  fi

  if [ "$web" == "y" ]; then
    install_nginx 1.12.0
  fi

  cp config/klnmp.sh /klnmp/klnmp.sh
  #清理安装包
  cd && rm -rf *.tar.gz mariadb-10.1.22 nginx-1.12.0 php-7.1.4
  clear
  echo
  echo "安装成功，尽情享受klnmp带来的便利吧..."
}

start