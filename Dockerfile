FROM python:3.9-buster

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	connectome-workbench \
	git bc

COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip \
	&& pip install -r /requirements.txt

COPY ./scripts /scripts
ENV PATH="${PATH}:/scripts/"

ENTRYPOINT ["/bin/bash"]
