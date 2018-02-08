<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Docker/OpenShift のハンズオンテキスト](#dockeropenshift-%E3%81%AE%E3%83%8F%E3%83%B3%E3%82%BA%E3%82%AA%E3%83%B3%E3%83%86%E3%82%AD%E3%82%B9%E3%83%88)
  - [Dockerの利用準備](#docker%E3%81%AE%E5%88%A9%E7%94%A8%E6%BA%96%E5%82%99)
  - [Dockerの利用](#docker%E3%81%AE%E5%88%A9%E7%94%A8)
    - [Dockerイメージの検索](#docker%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%81%AE%E6%A4%9C%E7%B4%A2)
    - [Dockerイメージの取得と起動](#docker%E3%82%A4%E3%83%A1%E3%83%BC%E3%82%B8%E3%81%AE%E5%8F%96%E5%BE%97%E3%81%A8%E8%B5%B7%E5%8B%95)
    - [コンテナ内でのアプリケーションインストールと起動](#%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A%E5%86%85%E3%81%A7%E3%81%AE%E3%82%A2%E3%83%97%E3%83%AA%E3%82%B1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%81%A8%E8%B5%B7%E5%8B%95)
    - [コンテナの変更保存](#コンテナの変更保存)
    - [DockerfileによるカスタムDockerイメージの作成](#dockerfileによるカスタムdockerイメージの作成)
    - [プライベートリポジトリへのDockerイメージの保存](#プライベートリポジトリへのdockerイメージの保存)
    - [コンテナのメトリクス監視](#コンテナのメトリクス監視)
    - [Dockerのログ](#dockerのログ)
    - [Dockerの各種コマンド](#dockerの各種コマンド)
  - [OpenShiftの利用準備](#openshiftの利用準備)
  - [OpenShiftの利用](#openshiftの利用)
    - [OpenShift環境へのログインとアプリケーション作成(GUI編)](#openshift環境へのログインとアプリケーション作成gui編)
    - [OpenShift環境へのログインとアプリケーション作成(CLI編)](#openshift環境へのログインとアプリケーション作成cli編)
    - [OpenShiftでのアプリケーション更改](#openshiftでのアプリケーション更改)
    - [OpenShiftでのアプリケーション削除](#openshiftでのアプリケーション削除)
    - [OpenShiftの状態監視](#openshiftの状態監視)
    - [OpenShiftのログ](#openshiftのログ)
    - [OpenShiftの各種コマンド](#openshiftの各種コマンド)
  - [Revision History](#revision-history)
<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Docker/OpenShift のハンズオンテキスト
1台の物理マシンまたは仮想マシンを利用して、Docker及びDockerのプライベートリポジトリの利用手順をご紹介します。[Red Hatが公式に配布しているRHEL7のDockerイメージ](https://access.redhat.com/containers/#/repo/57ea8cee9c624c035f96f3af/image/docker)を利用して、簡単なWebサーバをデプロイします。さらに、同様のことをOpenShiftで実施するとどうなるかをご確認いただくことで、OpenShiftでのアプリケーション作成及びデプロイを体感していただきます。

## Dockerの利用準備
Step1. Docker環境をインストールする最新版のRHEL7マシン(物理でも仮想でも可)を1台用意します。評価版を利用する場合は、[こちら](https://access.redhat.com/products/red-hat-enterprise-linux/evaluation)から取得してください。

Step2. Docker及びDockerのプライベートリポジトリに関連したアプリケーションをインストールして起動します。下記コマンドでは、プライベートリポジトリを利用するためのDockerの設定ファイルや、ポート番号(TCP5000番)の開放も合わせて実施しています。
```
# subscription-manager register --auto-attach
# subscription-manager repos --disable="*"
# subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms
# yum -y install docker docker-distribution
#
# echo "INSECURE_REGISTRY='--insecure-registry localhost:5000'" >> /etc/sysconfig/docker
# firewall-cmd --zone=public --add-port=5000/tcp
# firewall-cmd --zone=public --add-port=5000/tcp --permanent
#
# systemctl start docker; systemctl start docker-distribution
# systemctl enable docker; systemctl enable docker-distribution
```

## Dockerの利用

### Dockerイメージの検索

docker search コマンドでパブリックなDockerリポジトリから利用出来るDockerイメージの一覧が出力出来ることを確認します。
```
# docker search rhel
... (中略) ...
docker.io    docker.io/dockerdev/rhel
redhat.com   registry.access.redhat.com/rhel7
... (中略) ...
```
なお、docker searchで検索可能なDockerイメージの全リストを出力するには、python, rubyパッケージをインストールし、curlコマンドと組み合わせて実行します。
```
# yum -y install python ruby
# curl -s https://registry.access.redhat.com/v1/search?q="*" | python -mjson.tool|ruby -ryaml -rjson -e 'puts YAML.dump(JSON.parse(STDIN.read))'|grep "name:" |less
  name: registry-haproxyorg.rhcloud.com/haproxy/rhel-haproxy:1.5.12
  name: registry-crunchydata.rhcloud.com/crunchydata/crunchy-postgresql:9.4.4
... (中略) ...
```
プライベートリポジトリのDockerイメージの一覧を出力する際には、docker-distributionサービスが起動しているサーバに問い合わせをする必要があります。2017年2月現在、docker searchコマンドにdocker-distributionサービスが対応していないので、curlコマンドでDockerイメージの一覧を確認します。

```
# curl http://localhost:5000/v2/_catalog
{"repositories":["CUSTOM_DOCKER_IMAGE_NAME"]}
```

### Dockerイメージの取得と起動
Red Hatの公式リポジトリからRHEL7のDockerイメージをPULLします。

```
# docker pull rhel7
Using default tag: latest
Trying to pull repository registry.access.redhat.com/rhel7 ... 
latest: Pulling from registry.access.redhat.com/rhel7
7bd78273b666: Pull complete 
c196631bd9ac: Pull complete 
Digest: sha256:0614d58c96e8d1a04a252880a6c33b48b4685cafae048a70dd9e821edf62cab9
```
RHEL7のDockerイメージを取得できたことを確認します。
```
# docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
registry.access.redhat.com/rhel7   latest              e4b79d4d89ab        3 weeks ago         192.5 MB
```
このイメージをベースとしたコンテナを「test1」という名前で起動してみます。`/bin/bash`を指定してコンテナに対する標準入出力を有効にしておきます。また、起動中のコンテナから抜けるには、`Ctrl-p + Ctrl-q` を入力します。
```
# docker run -it --name=test1 rhel7 /bin/bash
[root@fbcf771e295c /]# cat /etc/hostname 
fbcf771e295c
[root@fbcf771e295c /]# [root@localhost ~]#
```
抜けた後に、docker psコマンドで現在起動中のコンテナ一覧を確認します。

```
# docker ps
CONTAINER ID        IMAGE                              COMMAND             CREATED             STATUS              PORTS               NAMES
fbcf771e295c        rhel7                              "/bin/bash"         2 minutes ago       Up 2 minutes                            test1
```
再びコンテナに入るには、docker attachコマンドを実施します。

```
# docker attach test1
[root@fbcf771e295c /]#
```

### コンテナ内でのアプリケーションインストールと起動
コンテナ内でyumを使ってWebサーバ(httpdパッケージ)とPHPをインストールします。

```
[root@fbcf771e295c /]# yum -y install httpd php
... (中略) ...
Installed:
  httpd.x86_64 0:2.4.6-45.el7 php.x86_64 0:5.4.16-42.el7                                                           
... (中略) ...
Complete!
[root@fbcf771e295c /]# 
```

ローカルのyumリポジトリを利用している場合は、docker cpコマンドを利用して、コンテナにyumのプライベートリポジトリを利用するための設定ファイルをコピーする必要があります。

```
# docker cp /etc/yum.repos.d/local.repo test1:/etc/yum.repos.d/
[root@fbcf771e295c /]# cat <<EOF > /etc/yum.repos.d/local.repo
[local]
name=local-repo
baseurl=http://localhost/public/packages/
gpgcheck=0
enabled=1
EOF
[root@fbcf771e295c /]#
```
コンテナ内でテスト用のPHPファイルを配置してhttpdプログラムを実行し、Webサービスを起動します。

```
[root@fbcf771e295c /]# mkdir /var/www/html/public
[root@fbcf771e295c /]# cat <<EOF > /var/www/html/public/test.php
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: left;">
<?php
echo "Hello Docker 2017-02-01";
echo "<br>";
echo "<br>";
echo "Host Name: ";
echo gethostname();
echo "<br>";
echo "Host IP: ";
echo $_SERVER["SERVER_ADDR"];
echo "<br>";
echo "Client IP: ";
echo $_SERVER["REMOTE_ADDR"];
?>
</div>
</body>
</html>
EOF
[root@fbcf771e295c /]#
[root@fbcf771e295c /]# /usr/sbin/httpd -DFOREGROUND
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message
```

端末の別タブまたはFirefoxから、コンテナのIPアドレスにアクセスてWebサービスが起動し、コンテナのホスト名`fbcf771e295c`/コンテナのIPアドレス`172.17.0.2`/アクセス元のホストのIPアドレス`172.17.0.1`を確認します。コンテナには、Dockerサービスが起動された際に自動的に作成される仮想ネットワークアドレス`172.17.0.0/16`から、空いているIPアドレスが順番に割り当てられていきます。

```
$ curl http://172.17.0.2/public/test.php
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: left;">
Hello Docker 2017-02-01<br><br>Host Name: fbcf771e295c<br>Host IP: 172.17.0.2<br>Client IP: 172.17.0.1</div>
</body>
</html>
```

```
Hello Docker 2017-02-01

Host Name: fbcf771e295c
Host IP: 172.17.0.2
Client IP: 172.17.0.1
```

### コンテナの変更保存
コンテナから抜けた後に、これまで加えてきた変更をベースとなるDockerイメージにコミットして、新しいDockerイメージとして保存します。

```
[root@fbcf771e295c /]# /usr/sbin/httpd -DFOREGROUND
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message

^C[root@fbcf771e295c /]# [root@localhost ~]# 
# docker commit test1 myrhel7_httpd01
sha256:04ec21f714818636aaf8afd4f9cff33c775fb9902279756d8b361041824f2b29
# docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
myrhel7_httpd01                    latest              04ec21f71481        14 seconds ago      265.3 MB
registry.access.redhat.com/rhel7   latest              e4b79d4d89ab        3 weeks ago         192.5 MB
```

これで、myrhel7_httpd01という名前のDockerイメージが新しく保存されました。このmyrhel7_httpd01からtest2という名前のコンテナを起動し、Webサービスを起動してみます。

```
# docker run -it --name=test2 myrhel7_httpd01 /bin/bash
[root@53de6ea3c782 /]# 
[root@53de6ea3c782 /]# /usr/sbin/httpd -DFOREGROUND
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.3. Set the 'ServerName' directive globally to suppress this message
```

再び、Firefoxなどから`http://172.17.0.3/public/test.php`にアクセスして、コンテナ内のWebサービスが起動していることを確認します。

### DockerfileによるカスタムDockerイメージの作成
こうしたコンテナの変更及びWebサービスなどの自動起動を有効化した、Dockerイメージを作成するための手順をDockerfileというテキストファイルに記載できます。まずはDockerfileで扱うホスト上のファイルを、特定のディレクトリ(Dockerfileファイルが保存されている場所)にコピー及び作成して、Dockerfileを作成します。
```
# mkdir buiddir
# cp /etc/yum.repos.d/local.repo /root/builddir/
# cat <<EOF > builddir/run-apache.sh

#!/bin/bash

rm -rf /run/httpd/*
exec /usr/sbin/httpd -D FOREGROUND
EOF
# cat <<EOF > builddir/test.php
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: left;">
<?php
echo "Hello Docker 2017-02-01";
echo "<br>";
echo "<br>";
echo "Host Name: ";
echo gethostname();
echo "<br>";
echo "Host IP: ";
echo $_SERVER["SERVER_ADDR"];
echo "<br>";
echo "Client IP: ";
echo $_SERVER["REMOTE_ADDR"];
?>
</div>
</body>
</html>
EOF
#
# cat <<EOF > builddir/Dockerfile

# My Docker Image
# Version 0.1

FROM rhel7 ### カスタマイズするベースイメージを指定
MAINTAINER Hirofumi Kojima

ADD local.repo /etc/yum.repos.d/local.repo  ### ホストの/root/builddir/local.repoファイルをコンテナの/etc/yum.repos.d/に追加
RUN yum -y install httpd php  ### コンテナ内でのコマンド実行
RUN yum clean all
ADD test.php /var/www/html/test.php
RUN echo "Apache is running." > /var/www/html/index.html

EXPOSE 80  ### コンテナでの開放するポート番号を指定
ADD run-apache.sh /root/run-apache.sh
RUN chmod +x /root/run-apache.sh

CMD ["/root/run-apache.sh"] ### コンテナ実行時に起動するコマンド(/root/run-apache.shを実行)
EOF
# ls /root/builddir/
Dockerfile local.repo run-apache.sh test.php
```

そして、docker buildコマンドで、myrhel7_httpd02という名前のDockerイメージを作成します。

```
# docker build -t myrhel7_httpd02 /root/builddir
Sending build context to Docker daemon  5.12 kB
Step 1 : FROM rhel7
 ---> e4b79d4d89ab
Step 2 : MAINTAINER Hirofumi Kojima
 ---> Using cache
 ---> 6f5863cb74dc
Step 3 : ADD guest.repo /etc/yum.repos.d/local.repo
 ---> Using cache
 ---> efea24e18b40
Step 4 : RUN yum -y install httpd php
 ---> Using cache
 ---> 0bed9b113bb1
Step 5 : RUN yum clean all
 ---> Using cache
 ---> 98c409997e7f
Step 6 : ADD test.php /var/www/html/test.php
 ---> d0f7a2895813
Removing intermediate container 372e4f9afba0
Step 7 : RUN echo "Apache is running." > /var/www/html/index.html
 ---> Running in ff708fa4c3e5
 ---> 6310c2a3df77
Removing intermediate container ff708fa4c3e5
Step 8 : EXPOSE 80
 ---> Running in 54256caa3d4c
 ---> fca39981080e
Removing intermediate container 54256caa3d4c
Step 9 : ADD run-apache.sh /root/run-apache.sh
 ---> 23b86b832c05
Removing intermediate container 091ac94807d2
Step 10 : RUN chmod +x /root/run-apache.sh
 ---> Running in c7af82fa1ff2
 ---> d766694a6f1a
Removing intermediate container c7af82fa1ff2
Step 11 : CMD /root/run-apache.sh
 ---> Running in d280a1344047
 ---> f8370c6e0f52
Removing intermediate container d280a1344047
Successfully built f8370c6e0f52
#
# docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
myrhel7_httpd02                    latest              f8370c6e0f52        5 seconds ago       267 MB
myrhel7_httpd01                    latest              04ec21f71481        16 minutes ago      265.3 MB
registry.access.redhat.com/rhel7   latest              e4b79d4d89ab        3 weeks ago         192.5 MB
```

作成したmyrhel7_httpd02から、コンテナを実行します。`-p 8080:80`で、ホストの8080番ポートにアクセスすると、コンテナの80番ポートにアクセスするようなポートフォワーディングの設定を行います。`-d`を指定することで、バックグラウンドでのコンテナ起動を行います。

```
# docker run -p 8080:80 -d --name=test3 myrhel7_httpd02
419a59e32b32ab138b031f55b7831c4159447a389bf52e1da3896992e6df1446
# docker ps
CONTAINER ID        IMAGE                              COMMAND                 CREATED             STATUS              PORTS                  NAMES
419a59e32b32        myrhel7_httpd02                    "/root/run-apache.sh"   4 seconds ago       Up 1 seconds        0.0.0.0:8080->80/tcp   test3
53de6ea3c782        myrhel7_httpd01                    "/bin/bash"             14 minutes ago      Up 14 minutes                              test2
fbcf771e295c        rhel7                              "/bin/bash"             46 minutes ago      Up 46 minutes                              test1
# curl http://localhost:8080
Apache is running.
# curl http://localhost:8080/test.php
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: left;">
Hello Docker 2017-02-01<br><br>Host Name: 419a59e32b32<br>Host IP: 172.17.0.4<br>Client IP: 172.17.0.1</div>
</body>
</html>
```

### プライベートリポジトリへのDockerイメージの保存

作ったDockerイメージをDockerのプライベートリポジトリにPUSHします。DockerイメージのPUSHには、ローカルのDockerイメージに、「このDockerイメージは、あのプライベートリポジトリに存在します」というタグを付けて、そのタグが付けられたDockerイメージをPUSHします。

```
# docker tag myrhel7_httpd02 localhost:5000/myrhel7_ver01
# docker images
REPOSITORY                               TAG                 IMAGE ID            CREATED             SIZE
myrhel7_httpd02                          latest              f8370c6e0f52        9 minutes ago       267 MB
localhost:5000/myrhel7_ver02             latest              f8370c6e0f52        9 minutes ago       267 MB
myrhel7_httpd01                          latest              04ec21f71481        26 minutes ago      265.3 MB
registry.access.redhat.com/rhel7         latest              e4b79d4d89ab        3 weeks ago         192.5 MB
# docker push localhost:5000/myrhel7_ver01
The push refers to a repository [localhost:5000/myrhel7_ver01]
ca2837254b63: Pushed 
5e774d72e558: Pushed 
aec628fdc617: Pushed 
d282d15d462d: Pushed 
5a3f8f3594d7: Pushed 
27c780537ee3: Pushed 
c002924c33dd: Pushed 
0a081b45cb84: Mounted from rhel7 
df9d2808b9a9: Mounted from rhel7 
latest: digest: sha256:c0377175ad942ff605a405ee99744c72d851bd50ea78f87a2b15208d503edda9 size: 2194
#
# curl http://localhost:5000/v2/_catalog
{"repositories":["myrhel7_ver01"]}
```
### コンテナのメトリクス監視

docker statsコマンドで、CPU, メモリ, ネットワークI/O, ブロックI/Oの情報を確認できます。

```
# docker stats test1 test2
CONTAINER           CPU %               MEM USAGE / LIMIT       MEM %               NET I/O             BLOCK I/O           PIDS
76af75bb883d        0.00%               4.062 MiB / 1.796 GiB   0.22%               788 B / 648 B       5.138 MB / 0 B      1
7a0f8cedbdd6        0.00%               4.07 MiB / 1.796 GiB    0.22%               1.296 kB / 648 B    5.391 MB / 0 B      1
```

### Dockerのログ

Dockerのログについては、Dockerサービスで設定するロギング・ドライバ(デフォルトはjournald)と、各コンテナ実行時に指定するロギング・ドライバ(デフォルトはDockerサービスで指定しているロギング・ドライバ)を利用して出力できます。ロギング・ドライバについては、syslog/journald/fluentd/awslogsなどを利用できます。

例を挙げておくと、journaldをロギング・ドライバとして利用する場合のDockerサービスのログは、次のコマンドを実行して取得できます。

```
# journalctl -u docker.service
```

また、各コンテナのログは`docker logs`コマンドで取得できます。`-f`オプションを利用してログをリアルタイムに出力することもできます。

```
### Follow the log of CONTAINER_NAME ###
# docker logs -f CONTAINER_NAME
```

詳細は[こちら](https://docs.docker.com/engine/admin/logging/overview/)をご参照ください。

### Dockerの各種コマンド

イメージの検索/取得/削除やコンテナ実行/停止などのコマンド一覧は[こちら](https://docs.docker.com/engine/reference/commandline/docker/)をご参照ください。

## OpenShiftの利用準備
Step1. OpenShift環境をインストールする最新版のRHEL7マシン(物理でも仮想でも可)を1台用意します。

Step2. OpenShift環境をインストールするためのリポジトリ利用を有効にし、SSH鍵の作成及びローカルホストへのコピーを実行します。評価版のOpenShiftを利用する場合は、[こちら](https://access.redhat.com/products/red-hat-openshift-container-platform/evaluation)から取得してください。
```
# subscription-manager register --auto-attach
# subscription-manager repos --disable="*"
# subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-ose-3.4-rpms
#
# ssh-keygen -f /root/.ssh/id_rsa -N ''
# ssh-copy-id root@OPENSHIFT_HOST_FQDN
```
Step3. OpenShiftのインストールにはAnsibleのPlaybookを活用します。Playbook実行用のInventoryファイルを作成し、OpenShift用に用意されたPlaybookを実行します。
```
# cat <<EOF > /root/sample-single-hosts

# Create an OSEv3 group that contains the master, nodes, etcd, and lb groups.
# The lb group lets Ansible configure HAProxy as the load balancing solution.
# Comment lb out if your load balancer is pre-configured.
[OSEv3:children]
masters
nodes

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
ansible_ssh_user=root
deployment_type=openshift-enterprise

# Uncomment the following to enable htpasswd authentication; defaults to DenyAllPasswordIdentityProvider.
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/or
igin/master/htpasswd'}]

# default subdomain to use for exposed routes
openshift_master_default_subdomain=OPENSHIFT_HOST_IP_ADDRESS.xip.io

[masters]
OPENSHIFT_HOST_FQDN

[nodes]
OPENSHIFT_HOST_FQDN openshift_node_labels="{'region': 'infra'}" openshift_schedulable=true
EOF
# yum -y install atomic-openshift-utils
# ansible-playbook -i /root/sample-single-hosts /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```
Step4. HTPasswd認証用のファイルを作成して、OpenShiftの設定ファイルとしてコピーします。
```
# yum -y install httpd-tools
# htpasswd -c /root/htpasswd USERNAME
# cp /root/htpasswd /etc/origin/master/
```

Step5. `https://OPENSHIFT_HOST_FQDN:8443` にアクセスするとOpenShiftのログイン画面が表示されるので、Step4.で作成したユーザ情報を利用してログインし、OpenShift環境を利用できるようになります。

## OpenShiftの利用
### OpenShift環境へのログインとアプリケーション作成(GUI編)

Step1. `https://OPENSHIFT_HOST_FQDN:8443`にFirefoxからアクセスして、ログインします。その後、[New Project]をクリックして適当な名前を入力し、[create]をクリックします。この作業で、OpenShift環境でアプリケーションを開発する場所となるプロジェクトを作成します。

Step2. カタログ画面から[PHP]をクリックして、[PHP, 5.6 - latest]の下にある[select]をクリックします。Nameに適当な名前を入力し、Git Repository URLには、`https://github.com/h-kojima/php-hello-world`を入力して、[Create]をクリックします。

Step3. [Continue to overview]をクリックすると、以下のような画面が表示されますので、ここからDockerイメージ作成時のログやコンテナの実行状態を確認できます。なお、OpenShiftではコンテナをPodという単位で管理しています。Podには、コンテナとOpenShift環境でコンテナを起動する際の設定(開放するポート番号やコンテナに接続する外部ストレージなど)が含まれます。

![Overview](https://github.com/h-kojima/docker/blob/master/handson/images/openshift-01.png)

Step4. 作成したアプリケーション名の右横にあるURLをクリックするとコンテナ内でPHPが実施され、Podのホスト名/PodのIPアドレス/Podへのアクセス元のIPアドレスが確認できます。

```
Hello OpenShift 2017-02-01

Host Name: testphp01-1-nwhpg
Host IP: 10.128.0.21
Client IP: 10.128.0.1
```

このPodのIPアドレスは、OpenShift環境内で利用される[SDN(OpenvSwitch)](https://docs.openshift.com/container-platform/latest/architecture/additional_concepts/sdn.html)により作成された、外部ホストと通信するためのネットワークアドレスから割り当てられたものになります。

### OpenShift環境へのログインとアプリケーション作成(CLI編)
上記GUI編で紹介した手順を、CLIで実行します。まずOpenShift環境にログインして、プロジェクトを作成します。
```
$ sudo yum -y install atomic-openshift-clients ### OpenShiftのCLIツールインストール
$ oc login -u USERNAME https://OPENSHIFT_HOST_FQDN:8443 ### OpenShift環境へのリモートログイン
$ oc new-project NEW_PROJECT
```

次にPHPアプリケーションを作成します。Gitリポジトリを指定するだけでアプリケーションを作成できます。作成するアプリケーションの名前を`--name=`で指定することができます。
```
$ oc new-app --name=testphp01 https://github.com/h-kojima/php-hello-world
--> Found image ee994c3 (3 weeks old) in image stream "openshift/php" under tag "5.6" for "php"

    Apache 2.4 with PHP 5.6 
    ----------------------- 
    Platform for building and running PHP 5.6 applications

    Tags: builder, php, php56, rh-php56

    * The source repository appears to match: php
    * A source build using source code from https://github.com/h-kojima/php-hello-world will be created
      * The resulting image will be pushed to image stream "testphp01:latest"
      * Use 'start-build' to trigger a new build
    * This image will be deployed in deployment config "testphp01"
    * Port 8080/tcp will be load balanced by service "testphp01"
      * Other containers can access this service through the hostname "testphp01"

--> Creating resources ...
    imagestream "testphp01" created
    buildconfig "testphp01" created
    deploymentconfig "testphp01" created
    service "testphp01" created
--> Success
    Build scheduled, use 'oc logs -f bc/testphp01' to track its progress.
    Run 'oc status' to view your app.
```
作成されたアプリケーションは、OpenShift環境の各Node(Podを実行するサーバ)のコンテナ間通信ネットワークで利用されるIPアドレスを指定してアクセスできます。このIPアドレスは、oc getコマンドで確認できます。

```
$ oc get pods
NAME                        READY     STATUS      RESTARTS   AGE
testphp01-1-build           0/1       Completed   0          1h
testphp01-1-e1vjn           1/1       Running     0          1h
$ oc get service
NAME              CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
testphp01         172.30.135.78    <none>        8080/TCP   1h
$ curl http://172.30.135.78:8080
Hello OpenShift 2017-02-01<br><br>Host Name: testphp01-1-e1vjn<br>Host IP: 10.128.0.15<br>Client IP: 10.128.0.1
```

ただし、このネットワーク`172.30.0.0/16`のアクセスは各Nodeでしか利用できませんので、このままだと作成したアプリケーションは外部ホストからアクセスできません。そこで、oc exposeコマンドを実行して、各Nodeでのみ利用できるサービスアクセス用のIPアドレスへの経路情報を追加します。

```
$ oc expose service testphp01
route "testphp01" exposed
$ oc get route
NAME       HOST/PORT                                PATH       SERVICES   PORT       TERMINATION
testphp01  testphp01-test1.192.168.199.201.xip.io              testphp01  8080-tcp
```

oc exposeコマンドにより自動的に外部からのアクセス用URLが作成され、このURLを利用して外部ホストからアプリケーションにアクセスできるようになります。こうしたPodへのルーティングを定義することで、対応する設定がOpenShift環境のHAProxyコンテナ(OpenShift環境の管理者のみアクセス可能なdefaultプロジェクトに`router`という名前のPodとして存在)に自動的に追加され、URLベースのルーティングが実施されるようになります。

```
# oc login -u system:admin ### OpenShift環境の管理者権限でログイン
# oc get pods -n default
NAME                       READY     STATUS    RESTARTS   AGE
docker-registry-2-ez0qq    1/1       Running   0          4h
registry-console-1-etpcf   1/1       Running   0          4h
router-1-5qv9k             1/1       Running   0          4h
# oc rsh router-1-5qv9k
sh-4.2$ pwd   
/var/lib/haproxy/conf
sh-4.2$ ls
cert_config.map		 os_edge_http_be.map	    os_sni_passthrough.map
default_pub_keys.pem	 os_edge_http_expose.map    os_tcp_be.map
error-page-503.http	 os_edge_http_redirect.map  os_wildcard_domain.map
haproxy-config.template  os_http_be.map
haproxy.config		 os_reencrypt.map
sh-4.2$ grep -inr testphp01 *
haproxy.config:329:backend be_http_test1_testphp01
os_http_be.map:1:testphp01-test1.192.168.199.201.xip.io test1_testphp01
sh-4.2$ 
```

上記の例では、[xip.io](https://xip.io/)をURLのドメインとして利用することで、`192.168.199.201`にアクセスするようになっています。また、各Nodeのカーネルが持っているパケット転送情報が、OpenShiftにより自動的に修正されます。そうした転送情報は各Nodeでiptablesコマンドを実施して確認できます。

<details>
  <summary>iptablesコマンドの実行結果</summary>
  
```
# iptables -t nat -nL
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
KUBE-HOSTPORTS  all  --  0.0.0.0/0            0.0.0.0/0            /* kube hostport portals */ ADDRTYPE match dst-type LOCAL
KUBE-SERVICES  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
KUBE-PORTALS-CONTAINER  all  --  0.0.0.0/0            0.0.0.0/0            /* handle ClusterIPs; NOTE: this must be before the NodePort rules */
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
KUBE-NODEPORT-CONTAINER  all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL /* handle service NodePorts; NOTE: this must be the last rule in the chain */

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
KUBE-HOSTPORTS  all  --  0.0.0.0/0            0.0.0.0/0            /* kube hostport portals */ ADDRTYPE match dst-type LOCAL
KUBE-SERVICES  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
KUBE-PORTALS-HOST  all  --  0.0.0.0/0            0.0.0.0/0            /* handle ClusterIPs; NOTE: this must be before the NodePort rules */
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL
KUBE-NODEPORT-HOST  all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL /* handle service NodePorts; NOTE: this must be the last rule in the chain */

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
KUBE-POSTROUTING  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes postrouting rules */
MASQUERADE  all  --  10.128.0.0/14        0.0.0.0/0           
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
MASQUERADE  all  --  127.0.0.0/8          0.0.0.0/0            /* SNAT for localhost access to hostports */

Chain DOCKER (2 references)
target     prot opt source               destination         
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           

Chain KUBE-HOSTPORTS (2 references)
target     prot opt source               destination         

Chain KUBE-MARK-DROP (0 references)
target     prot opt source               destination         
MARK       all  --  0.0.0.0/0            0.0.0.0/0            MARK or 0x8000

Chain KUBE-MARK-MASQ (9 references)
target     prot opt source               destination         
MARK       all  --  0.0.0.0/0            0.0.0.0/0            MARK or 0x4000

Chain KUBE-NODEPORT-CONTAINER (1 references)
target     prot opt source               destination         

Chain KUBE-NODEPORT-HOST (1 references)
target     prot opt source               destination         

Chain KUBE-NODEPORTS (1 references)
target     prot opt source               destination         

Chain KUBE-PORTALS-CONTAINER (1 references)
target     prot opt source               destination         

Chain KUBE-PORTALS-HOST (1 references)
target     prot opt source               destination         

Chain KUBE-POSTROUTING (1 references)
target     prot opt source               destination         
MASQUERADE  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes service traffic requiring SNAT */ mark match 0x4000/0x4000

Chain KUBE-SEP-E6FCPDCMETE5EXAN (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/router:1936-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/router:1936-tcp */ tcp to:192.168.199.201:1936

Chain KUBE-SEP-EF7GKFWKZ4WP7JXO (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  10.128.0.16          0.0.0.0/0            /* test1/testphp01:8080-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* test1/testphp01:8080-tcp */ tcp to:10.128.0.16:8080

Chain KUBE-SEP-GBVT36Z4B6AP2NV2 (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/router:80-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/router:80-tcp */ tcp to:192.168.199.201:80

Chain KUBE-SEP-HOZY5FQONK4KRS62 (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/router:443-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/router:443-tcp */ tcp to:192.168.199.201:443

Chain KUBE-SEP-K76MIZIYCKNTVL37 (2 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/kubernetes:https */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https */ recent: SET name: KUBE-SEP-K76MIZIYCKNTVL37 side: source mask: 255.255.255.255 tcp to:192.168.199.201:8443

Chain KUBE-SEP-KJVBOMJWEK6E2NP2 (2 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/kubernetes:dns-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns-tcp */ recent: SET name: KUBE-SEP-KJVBOMJWEK6E2NP2 side: source mask: 255.255.255.255 tcp to:192.168.199.201:8053

Chain KUBE-SEP-MHACG4N3F3GEY3TM (2 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  10.128.0.13          0.0.0.0/0            /* default/docker-registry:5000-tcp */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/docker-registry:5000-tcp */ recent: SET name: KUBE-SEP-MHACG4N3F3GEY3TM side: source mask: 255.255.255.255 tcp to:10.128.0.13:5000

Chain KUBE-SEP-N7YD3EF5Y5FBWLG6 (2 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  192.168.199.201        0.0.0.0/0            /* default/kubernetes:dns */
DNAT       udp  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns */ recent: SET name: KUBE-SEP-N7YD3EF5Y5FBWLG6 side: source mask: 255.255.255.255 udp to:192.168.199.201:8053

Chain KUBE-SEP-VNGJR45WXLZKZWIE (1 references)
target     prot opt source               destination         
KUBE-MARK-MASQ  all  --  10.128.0.12          0.0.0.0/0            /* default/registry-console:registry-console */
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            /* default/registry-console:registry-console */ tcp to:10.128.0.12:9090

Chain KUBE-SERVICES (2 references)
target     prot opt source               destination         
KUBE-SVC-GQKZAHCS5DTMHUQ6  tcp  --  0.0.0.0/0            172.30.195.156       /* default/router:80-tcp cluster IP */ tcp dpt:80
KUBE-SVC-IKV43KYNCXS2W7KZ  tcp  --  0.0.0.0/0            172.30.195.156       /* default/router:443-tcp cluster IP */ tcp dpt:443
KUBE-SVC-BA6I5HTZKAAAJT56  tcp  --  0.0.0.0/0            172.30.0.1           /* default/kubernetes:dns-tcp cluster IP */ tcp dpt:53
KUBE-SVC-DEGCXZMVXZMJS2KL  tcp  --  0.0.0.0/0            172.30.107.125       /* default/registry-console:registry-console cluster IP */ tcp dpt:9000
KUBE-SVC-4JCRTMMYZAAYMIJ2  tcp  --  0.0.0.0/0            172.30.195.156       /* default/router:1936-tcp cluster IP */ tcp dpt:1936
KUBE-SVC-ECTPRXTXBM34L34Q  tcp  --  0.0.0.0/0            172.30.235.3         /* default/docker-registry:5000-tcp cluster IP */ tcp dpt:5000
KUBE-SVC-NPX46M4PTMTKRN6Y  tcp  --  0.0.0.0/0            172.30.0.1           /* default/kubernetes:https cluster IP */ tcp dpt:443
KUBE-SVC-3VQ6B3MLH7E2SZT4  udp  --  0.0.0.0/0            172.30.0.1           /* default/kubernetes:dns cluster IP */ udp dpt:53
KUBE-SVC-GQPEHBXW7I4ENKJT  tcp  --  0.0.0.0/0            172.30.73.69         /* test1/testphp01:8080-tcp cluster IP */ tcp dpt:8080
KUBE-NODEPORTS  all  --  0.0.0.0/0            0.0.0.0/0            /* kubernetes service nodeports; NOTE: this must be the last rule in this chain */ ADDRTYPE match dst-type LOCAL

Chain KUBE-SVC-3VQ6B3MLH7E2SZT4 (1 references)
target     prot opt source               destination         
KUBE-SEP-N7YD3EF5Y5FBWLG6  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns */ recent: CHECK seconds: 180 reap name: KUBE-SEP-N7YD3EF5Y5FBWLG6 side: source mask: 255.255.255.255
KUBE-SEP-N7YD3EF5Y5FBWLG6  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns */

Chain KUBE-SVC-4JCRTMMYZAAYMIJ2 (1 references)
target     prot opt source               destination         
KUBE-SEP-E6FCPDCMETE5EXAN  all  --  0.0.0.0/0            0.0.0.0/0            /* default/router:1936-tcp */

Chain KUBE-SVC-BA6I5HTZKAAAJT56 (1 references)
target     prot opt source               destination         
KUBE-SEP-KJVBOMJWEK6E2NP2  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns-tcp */ recent: CHECK seconds: 180 reap name: KUBE-SEP-KJVBOMJWEK6E2NP2 side: source mask: 255.255.255.255
KUBE-SEP-KJVBOMJWEK6E2NP2  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:dns-tcp */

Chain KUBE-SVC-DEGCXZMVXZMJS2KL (1 references)
target     prot opt source               destination         
KUBE-SEP-VNGJR45WXLZKZWIE  all  --  0.0.0.0/0            0.0.0.0/0            /* default/registry-console:registry-console */

Chain KUBE-SVC-ECTPRXTXBM34L34Q (1 references)
target     prot opt source               destination         
KUBE-SEP-MHACG4N3F3GEY3TM  all  --  0.0.0.0/0            0.0.0.0/0            /* default/docker-registry:5000-tcp */ recent: CHECK seconds: 180 reap name: KUBE-SEP-MHACG4N3F3GEY3TM side: source mask: 255.255.255.255
KUBE-SEP-MHACG4N3F3GEY3TM  all  --  0.0.0.0/0            0.0.0.0/0            /* default/docker-registry:5000-tcp */

Chain KUBE-SVC-GQKZAHCS5DTMHUQ6 (1 references)
target     prot opt source               destination         
KUBE-SEP-GBVT36Z4B6AP2NV2  all  --  0.0.0.0/0            0.0.0.0/0            /* default/router:80-tcp */

Chain KUBE-SVC-GQPEHBXW7I4ENKJT (1 references)
target     prot opt source               destination         
KUBE-SEP-EF7GKFWKZ4WP7JXO  all  --  0.0.0.0/0            0.0.0.0/0            /* test1/testphp01:8080-tcp */

Chain KUBE-SVC-IKV43KYNCXS2W7KZ (1 references)
target     prot opt source               destination         
KUBE-SEP-HOZY5FQONK4KRS62  all  --  0.0.0.0/0            0.0.0.0/0            /* default/router:443-tcp */

Chain KUBE-SVC-NPX46M4PTMTKRN6Y (1 references)
target     prot opt source               destination         
KUBE-SEP-K76MIZIYCKNTVL37  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https */ recent: CHECK seconds: 180 reap name: KUBE-SEP-K76MIZIYCKNTVL37 side: source mask: 255.255.255.255
KUBE-SEP-K76MIZIYCKNTVL37  all  --  0.0.0.0/0            0.0.0.0/0            /* default/kubernetes:https */
```
</details>

### OpenShiftでのアプリケーション更改

OpenShift環境とGitリポジトリがネットワーク通信が可能な場合、Gitリポジトリで管理するソースコードに対して変更がコミットされた場合、自動的にDockerイメージのリビルドとアプリケーションのデプロイを実行するように設定できます。ただし、GitリポジトリからOpenShift環境へのネットワーク通信が不可、ソースコード変更のタイミングで毎回Dockerイメージをリビルドしたくない、といった場合はソースコード変更コミットの後で、手動でDockerイメージのリビルドができます。<br>
<br>
リビルドするための方法は、左側の[Builds]メニューから確認できます。

![ビルド設定](https://github.com/h-kojima/docker/blob/master/handson/images/openshift-02.png)

GUIの場合はこの画面の[Start Build]をクリックします。CLIの場合は以下のコマンドを実行します。

```
$ oc start-build testphp -n PROJECT_NAME
```
リビルドを実行すると、Dockerイメージが新しく作成されて新規Podが起動した後に、古いPodが削除されることをGUIで確認できます。

### OpenShiftでのアプリケーション削除
プロジェクト内のアプリケーションや関連する設定などを一括削除する場合は、oc deleteコマンドを実行します。

```
$ oc delete all --all -n PROJECT_NAME
```
プロジェクトもまとめて消去する場合は、oc delete PROJECTコマンドを実行します。

```
$ oc delete PROJECT_NAME
```
なお、アプリケーション作成時に`-l LABEL_NAME`オプションを指定することで、アプリケーション削除の際に特定のアプリケーションのみ削除することもできます。

```
$ oc new-app ...(中略)... -l LABEL_NAME -n PROJECT_NAME  ### アプリケーションと関連設定に特定のラベルを付ける
$ oc delete all -l LABEL_NAME -n PROJECT_NAME  ### 特定のラベルが付いたアプリケーションと関連設定を一括削除
```

### OpenShiftの状態監視
OpenShift環境では各Pod(Pod内のプロセス含む)やNodeの状態監視を行っており、Pod(Pod内のプロセス含む)やNodeに障害が発生した場合、正常NodeでPodを自動的に再起動します。

### OpenShiftのログ
アプリケーション作成やデプロイ時などのログについてはGUIから確認できる他に、[oc logsコマンド](https://docs.openshift.com/container-platform/latest/cli_reference/basic_cli_operations.html#troubleshooting-and-debugging-cli-operations)でも確認できます。OpenShiftではアプリケーションだけでなく、アプリケーション作成やデプロイ専用のPodも作成されるのでこれらのPodに関するログも見ることができます。

### OpenShiftの各種コマンド
アプリケーションの作成・削除や、アプリケーションへのログインなどのコマンド一覧は[こちら](https://docs.openshift.com/container-platform/latest/cli_reference/basic_cli_operations.html)をご参照ください。

## Revision History

2017-02-07 初版リリース

