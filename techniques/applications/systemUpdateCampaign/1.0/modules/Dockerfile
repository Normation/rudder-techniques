ARG PYTHON_VERSION=3
FROM python:${PYTHON_VERSION}

ARG USER_ID=1000
COPY ci/user.sh .
RUN ./user.sh $USER_ID

COPY techniques/applications/systemUpdateCampaign/1.0/modules/dev-requirements.txt dev-requirements.txt
RUN pip install -r dev-requirements.txt
