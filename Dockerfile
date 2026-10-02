FROM python:3.14-slim
WORKDIR /app
COPY server.py index.html clem_thumb.jpg pi-menu-card.html ./
CMD ["python3", "server.py"]
