FROM ubuntu:20.10
MAINTAINER Randall Mawhinnie <Randall.Mawhinnie@virtustream.com>

# To get rid of error messages like "debconf: unable to initialize frontend: Dialog":
ENV SN_URL="vdossupport"
ENV SN_USER=""
ENV SN_PASSWD=""
ENV SN_MID_NAME=""

COPY asset /opt/

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get -q update && apt-get install -qy unzip supervisor wget curl httpie&& \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# Get ServiceNow instance stats and Download MidServer install pack
RUN snowinfo=$(curl GET https://${SN_URL}.service-now.com/stats.do) && \
    snow_build_date=$(echo $snowinfo | awk -F 'Build date: ' '{print $2}' | awk -F "<br/>" '{print $1}') && \
    snow_build_stamp=$(echo $snowinfo | awk -F 'MID buildstamp: ' '{print $2}' | awk -F "<br/>" '{print $1}') && \
    snow_build_year=$(echo $snow_build_date | awk -F '_' '{print $1}' | awk -F '-' '{print $3}') && \
    snow_build_month=$(echo $snow_build_date | awk -F '_' '{print $1}' | awk -F '-' '{print $2}') && \
    snow_build_day=$(echo $snow_build_date | awk -F '_' '{print $1}' | awk -F '-' '{print $1}') && \
    mid_download_url=https://install.service-now.com/glide/distribution/builds/package/mid/${snow_build_year}/${snow_build_day}/${snow_build_month}/mid.${snow_build_stamp}.linux.x86-64.zip && \
    curl GET ${mid_download_url} > /tmp/mid.zip

# Run Midserver Install
RUN unzip -d /opt/install /tmp/mid.zip && \
    mv /opt/install/agent/config.xml /opt/ && \
    chmod 755 /opt/init && \
    sed -i -e 's/\r$//' /opt/init && \
    rm -rf /tmp/*ls

ENV MID_HOME="/opt/agent"
ENV CONF_FILE="${MID_HOME}/config.xml"
ENV CONF_FILE_ORIGIN="/opt/config.xml"

EXPOSE 80 443

ENTRYPOINT ["/opt/init"]
CMD ["mid:start"]
