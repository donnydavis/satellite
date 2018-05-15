#!/bin/bash
#######################################################################################
# Only set the value to y if you are initalizing the export or have made repo updates #
#######################################################################################
export initrepos=y
#####################################
# Don't forget to set your org name #
#####################################
export org=myorgname

if [[ $initrepo =~ ^[Yy]$ ]]
then
  hammer content-view version list --organization $org
  for i in $(hammer repository list |grep yum |awk '{print $1}'); do hammer repository update --id $i --download-policy immediate; done
  for i in $(hammer repository list |grep yum |awk '{print $1}'); do hammer repository synchronize --id $i ; done
fi

hammer content-view version export   --organization $org   --content-view "Default Organization View"   --version "1.0"
