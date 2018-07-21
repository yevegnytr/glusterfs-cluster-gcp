#! /bin/bash
# setting up 3 nodes cluster
GFS_ENV="prod" #Set your environment
echo "--------------------------------"
echo "Environment is set to ${GFS_ENV}"
echo "--------------------------------"
#
echo "Checking if the script already ran once..."
if [ ! -f /root/bootstrap-script ];
  then
    echo "Script file was not found. Running script."
  else
    echo "Script file was found. Not running script."
    exit 1
fi

yum update -y
# Install latest LTS version of GlusterFS
yum install centos-release-gluster312 -y
yum install glusterfs-server nmap-ncat -y
systemctl start glusterd
systemctl enable glusterd
systemctl status glusterd
# OS storage tune up
sysctl -w vm.dirty_background_ratio=5
sysctl -w vm.dirty_ratio=10
# Storage setup
echo "n
p
1


w" | fdisk /dev/sdb
mkdir /data
mkfs.xfs -i size=512 /dev/sdb1
echo "/dev/sdb1       /data           xfs     defaults        1 2" >> /etc/fstab
mount -a
mkdir /data/brick1/gv0 -p

# GlusterFS setup
curl -s "http://metadata.google.internal/computeMetadata/v1/instance/hostname" -H "Metadata-Flavor: Google" | grep ${GFS_ENV}-glusterfs-node-1
if [ $? -eq 0 ];
  then
    echo "This is the correct host to launch gluster volume commands"
  else
    exit 1
fi

echo "${GFS_ENV}-glusterfs-node-1
${GFS_ENV}-glusterfs-node-2
${GFS_ENV}-glusterfs-node-3" > /tmp/gfs-peers
grep -v `hostname` /tmp/gfs-peers > /tmp/gfs-peers2
NODE_A=`head -1 /tmp/gfs-peers2`
NODE_B=`tail -1 /tmp/gfs-peers2`

until nc -z $NODE_A 24007;
  do
    echo "Waiting for `head -1 /tmp/gfs-peers2` to come online"
    sleep 1
done

until nc -z $NODE_B 24007;
  do
    echo "Waiting for `tail -1 /tmp/gfs-peers2` to come online"
    sleep 1
done

gluster peer probe $NODE_A
gluster peer probe $NODE_B
gluster peer status
rm /tmp/gfs-peers*

sleep 10
GFS_VOL_NAME="gv0"
gluster volume create $GFS_VOL_NAME replica 3 ${GFS_ENV}-glusterfs-node-1:/data/brick1/$GFS_VOL_NAME \
${GFS_ENV}-glusterfs-node-2:/data/brick1/$GFS_VOL_NAME \
${GFS_ENV}-glusterfs-node-3:/data/brick1/$GFS_VOL_NAME force

gluster volume start $GFS_VOL_NAME
gluster volume status $GFS_VOL_NAME

# Create a file that will prevent the script to run on next boot
touch /root/bootstrap-script
