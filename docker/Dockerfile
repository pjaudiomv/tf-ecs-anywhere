FROM ubuntu:22.04
RUN apt-get update && apt-get install nginx openssl -y && \
    echo "<html><h1>Hello World ECS</h1></html>" > /var/www/html/index.html && \
    ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir /etc/nginx/ssl && chmod 600 /etc/nginx/ssl && \
    openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes \
        -out /etc/nginx/ssl/nginx.test.internal.crt \
        -keyout /etc/nginx/ssl/nginx.test.internal.key \
        -subj "/C=US/ST=Massachusetts/L=DC/O=Anywhere/OU=Intranet/CN=nginx.test.internal"
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
