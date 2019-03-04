import os
from celery import Celery

env=os.environ

CELERY_BROKER_URL=env.get('CELERY_BROKER_URL','redis://redis:6379/0')
#CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'amqp://admin:mypass@rabbitmq//'),
CELERY_RESULT_BACKEND=env.get('CELERY_RESULT_BACKEND','redis://redis:6379/0')


celery= Celery('tasks',
                broker=CELERY_BROKER_URL,
                backend=CELERY_RESULT_BACKEND)