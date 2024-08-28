#!/bin/sh

# /opt/ericsson/rhq-cli folder is not removed on removal of RHQ Agent
# So we are removing /opt/ericsson/rhq-cli folder if exist when
# node exporter is installed on blades

deleteOldRhqCliData(){
 if [ -d /opt/ericsson/rhq-cli ]
  then
   /bin/rm -rf /opt/ericsson/rhq-cli
  fi
 }

deleteOldRhqCliData
