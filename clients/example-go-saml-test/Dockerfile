# syntax=docker.io/docker/dockerfile:1.7

FROM mcr.microsoft.com/playwright:v1.42.1
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . ./
CMD ["npm", "run", "test"]
