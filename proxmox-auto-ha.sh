#!/bin/bash

##################
#  Configuration #
##################

DEFAULT_HA_GROUP="NoAffinity"
DEFAULT_HA_STATUS="started"

##################
#     Main       #
##################

# Get running VMs ID
VMids=$(pvesh get /cluster/resources --type vm --output-format json|jq -r  '.[]|select(.status=="running")'|jq -r '.vmid')

for VMid in $VMids
do
  # Get current VM type (lxc or qemu)
  VMid_type=$(pvesh get /cluster/resources --type vm --output-format json|jq -r  ".[]|select(.vmid==${VMid})" | jq -r '.type')

  case $VMid_type in
  "qemu")
    search_pattern="^service[ \t]*vm:${VMid}[\t ]"
    ID="vm:${VMid}"
    ;;
  "lxc")
    search_pattern="^service[ \t]*ct:${VMid}[\t ]"
    ID="ct:${VMid}"
    ;;
  *)
    echo "unknown type:${}VMid_type for VM $VMid"
    break
    ;;
  esac

  # Search for current VM in HA resources
  ha-manager status |grep -E "$search_pattern" > /dev/null 2>&1
  res=$?

  # If VM not present in HA resources
  if [ $res -ne 0 ]
  then
   echo "Adding $ID to ${DEFAULT_HA_GROUP} HA group."
     ha-manager add $ID
     ha-manager set $ID --state $DEFAULT_HA_STATUS
     ha-manager set $ID --group $DEFAULT_HA_GROUP
     ha-manager set $ID --comment "auto added to ${DEFAULT_HA_GROUP} HA group by script ${BASH_SOURCE[0]} on $(hostname)."
  fi 
done
