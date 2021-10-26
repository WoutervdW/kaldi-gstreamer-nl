#!/bin/bash
export LC_ALL=C.UTF-8
/opt/start.sh -y /opt/models/online_nnet2.yaml
tail -f /dev/null