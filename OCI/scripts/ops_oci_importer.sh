#!/bin/sh

#  usage import.sh compartment-id image

cat << "_EOT"
                  ____  _________
 ___  ___  ___   / __ \/ ___/  _/
/ _ \/ _ \(_-<  / /_/ / /___/ /
\___/ .__/___/  \____/\___/___/
   /_/_                    __
  /  _/_ _  ___  ___  ____/ /____ ____
 _/ //  ' \/ _ \/ _ \/ __/ __/ -_) __/
/___/_/_/_/ .__/\___/_/  \__/\__/_/
         /_/
_EOT

oci_namespace=`oci os ns get --query "data" --raw-output`

tmp_bucket="_tmp_images"

echo "\nCreating temporary bucket:"
oci os bucket create --compartment-id $1 --name $tmp_bucket --query "data.id" --raw-output

oci os object put --bucket-name $tmp_bucket --file $2 --query "etag"

echo "\nImporting image:"

oci_image_id=`oci compute image import from-object --display-name $2 --launch-mode PARAVIRTUALIZED --source-image-type QCOW2 --bucket-name $tmp_bucket --name $2 --namespace $oci_namespace --compartment-id $1 --query "data.id" --raw-output`

echo "\n\e[92m... this will take some minutes ...\e[39m"

watch -x -n 10 -g -d oci compute image get --image-id $oci_image_id --query 'data."lifecycle-state"'

echo "\n\e[92mimport of imaged \e[39m$oci_image_id\e[92m finished.\n\nNow cleaning up...\e[39m"

echo "\n\e[91mDelete temporary object:\e[39m"
oci os object delete --bucket-name $tmp_bucket --object-name $2

echo "\n\e[91mDelete temporary bucket:\e[39m"
oci os bucket delete --bucket-name $tmp_bucket


