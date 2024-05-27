# flask.Dockerfile for the Flask App
FROM python:3.8-slim

WORKDIR /app


ARG FLASK_KEY
ARG SPOTIFY_CLIENT_ID
ARG SPOTIFY_SECRET_ID
ARG ENVIRONMENT


ENV FLASK_KEY=$FLASK_KEY
ENV SPOTIFY_CLIENT_ID=$SPOTIFY_CLIENT_ID
ENV SPOTIFY_SECRET_ID=$SPOTIFY_SECRET_ID
ENV ENVIRONMENT=$ENVIRONMENT

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
