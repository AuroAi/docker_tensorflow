ARG FROM_IMAGE_NAME=nvcr.io/nvidia/tensorflow:19.09-py3
FROM ${FROM_IMAGE_NAME} 

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /workspace

RUN apt-get update -y && apt install -y protobuf-compiler python-tk git 

RUN PROTOC_VERSION=3.0.0 && \
    PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    curl -OL https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/$PROTOC_ZIP && \
    unzip -o $PROTOC_ZIP -d /usr/local bin/protoc && \
    rm -f $PROTOC_ZIP


# Get the tensorflow models research directory, and move it into tensorflow
RUN mkdir -p /tensorflow && \
    git clone -b r1.13.0 --depth 1 https://github.com/tensorflow/models.git && \
    mv models /tensorflow/models


RUN git clone -b r1.13 --depth 1 https://github.com/tensorflow/tpu.git  && \
    mv tpu /tensorflow/tpu_models



# Install gcloud and gsutil commands
# https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y



# Install the Tensorflow Object Detection API from here
# https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/installation.md

# Install object detection api dependencies

# Install Python dependencies
RUN python3 -m pip install --upgrade --no-cache-dir pip \
 && python3 -m pip install --no-cache-dir \
      Cython==0.28.4 \
      Pillow \
      absl-py \
      contextlib2 \
      lxml \
      matplotlib \
      mlperf-compliance==0.0.10 \
      numpy \
      opencv-python==3.4.1.15 \
      pandas \
      pycocotools==2.0.0 \
      setuptools \
      yacs 

#Alternative to `pip install pycocotools`
#RUN git clone --depth 1 https://github.com/cocodataset/cocoapi.git && \
#    cd cocoapi/PythonAPI && \
#    make -j8 && \
#    cp -r pycocotools /tensorflow/models/research && \
#    cd ../../ && \
#    rm -rf cocoapi


# Run protoc on the object detection repo
RUN cd /tensorflow/models/research && \
    protoc object_detection/protos/*.proto --python_out=.


# Set the PYTHONPATH to finish installing the API
ENV PYTHONPATH $PYTHONPATH:/tensorflow/models/research:/tensorflow/models/research/slim
RUN ln -sf /usr/bin/python3 /usr/bin/python & \
    ln -sf /usr/bin/pip3 /usr/bin/pip

