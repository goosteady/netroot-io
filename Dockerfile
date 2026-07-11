FROM nginx:alpine
COPY breviarium/index.html /usr/share/nginx/html/breviarium/index.html
COPY styles.css /usr/share/nginx/html/breviarium/styles.css
COPY netroot/index.html /usr/share/nginx/html/netroot/index.html
COPY styles.css /usr/share/nginx/html/netroot/styles.css
COPY nginx.conf /etc/nginx/conf.d/default.conf
CMD sed -i "s/\$PORT/$PORT/g" /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
