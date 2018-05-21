#!/bin/bash
emailid=$1
groupName=terraform-lab-user

aws iam remove-user-from-group --user-name $emailid --group-name $groupName
aws iam delete-login-profile --user-name $emailid
keys=$(aws iam list-access-keys --user-name $emailid|jq .AccessKeyMetadata[].AccessKeyId|sed -e 's/\"//g')
for key in $keys;
  do aws iam delete-access-key --user-name $emailid --access-key-id $key;
done;
aws iam delete-user --user-name $emailid

