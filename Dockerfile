FROM python:3.9-buster

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	connectome-workbench \
	git

COPY requirements.txt /requirements.txt
RUN pip install --upgrade pip \
	&& pip install -r /requirements.txt

COPY . /brainhack-project-2022
ENV PATH="${PATH}:/brainhack-project-2022/scripts"

ENTRYPOINT ["/bin/bash"]
