FROM quay.io/generic/rhel6

RUN yum -y install httpd; \
    yum clean all

RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf; \
    echo "ServerName localhost:8080" >> /etc/httpd/conf/httpd.conf; \
    echo "Test HTTPD Container." > /var/www/html/index.html

EXPOSE 8080

USER 1001

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND;"]
