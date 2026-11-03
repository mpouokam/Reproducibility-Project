FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    libatlas-base-dev \
    liblapack-dev \
    gfortran \
    gcc \
    make \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --upgrade pip
RUN pip install numpy==1.14.5
RUN pip install scipy scikit-learn pandas matplotlib iced pastis openpyxl

CMD ["bash"]
