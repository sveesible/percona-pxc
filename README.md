# percona-pxc1
docker example for PXC setup

### First build it
```bash
docker build -t pxc-sample1
```
### Second Setup a new public IP for this container 
(this adds it to your default interface, in my case em2 you might have eth0)
```bash
ip addr add 10.2.28.183/23 dev em2
```
you might need this too
```bash
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf && sysctl -p
```


### Third run the container with your own environment variables and map the ports to your new public IP
```bash
docker run --name pxc-node1 -e MYSQL_ROOT_PASSWORD=changeMe? -e CLUSTER_IP_ADDRESS=10.2.28.183 -e \
CLUSTER_NODE_NAME=pxc-cluster1 -e CLUSTER_NODES=10.2.28.184,10.2.28.185 -d -p 10.2.28.183:3306:3306 -p 10.2.28.183:4567:4567 \
-p 10.2.28.183:4568:4568 -p 10.2.28.183:4444:4444 pxc-sample1 bootstrap
```
#### Docker doesn't do well with source NAT so you might want to add a SNAT rule

```bash

 iptables -t nat -I POSTROUTING -s `docker inspect --format '{{ .NetworkSettings.IPAddress }}' "pxc-node1"` -j SNAT --to-source 10.2.28.183
```
### Then you can login with bash or mysql client
```bash
docker exec -it pxc-node1 bash
```
```bash
docker exec -it pxc-node1 mysql
```



### ENV Variables for this dockerfile
|ENV Name | Description | Default |
|---------|-------------|---------|
|PACKAGES | Probably shouldn't change this but you can | murp |
|DATADIR  | this will create and move the mysql data directory | /data |
|KEY_SERVER | where to get the gpg key, probably won't change, uses port 80 here to bypass firewall | hkp://http-keys.gnupg.net:80 |
|KEY_ID | The percona key | 1C4CBDCDCD2EFD2A |
|CUSTOM_APT_REPO | The percona repo | duh|
|CUSTOM_APT_NAME | percona | duh |
|MYSQL_ROOT_PASSWORD | a new root pw for you if you want | somethingSecure! |
|BUFFER_POOL_SIZE | INNODB Buffer pool, in case you want it to perform | 1G |
|CLUSTER_NODES | Comma separated list of IP addresses for your other cluster nodes | blank |
|CLUSTER_SECRET | password for the SST user account for recovery of State remotely | lessSecure? |
|CLUSTER_CHECK_PW | ClusterCheck password for loadbalancer and health check | clusterCheckPwd! |
|CLUSTER_NAME | Each cluster should have a unique name, this creates a sense of unity for the members | PXC1 |
|CLUSTER_NODE_NAME | Each cluster member needs its own name, so make sure to set this one | PXC-NODE1 |
|CLUSTER_NODE_IP | This is your public IP you want the world to see your cluster at | blank |
|CLUSTER_CACHE_SIZE | This is the byte size of the local gcache for Incremental State Transfer and recovery from short shutdowns | 2097152000 |

#### TODO
* Fix DATA_DIR so it can mount storage from Local Host disk
* Create Galera Arbitrator Node Docker
* create cron docker for backup scripts
* create keepalived docker for roaming VIP
