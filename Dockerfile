FROM nginx:alpine

# Copy the HTML file to nginx's default serving directory
COPY index.html /usr/share/nginx/html/

# Expose port 80 (matches your Helm chart configuration)
EXPOSE 80

# Start nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
