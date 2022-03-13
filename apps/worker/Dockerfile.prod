FROM python:3.6-alpine
#FROM python:3.7-alpine             # celery and 3.7 do not get along

ENV CELERY_BROKER_URL redis://redis:6379/0
ENV CELERY_RESULT_BACKEND redis://redis:6379/0
ENV C_FORCE_ROOT true

# www-data user create
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

COPY . /queue
WORKDIR /queue

RUN pip install --upgrade pip && pip install pipenv 

RUN pipenv install --system --deploy --ignore-pipfile

ENTRYPOINT celery -A tasks worker --loglevel=info --uid=www-data --gid=www-data

