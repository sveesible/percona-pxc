#!/bin/bash

#hack around docker's way of making IP address so we can set teh IST.recv_addr
CLUSTER_NODE_LOCAL_IP=`ip route get 8.8.8.8 | grep -oP 'via \K\S+'`
if [ -z CLUSTER_NODE_IP ]; then
	CLUSTER_NODE_IP=$CLUSTER_NODE_LOCAL_IP
fi
cat>/etc/mysql/conf.d/my.cnf<<EOF
[CLIENT]
default-character-set = utf8

[MYSQLD]
character-set-server = utf8
init-connect = 'SET NAMES utf8'
collation-server = utf8_general_ci
max_connections = 2500
user = mysql
default_storage_engine = InnoDB
basedir = /usr
pid_file = ${DATADIR}/mysqld.pid
datadir = ${DATADIR}
innodb_data_home_dir = ${DATADIR}
innodb_log_group_home_dir = ${DATADIR}
socket = ${DATADIR}/mysqld.sock
port = 3306
innodb_buffer_pool_size = ${BUFFER_POOL_SIZE}" 
innodb_autoinc_lock_mode = 2
innodb_log_files_in_group = 2
innodb_log_file_size = 64M
innodb_file_format = Barracuda
log_queries_not_using_indexes = 1
max_allowed_packet = 16M
binlog_format = ROW
wsrep_provider = /usr/lib/libgalera_smm.so
wsrep_node_address = ${CLUSTER_NODE_IP}
wsrep_cluster_name = "${CLUSTER_NAME}"
wsrep_cluster_address = gcomm://${CLUSTER_NODES}
wsrep_node_name = ${CLUSTER_NODE_NAME}
wsrep_slave_threads = 4
wsrep_sst_method = xtrabackup-v2
wsrep_sst_auth = sstuser:${CLUSTER_SECRET}
wsrep_sst_receive_address = ${CLUSTER_NODE_IP}
wsrep_provider_options = "ist.recv_addr=${CLUSTER_NODE_IP};gcache.dir=${DATADIR}/binlogs; gcache.size=${CLUSTER_CACHE_SIZE}"
[sst]
streamfmt = xbstream
[xtrabackup]
compress
compact
parallel = 2
compress_threads = 2
rebuild_threads = 2
EOF

#borrowed from klevo/docker-percona except we're going to stage it and then move it later to the correct file
cat > /root/postConfig.my.cnf <<-EOF
[client]
user=root
password=${MYSQL_ROOT_PASSWORD}
[mysqladmin]
user=root
password=${MYSQL_ROOT_PASSWORD}
[mysqldump]
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF

chmod 0600 /root/postConfig.my.cnf

echo "/root/postConfig.my.cnf deployed"

#removing this doesn't work without net=host settings
#mkdir -p /etc/keepalived
#cat > /etc/keepalived/keepalived.conf <<-EOF
#vrrp_script chk_pxc {
#        script "/usr/bin/clustercheck clustercheckuser ${CLUSTER_CHECK_PW} 1"
#        interval 1
#}
#vrrp_instance PXC {
#    state ${KEEPALIVE_STATE}
#    interface ${KEEPALIVE_INTERFACE}
#    virtual_router_id ${KEEPALIVE_ROUTER_ID}
#    priority 100
#    nopreempt
#    virtual_ipaddress {
#        ${KEEPALIVE_VIP}
#    }
#    track_script {
#        chk_pxc
#    }
#    notify_master "/bin/echo 'now master' > /tmp/keepalived.state"
#    notify_backup "/bin/echo 'now backup' > /tmp/keepalived.state"
#    notify_fault "/bin/echo 'now fault' > /tmp/keepalived.state"
#}
#EOF

