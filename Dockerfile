#
# Docker image target for linting the markdown files.
#
FROM node:lts-alpine AS prettier
RUN npm install --save-dev --save-exact prettier


#
# Docker image target for linting python files.
#
FROM python:3.12 AS black
RUN pip3 install black
