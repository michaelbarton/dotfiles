#
# Docker image target for linting the markdown files.
#
FROM node:fermium-alpine3.15 AS prettier
RUN npm install --save-dev --save-exact prettier
