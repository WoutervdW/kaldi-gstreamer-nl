#!/bin/bash
export LC_ALL=C.UTF-8
/opt/start.sh -y /opt/kaldi-gstreamer-server/dutch_nnet3.yaml
tail -f /dev/null