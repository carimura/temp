FROM nginx
# Make all-to-v1 default config
COPY nginx-v1.conf /etc/nginx/nginx.conf
COPY nginx-v1.conf /etc/nginx/nginx-v1.conf
COPY nginx-v2.conf /etc/nginx/nginx-v2.conf
COPY nginx-50-50.conf /etc/nginx/nginx-50-50.conf
