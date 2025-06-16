FROM registry.access.redhat.com/ubi10/python-312-minimal:latest

LABEL org.opencontainers.image.name="example-01"

COPY requirements.txt .
RUN pip install -r requirements.txt
