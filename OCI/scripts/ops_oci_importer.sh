#!/bin/sh

#  usage import.sh compartment-id image

cat << "_EOT"

_______________________   ________                               
__  __ \_  ____/___  _/   ____  _/______ _________ _______ _____ 
_  / / /  /     __  /      __  / __  __ `__ \  __ `/_  __ `/  _ \
/ /_/ // /___  __/ /      __/ /  _  / / / / / /_/ /_  /_/ //  __/
\____/ \____/  /___/      /___/  /_/ /_/ /_/\__,_/ _\__, / \___/ 
                                                   /____/        
________                               _____                     
____  _/______ __________________________  /_____________        
 __  / __  __ `__ \__  __ \  __ \_  ___/  __/  _ \_  ___/        
__/ /  _  / / / / /_  /_/ / /_/ /  /   / /_ /  __/  /            
/___/  /_/ /_/ /_/_  .___/\____//_/    \__/ \___//_/             
                  /_/                                            

_EOT

if test -z $2 
  then
    echo "\e[91mUsage:\e[0m $0 compartment-id image\n"
    exit
fi

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



