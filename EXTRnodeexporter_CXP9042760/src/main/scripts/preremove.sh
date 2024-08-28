#!/bin/bash

systemctl disable node-exporter.service
systemctl stop node-exporter.service
exit 0
