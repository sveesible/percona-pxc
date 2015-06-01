#!/bin/bash
set -e

do_reset_config() {
	/setMyCnf.sh 
}

reset_root_pw() {
	if ! grep -q ${MYSQL_ROOT_PASSWORD} /root/.my.cnf ; then
			echo "resetting mysql root pw"
	        /usr/bin/mysqladmin -u root password "${MYSQL_ROOT_PASSWORD}"
	        mv -f /root/postConfig.my.cnf /root/.my.cnf
	fi
	
}

  
case "$*" in
   bash)
      bash
   ;;
   start)
		echo "reseting my.cnf"
		do_reset_config
		echo "Starting Mysql"
		if [ -f /var/run/mysqld/mysqld.sock ]; then
			rm /var/run/mysqld/mysqld.sock
		fi
		if [ -f ${DATADIR}/mysqld.pid ]; then
			rm ${DATADIR}/mysqld.pid
		fi
		mysqld_safe
		
		#if [ ${USE_KEEPALIVED} = true ]; then
		#	/etc/init.d/keepalived start
		#fi
		#HACK to get Docker to stay running while in Daemon mode, tail stays in the foreground
		mysqladmin --silent --wait=300 ping || exit 1 && tail -f /dev/null
	;;
	bootstrap)
		echo "Bootstrappping Mysql"
		do_reset_config
		if [ -f /var/run/mysqld/mysqld.sock ]; then
			rm /var/run/mysqld/mysqld.sock
		fi
		if [ -f ${DATADIR}/mysqld.pid ]; then
			rm ${DATADIR}/mysqld.pid
		fi
		/etc/init.d/mysql bootstrap-pxc & mysqladmin --silent --wait=300 ping || exit 1
		reset_root_pw
		#if [ ${USE_KEEPALIVED} = true ]; then
		#	/etc/init.d/keepalived start
		#fi
		#HACK to get Docker to stay running while in Daemon mode, tail stays in the foreground
		mysqladmin --silent --wait=300 ping || exit 1 && tail -f /dev/null 
	;;
	*) 
		echo "Use either start or bootstrap"
	;;
esac


