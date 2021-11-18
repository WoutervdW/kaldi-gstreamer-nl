FROM debian:9

ARG NUM_BUILD_CORES=2
ENV NUM_BUILD_CORES ${NUM_BUILD_CORES}

RUN apt-get update && \
    apt-get install -y \
    procps \
    autoconf \
    automake \
    bzip2 \
    g++ \
    git \
    gstreamer1.0-plugins-good \
    gstreamer1.0-tools \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-ugly  \
    libatlas3-base \
    libgstreamer1.0-dev \
    libtool-bin \
    make \
    python2.7 \
    python3 \
    python-pip \
    python-yaml \
    python-simplejson \
    python-gi \
    subversion \
    unzip \
    wget \
    build-essential \
    python-dev \
    sox \
    zlib1g-dev

RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    pip install ws4py==0.3.2 && \
    pip install tornado && \
    pip install redis && \
    ln -s /usr/bin/python2.7 /usr/bin/python ; ln -s -f bash /bin/sh

# RUN apt-get install -y wget bzip2

WORKDIR /opt

RUN wget http://www.digip.org/jansson/releases/jansson-2.7.tar.bz2 && \
    bunzip2 -c jansson-2.7.tar.bz2 | tar xf -  && \
    cd jansson-2.7 && \
    ./configure && make && make check &&  make install && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/jansson.conf && ldconfig && \
    rm /opt/jansson-2.7.tar.bz2 && rm -rf /opt/jansson-2.7

# RUN git clone https://github.com/kaldi-asr/kaldi && \
#     cd /opt/kaldi/tools && \
#     make -j $(nproc) && \
#     ./install_portaudio.sh && \
#     /opt/kaldi/tools/extras/install_mkl.sh && \
#     cd /opt/kaldi/src && ./configure --shared && \
#     sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
#     make clean -j $(nproc) && make -j $(nproc) depend && make -j $(nproc) && \

RUN apt-get install -y \
    time \
    sox \
    libsox-fmt-mp3 \
    default-jre \
    unzip \
    gfortran

RUN git clone https://github.com/kaldi-asr/kaldi

RUN cd /opt/kaldi/tools && \
    make -j${NUM_BUILD_CORES}

RUN cd /opt/kaldi/tools && \
    ./install_portaudio.sh

RUN cd /opt/kaldi/tools && \
    extras/install_mkl.sh

# RUN cd /opt/kaldi/src && ./configure --shared --mathlib=OPENBLAS && \

RUN cd /opt/kaldi/src && ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
    make depend && make -j${NUM_BUILD_CORES} && \
    cd /opt/kaldi/src/online && make depend && make -j${NUM_BUILD_CORES} && \
    cd /opt/kaldi/src/gst-plugin && make depend && make -j${NUM_BUILD_CORES} && \
    cd /opt && \
    git clone https://github.com/alumae/gst-kaldi-nnet2-online.git && \
    cd /opt/gst-kaldi-nnet2-online/src && \
    sed -i '/KALDI_ROOT?=\/home\/tanel\/tools\/kaldi-trunk/c\KALDI_ROOT?=\/opt\/kaldi' Makefile && \
    make depend && make && \
    rm -rf /opt/gst-kaldi-nnet2-online/.git/ && \
    find /opt/gst-kaldi-nnet2-online/src/ -type f -not -name '*.so' -delete && \
    rm -rf /opt/kaldi/.git && \
    rm -rf /opt/kaldi/windows/ /opt/kaldi/misc/ && \
    cd /opt && git clone https://github.com/alumae/kaldi-gstreamer-server.git && \
    rm -rf /opt/kaldi-gstreamer-server/.git/ && \
    rm -rf /opt/kaldi-gstreamer-server/test/

# Get the Dutch models and yaml on the docker and 'install' them
# COPY mod.tar.gz /opt/kaldi-gstreamer-server/

COPY start.sh stop.sh entrypoint.sh /opt/

# change the directory for wget to /models to add the model to that folder where it is (probably) by the application
RUN chmod +x /opt/start.sh && \
    chmod +x /opt/stop.sh && \
    chmod +x /opt/entrypoint.sh && \
    cd /opt/kaldi-gstreamer-server && \
    wget -nv http://nlspraak.ewi.utwente.nl/open-source-spraakherkenning-NL/mod.tar.gz && \
    tar -xvzf mod.tar.gz && rm mod.tar.gz

# The following bit gives you the scripts for offline transcription.
# It requires Java and some other things, so if you don't need it you
# may want to skip this section.

# COPY Kaldi_NL.tar.gz /opt/
# RUN  cd /opt && tar -xvzf Kaldi_NL.tar.gz && rm Kaldi_NL.tar.gz && \
#      cd /opt/Kaldi_NL && ln -s /opt/kaldi/egs/wsj/s5/utils utils && ln -s /opt/kaldi/egs/wsj/s5/steps steps
#
# COPY worker.py master_server.py /opt/kaldi-gstreamer-server/kaldigstserver/

RUN pip uninstall -y tornado && pip install tornado==4.4

ENTRYPOINT ["/opt/entrypoint.sh"]
# try out what this file adds