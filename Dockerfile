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

ENV WEBSOCKET_SERVER=https://vaas-backend.sklirg.io
RUN yarn build

FROM nginx:mainline-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=0 /app/dist/ /var/www/html
