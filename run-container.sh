#!/bin/bash
docker run -it -p 8080:80 -v ~/Projects/docker-kaldi-gstreamer-server/models:/opt/models jcsilva/docker-kaldi-gstreamer-server:latest /bin/bash
