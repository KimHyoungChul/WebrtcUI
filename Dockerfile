FROM ubuntu:14.04

RUN apt-get update && \
  apt-get install -y software-properties-common && \
  add-apt-repository ppa:openjdk-r/ppa && \
  apt-get update && \
  apt-get install -y openjdk-8-jdk curl git build-essential ca-certificates-java && \
  apt-get clean && \
  rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

ENV ANDROID_SDK /opt/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_SDK}/tools:${ANDROID_SDK}/platform-tools

# Install dependencies
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g gulp && npm install -g bower && npm install -g cordova@6.5.0

# Get android sdk for linux and install needed packages
RUN apt-get install -y wget && \
  apt-get install -y unzip

RUN wget -q https://dl.google.com/android/repository/tools_r25.2.5-linux.zip -O android-sdk-linux.zip
RUN unzip -q android-sdk-linux.zip -d ${ANDROID_SDK} && \
  chown -R root.root ${ANDROID_SDK}

RUN mkdir -p ${ANDROID_SDK}/licenses && \
    echo 8933bad161af4178b1185d1a37fbf41ea5269c55 > ${ANDROID_SDK}/licenses/android-sdk-license && \
    echo 84831b9409646a918e30573bab4c9c91346d8abd > ${ANDROID_SDK}/licenses/android-sdk-preview-license && \
    echo d975f751698a77b662f1254ddbeed3901e976f5a > ${ANDROID_SDK}/licenses/intel-android-extra-license

RUN yes | ${ANDROID_SDK}/tools/bin/sdkmanager "platform-tools"
RUN yes | ${ANDROID_SDK}/tools/bin/sdkmanager "platforms;android-25"
RUN yes | ${ANDROID_SDK}/tools/bin/sdkmanager "build-tools;25.0.3"
RUN yes | ${ANDROID_SDK}/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
