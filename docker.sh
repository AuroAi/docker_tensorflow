#!/bin/bash
# Fail on first error.
set -e

REPO=auroai/tensorflow

IMAGE_TAG="latest"

BASE_IMAGE=nvcr.io/nvidia/tensorflow:19.06-py3
#tensorflow/tensorflow:nightly-gpu-py3-jupyter	# 2.87 GB
#tensorflow/tensorflow:2.0.0-gpu-py3-jupyter	# 3.56 GB
#tensorflow/tensorflow:1.15.0-gpu-py3-jupyter	# 3.71 GB
#tensorflow/tensorflow:1.14.0-gpu-py3-jupyter	# 3.65 GB
#tensorflow/tensorflow:1.13.2-gpu-py3-jupyter	# 3.49 GB
#nvcr.io/nvidia/tensorflow:19.09-py3			# 8.44 GB
#ufoym/deepo:tensorflow-py36-cu100				# 4.94 GB
#ufoym/deepo:all-jupyter-py36-cu100				# 10.9 GB
#ufoym/deepo:all-jupyter-py36-cu90				# 9.76 GB




IMAGE="${REPO}:${IMAGE_TAG}"
BUILD_OPTS=""
echo "Image name : $IMAGE"

function show_usage()
{
cat <<EOF
Usage: $(basename $0) [options] ...
OPTIONS:
	build          Build Image
	pull           Pull Image
	push           Push Image
	del            Delete/Remove Image (locally)
	run	           Run the image
	-n             Build with no cache

EOF
exit 0
}

function pull()
{
	echo "Pulling image ${IMAGE}"
	docker pull ${IMAGE}
}

function push()
{
	echo "Pushing image ${IMAGE}"
	docker push ${IMAGE}
}

function run()
{
   echo "Run ${IMAGE}"
   docker run --gpus all \
	-it --rm --network host \
	-u`id -u $USER`:`id -u $USER` \
	-v /etc/passwd:/etc/passwd:ro \
	-v/etc/group:/etc/group:ro \
	-v /media:/media  \
	-v $PWD:/workspace\
	-e HISTFILE=/workspace/.bash_hist \
	-e PYTHONPATH=/workspace:/tensorflow/models/research:/tensorflow/models/research/slim \
	-w /workspace \
	${IMAGE}
}

function build()
{
	echo "Builing image ${IMAGE}"
	docker build  ${BUILD_OPTS} --build-arg FROM_IMAGE_NAME=${BASE_IMAGE} -t ${IMAGE} .
	echo "Built new image ${IMAGE}"
}

function del()
{
	echo "Deleting image ${IMAGE}"
	docker rmi ${IMAGE}
}


while [ $# -gt 0 ]
do
	case "$1" in
		build)
			build
			exit 0
			;;
		pull)
			pull
			exit 0
			;;
		push)
			push
			exit 0
			;;
		run)
			run
			exit 0
			;;
		del)
			del
			exit 0
				;;
		-h|--help)
			show_usage
			;;
		-n)
			BUILD_OPTS="--no-cache"
			;;
		*)
			echo -e "\033[93mWarning\033[0m: Unknown option: $1"
			show_usage
			exit 2
				;;
	esac
	shift
done



