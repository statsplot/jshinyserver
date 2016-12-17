FROM ubuntu:16.04

EXPOSE 8888

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV R_BASE_VERSION 3.3.2
ENV VER master
ENV DL_TOOL wget
ENV DL_PATH /opt/shiny/download/master
ENV INS_PATH /opt/shiny

# Install Java.
RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java8-installer && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/oracle-jdk8-installer

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker && \
    mkdir /home/docker && \
    chown docker:docker /home/docker && \
    addgroup docker staff

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ed \
        less \
        locales \
        vim-tiny \
        wget \
        ca-certificates \
        apt-transport-https \
        fonts-texgyre && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.utf8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

RUN echo "deb https://cran.rstudio.org/bin/linux/ubuntu xenial/" > /etc/apt/sources.list.d/rstudio.list 

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base=${R_BASE_VERSION}* \
        r-base-dev=${R_BASE_VERSION}* \
        r-recommended=${R_BASE_VERSION}* \
        sudo \
        gdebi-core \
        pandoc \
        pandoc-citeproc \
        libcurl4-gnutls-dev \
        libcairo2-dev \
        libxt-dev && \
        echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site &&  \
    rm -rf /tmp/downloaded_packages/ /tmp/*.rds && \
    rm -rf /var/lib/apt/lists/*

# Download and install shiny server
RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')"

RUN mkdir -p ${DL_PATH} && \
      mkdir -p ${INS_PATH} && \
      wget -nv -O ${DL_PATH}/${VER}.tar.gz https://github.com/statsplot/jshinyserver/archive/${VER}.tar.gz && \ 
      tar zxf ${DL_PATH}/${VER}.tar.gz -C ${DL_PATH} && \
      ln -s  ${DL_PATH}/jshinyserver-*/source/Objects ${INS_PATH}/server && \
      mkdir -p ${INS_PATH}/server/logs ${INS_PATH}/server/pid && \
      cp -R /usr/local/lib/R/site-library/shiny/examples/* ${INS_PATH}/server/shinyapp && \
      echo "[Done] jShiny server ${VER} installed to ${INS_PATH}/server"

RUN echo '#!/bin/sh\nsu -c "/bin/sh ${INS_PATH}/server/start.sh ${INS_PATH}/server && tail -f ${INS_PATH}/server/logs/server_cmd.log" docker ' >> /usr/bin/shiny-server.sh && \
      touch ${INS_PATH}/server/config/applist.update && \
      chown -R docker:docker ${INS_PATH}/server/* /usr/bin/shiny-server.sh && \
      chmod -R 700 ${INS_PATH}/server/* /usr/bin/shiny-server.sh

# Define default command.
CMD ["/usr/bin/shiny-server.sh"]
