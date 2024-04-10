FROM python:3.9-alpine
COPY /src /code
WORKDIR /code
RUN pip install -r requirements.txt
CMD ["python", "app.py"]