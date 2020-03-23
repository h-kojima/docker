FROM docker.io/library/centos:centos6

RUN yum -y install httpd; \
    yum clean all

RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf; \
    echo "ServerName localhost:8080" >> /etc/httpd/conf/httpd.conf; \
    echo "Test HTTPD Container." > /var/www/html/index.html; \
    chmod -R 777 /var/log/httpd /var/run/httpd

EXPOSE 8080

USER 1001

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND;"]
