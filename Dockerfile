FROM ubuntu:16.04 
RUN apt-get -y update
RUN apt-get -y install ssh
RUN apt-get -y install rsync

# setup jdk
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get install -y wget && export PATH=$PATH:$JAVA_HOME/bin
RUN wget -O /tmp/hadoop-2.7.3.tar.gz http://apache.mirror.amaze.com.au/hadoop/common/stable/hadoop-2.7.3.tar.gz
# install hadoop
RUN tar -xzf /tmp/hadoop-2.7.3.tar.gz -C /usr/local
RUN cd /usr/local && ln -s ./hadoop-2.7.3 hadoop

# now setup environment
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

# prepare the datanode and namenode folder
RUN mkdir /opt/hadoop
RUN chmod o+rw /opt/hadoop
RUN mkdir /opt/hadoop/name
RUN mkdir /opt/hadoop/data

# copy over the hdfs-site.xml and core-site.xml file
COPY core-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
COPY hdfs-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
COPY mapred-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
COPY yarn-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/

# setup passphraseless ssh
#RUN ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa && cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys


RUN rm /etc/ssh/ssh_host_dsa_key
RUN rm /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -o -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -o -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -o -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 0600 ~/.ssh/authorized_keys

RUN /etc/init.d/ssh start

# ready on port 50070
RUN /usr/local/hadoop/bin/hdfs namenode -format
RUN /usr/local/hadoop/sbin/start-dfs.sh

# ready on port 8088
RUN /usr/local/hadoop/sbin/start-yarn.sh


