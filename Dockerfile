FROM python:3.8-slim
WORKDIR /app
COPY /app .
RUN pip install flask
# Expose the port Flask runs on
EXPOSE 5000
CMD ["python", "app.py"]
