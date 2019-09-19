#!/bin/bash


export HOSTS="mszalay-zk-loadtest-1.vpc.cloudera.com mszalay-zk-loadtest-2.vpc.cloudera.com mszalay-zk-loadtest-3.vpc.cloudera.com mszalay-zk-loadtest-4.vpc.cloudera.com mszalay-zk-loadtest-5.vpc.cloudera.com mszalay-zk-loadtest-6.vpc.cloudera.com"

for host in $HOSTS
do
  shortname=`echo $host | cut -f1 -d .`

  # Create SSL keystore JKS to store local credentials
  keytool -genkeypair -alias $host -keyalg RSA -keysize 2048 -dname "cn=$host" -keypass password -keystore keystore-$shortname.jks -storepass password

  # Extract the (self)signed public key (certificate) from keystore
  keytool -exportcert -alias $host -keystore keystore-$shortname.jks -file $host.crt -rfc -storepass password

  # Store the public key in a common trust store contains certificates for all ZooKeeper instances
  keytool -importcert -alias $host -file $host.crt -keystore truststore.jks -storepass password -noprompt

  # convert JKS to P12
  keytool -importkeystore -srckeystore keystore-$shortname.jks -srcstorepass password -srckeypass password -srcalias $host -destalias $host -destkeystore keystore-$shortname.p12 -deststoretype PKCS12 -deststorepass password -destkeypass password

  # export secret key pem file from P12
  openssl pkcs12 -in keystore-$shortname.p12 -nodes -nocerts -password pass:password -out private-key-$shortname.pem
done



for host in $HOSTS
do
  shortname=`echo $host | cut -f1 -d .`

  scp ./keystore-$shortname.jks $host:/root/zookeeper/keystore.jks
  scp ./private-key-$shortname.pem $host:/root/zookeeper/private-key.pem
  scp ./*.crt $host:/root/zookeeper/
  scp ./truststore.jks $host:/root/zookeeper/truststore.jks
done
