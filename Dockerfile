FROM node:14-stretch

WORKDIR /app

RUN yarn global add elm

COPY package.json .
COPY yarn.lock .

RUN yarn install --frozen-lockfile

COPY src/ src/
COPY js/ js/
COPY elm.json .
COPY index.html .

ENV WEBSOCKET_SERVER=https://vaas-backend.sklirg.io/
RUN yarn build

FROM iamfreee/docker-nginx-static-spa:latest

COPY --from=0 /app/dist/ /var/www/html
