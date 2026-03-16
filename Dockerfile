FROM python:3.11

WORKDIR /app

COPY . .

CMD ["python3","-m","http.server","8000"]