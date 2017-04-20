FROM ubuntu:16.04
MAINTAINER Tim.Qin<qinyujue@gmail.com>

RUN apt-get -y update
RUN apt-get -y install ssh rsync openjdk-8-jdk s3cmd

# setup jdk
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get install -y wget && export PATH=$PATH:$JAVA_HOME/bin
RUN wget -q -O /tmp/hadoop-2.7.3.tar.gz http://apache.mirror.amaze.com.au/hadoop/common/stable/hadoop-2.7.3.tar.gz
# install hadoop
RUN tar -xzf /tmp/hadoop-2.7.3.tar.gz -C /usr/local
RUN cd /usr/local && ln -s ./hadoop-2.7.3 hadoop && rm /tmp/hadoop-2.7.3.tar.gz

# now setup environment
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# setup sshd using port 11126
RUN echo '    Port 11126' >> /etc/ssh/ssh_config
RUN sed -ie 's/Port 22/Port 11126/g' /etc/ssh/sshd_config
RUN /etc/init.d/ssh start

# prepare the datanode and namenode folder
RUN mkdir /opt/hadoop 
RUN chmod o+rw /opt/hadoop
RUN mkdir /opt/hadoop/name
RUN mkdir /opt/hadoop/data

# add s3cfg file for s3cmd and minio bucket
ADD s3cfg /root/.s3cfg

# add over the hdfs-site.xml and core-site.xml file
ADD core-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
ADD hdfs-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
ADD mapred-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/
ADD yarn-site.xml /usr/local/hadoop-2.7.3/etc/hadoop/


ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
RUN echo 'export HADOOP_SSH_OPTS="-p 11126"' >> $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# setup passphraseless ssh
#RUN ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa && cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys


RUN $HADOOP_PREFIX/bin/hdfs namenode -format

# Generating ssh phraseless key
RUN ssh-keygen -q -N "" -t rsa -C noname -f /root/.ssh/id_rsa2 && cat /root/.ssh/id_rsa2.pub >> /root/.ssh/authorized_keys &&chmod 0600 ~/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config
ADD id_rsa /root/.ssh/id_rsa
ADD id_rsa.pub /root/.ssh/id_rsa.pub
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && chmod 400 ~/.ssh/id_rsa

# ready on port 50070
RUN /etc/init.d/ssh start && /usr/local/hadoop/sbin/start-dfs.sh && /usr/local/hadoop/sbin/start-yarn.sh

ADD start-keep-alive.sh /etc/bootstrap-hadoop.sh
RUN chown root:root /etc/bootstrap-hadoop.sh
RUN chmod 777 /etc/bootstrap-hadoop.sh
RUN chmod 777 $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

ENV BOOTSTRAP /etc/bootstrap-hadoop.sh

CMD ["/etc/bootstrap-hadoop.sh", "-d"]

EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
EXPOSE 9000 11126


