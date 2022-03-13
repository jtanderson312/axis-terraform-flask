FROM python:3.6-alpine

RUN apk add build-base linux-headers
RUN pip install pipenv

# www-data user create
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

COPY . /app

WORKDIR /app

# .venv install to /app
ENV PIPENV_VENV_IN_PROJECT true

RUN pipenv install

CMD [ "pipenv", "run", "uwsgi", "--ini", "uwsgi.ini"]