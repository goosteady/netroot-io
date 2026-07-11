FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY styles.css /usr/share/nginx/html/styles.css
COPY nginx.conf /etc/nginx/conf.d/default.conf
CMD RESOLVER=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf) && \
    sed -i "s/\$PORT/$PORT/g; s/\$RESOLVER/$RESOLVER/g" /etc/nginx/conf.d/default.conf && \
    nginx -g 'daemon off;'
