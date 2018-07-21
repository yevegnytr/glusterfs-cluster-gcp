#!/bin/bash
source ./settings.conf

#Create persistant disks
for (( i=1; i<=${COUNT}; i++ ))
  do
    gcloud compute --project=$GCP_PROJECT \
    disks create ${ENV}-gfs-data-disk-${i} --zone=${GCP_REGION}-${GCP_AZS[$i-1]} \
    --type=$PD_TYPE --description=$PD_DISCRIPT --size=$PD_SIZE \
    --verbosity=$GCLOUD_VERBOSITY
done

#Create compute instaces
for (( i=1; i<=${COUNT}; i++ ))
  do
    gcloud beta compute --project=$GCP_PROJECT instances create ${ENV}-glusterfs-node-${i} \
    --zone=${GCP_REGION}-${GCP_AZS[$i-1]} --machine-type=$GFS_NODE_TYPE --subnet=$GCP_SUBNET \
    --network-tier=PREMIUM --maintenance-policy=MIGRATE \
    --service-account=$GCP_SVC_ACC --scopes=$GCP_API_SCOPE --tags=$GCP_FW_TAG \
    --image=$GCP_IMAGE --image-project=$GCP_IMAGE_PRJ --boot-disk-size=$GCP_BOOT_DISK_SIZE \
    --boot-disk-type=$GCP_BOOT_DISK_TYPE \
    --boot-disk-device-name=glusterfs-node-${i} --disk=name=${ENV}-gfs-data-disk-${i},device-name=gfs-data-disk,mode=rw,boot=no \
    --metadata-from-file startup-script=$BOOSTRAP_SCRIPT \
    --verbosity=$GCLOUD_VERBOSITY
done
