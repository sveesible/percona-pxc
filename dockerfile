
FROM ubuntu

ENV PACKAGES='percona-xtradb-cluster-56 perl autossh percona-xtrabackup percona-toolkit wget  percona-xtradb-cluster-client-5.6'
ENV DATADIR=/data
ENV KEY_SERVER=hkp://http-keys.gnupg.net:80
ENV KEY_ID=1C4CBDCDCD2EFD2A
ENV CUSTOM_APT_REPO=http://repo.percona.com/apt
ENV CUSTOM_APT_NAME=percona
ENV MYSQL_ROOT_PASSWORD=somethingSecure!
ENV BUFFER_POOL_SIZE=1G
#CLUSTER_NODES=comma separated list of ip addresses for other nodes
ENV CLUSTER_NODES=""
ENV CLUSTER_SECRET=lessSecure?
ENV CLUSTER_CHECK_PW=clusterCheckPwd!
ENV CLUSTER_NAME=PXC1
ENV CLUSTER_NODE_NAME=PXC-NODE1
ENV CLUSTER_NODE_IP=""

ENV CLUSTER_CACHE_SIZE=2097152000
#ENV KEEPALIVE_ROUTER_ID=51
#ENV KEEPALIVE_VIP=192.168.0.200
#ENV KEEPALIVE_INTERFACE=eth0
#ENV USE_KEEPALIVED=true
#ENV KEEPALIVE_STATE=BACKUP


ADD setMyCnf.sh /setMyCnf.sh
 

RUN mkdir -p /etc/mysql/conf.d \
	&& mkdir -p $DATADIR/binlogs \
	&& groupadd -r mysql && useradd -r -g mysql mysql \
	&& chown -R mysql:mysql /etc/mysql \
	&& bash /setMyCnf.sh \
	&& echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
	&& apt-key adv --keyserver ${KEY_SERVER}  --recv-keys ${KEY_ID} \
	&& echo "deb ${CUSTOM_APT_REPO} `lsb_release -cs` main" > /etc/apt/sources.list.d/${CUSTOM_APT_NAME}.list \
	&& apt-get update \
	&& apt-get install -y  ${PACKAGES} --no-install-recommends \
	&& rm -rf /var/lib/apt/lists/* \
	&& wget http://www.quicklz.com/qpress-11-linux-x64.tar \
	&& tar -xf qpress-11-linux-x64.tar -C /usr/bin/

#TODO: map the data dir to a directory within the host
#VOLUME ["/mnt/mysql/data:${DATADIR}","/etc/mysql", "/var/lib/mysql"]

RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf \
	&& sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf  \
	&& sed -i 's/^\(skip-networking)\s.*\)/# \1/' /etc/mysql/my.cnf \
	&& chown -R mysql:mysql "${DATADIR}" \
	&& echo "Moving mysql data directory" \
	&& mysql_install_db --datadir="${DATADIR}" \
	&& /etc/init.d/mysql bootstrap-pxc & mysqladmin --silent --wait=600 ping || exit 0 \
	&& echo "Resetting root accounts" \
	&& mysql -e "DELETE FROM mysql.user;" \
	&& mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" \
	&& mysql -e "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;" \
	&& echo "Dropping Test DB" \
	&& mysql -e "DROP DATABASE IF EXISTS test;" \
	&& echo "Creating SST user account" \
	&& mysql -e "CREATE USER 'sstuser'@'localhost' IDENTIFIED BY '${CLUSTER_SECRET}';" \
	&& mysql -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';" \
	&& mysql -e "GRANT PROCESS on *.* to 'clustercheckuser'@'localhost' identified by '${CLUSTER_CHECK_PW}';" \
	&& mysql -e "FLUSH PRIVILEGES ;" \
	&& mv /root/postConfig.my.cnf /root/.my.cnf \
	&& echo "Shutting down" \
	&& mysqladmin shutdown 


ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh && chmod a+rx /setMyCnf.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["start"]

#DEPRECATED
#EXPOSE 3307:3306
#EXPOSE 4444:4444
#EXPOSE 4567:4567
#EXPOSE 4568:4568
