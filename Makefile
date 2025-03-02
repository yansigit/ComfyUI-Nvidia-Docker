SHELL := /bin/bash
.PHONY: all

DOCKER_CMD=docker
DOCKER_PRE="NVIDIA_VISIBLE_DEVICES=all"
DOCKER_BUILD_ARGS=

COMFYUI_NVIDIA_DOCKER_VERSION=20250227

COMFYUI_CONTAINER_NAME=comfyui-nvidia-docker

COMPONENTS_DIR=components
DOCKERFILE_DIR=Dockerfile

# Get the list of all the base- files in COMPONENTS_DIR
DOCKER_ALL=$(shell ls -1 ${COMPONENTS_DIR}/base-* | perl -pe 's%^.+/base-%%' | perl -pe 's%\.Dockerfile%%' | sort)
# Remove CUDA 12.8 entries for the time being
#DOCKER_ALL=$(shell ls -1 ${COMPONENTS_DIR}/base-* | perl -pe 's%^.+/base-%%' | perl -pe 's%\.Dockerfile%%' | sort | grep -v 12.8)

all:
	@if [ `echo ${DOCKER_ALL} | wc -w` -eq 0 ]; then echo "No images candidates to build"; exit 1; fi
	@echo "Available ${COMFYUI_CONTAINER_NAME} ${DOCKER_CMD} images to be built (make targets):"
	@echo -n "      "; echo ${DOCKER_ALL} | sed -e 's/ /\n      /g'
	@echo ""
	@echo "build:          builds all"

build: ${DOCKER_ALL}

${DOCKERFILE_DIR}:
	@mkdir -p ${DOCKERFILE_DIR}

${DOCKER_ALL}: ${DOCKERFILE_DIR}
	@echo ""; echo ""; echo "===== Building ${COMFYUI_CONTAINER_NAME}:$@"
	@$(eval DOCKERFILE_NAME="${DOCKERFILE_DIR}/$@.Dockerfile")
	@cat ${COMPONENTS_DIR}/base-$@.Dockerfile > ${DOCKERFILE_NAME}
	@cat ${COMPONENTS_DIR}/part1-common.Dockerfile >> ${DOCKERFILE_NAME}
	@$(eval VAR_NT="${COMFYUI_CONTAINER_NAME}-$@")
	@echo "-- Docker command to be run:"
	@echo "docker buildx ls | grep -q ${COMFYUI_CONTAINER_NAME} && echo \"builder already exists -- to delete it, use: docker buildx rm ${COMFYUI_CONTAINER_NAME}\" || docker buildx create --name ${COMFYUI_CONTAINER_NAME}"  > ${VAR_NT}.cmd
	@echo "docker buildx use ${COMFYUI_CONTAINER_NAME} || exit 1" >> ${VAR_NT}.cmd
	@echo "BUILDX_EXPERIMENTAL=1 ${DOCKER_PRE} docker buildx debug --on=error build --progress plain --platform linux/amd64 ${DOCKER_BUILD_ARGS} \\" >> ${VAR_NT}.cmd
	@echo "  --build-arg COMFYUI_NVIDIA_DOCKER_VERSION=\"${COMFYUI_NVIDIA_DOCKER_VERSION}\" \\" >> ${VAR_NT}.cmd
	@echo "  --build-arg BUILD_BASE=\"$@\" \\" >> ${VAR_NT}.cmd
	@echo "  --tag=\"${COMFYUI_CONTAINER_NAME}:$@\" \\" >> ${VAR_NT}.cmd
	@echo "  -f ${DOCKERFILE_NAME} \\" >> ${VAR_NT}.cmd
	@echo "  --load \\" >> ${VAR_NT}.cmd
	@echo "  ." >> ${VAR_NT}.cmd
	@cat ${VAR_NT}.cmd | tee ${VAR_NT}.log.temp
	@echo "" | tee -a ${VAR_NT}.log.temp
	@echo "Press Ctl+c within 5 seconds to cancel"
	@for i in 5 4 3 2 1; do echo -n "$$i "; sleep 1; done; echo ""
# Actual build
	@chmod +x ./${VAR_NT}.cmd
	@script -a -e -c ./${VAR_NT}.cmd ${VAR_NT}.log.temp; exit "$${PIPESTATUS[0]}"
	@mv ${VAR_NT}.log.temp ${VAR_NT}.log
	@rm -f ./${VAR_NT}.cmd

###### clean

docker_tag_list:
	@${DOCKER_CMD} images --filter "label=comfyui-nvidia-docker-build"

docker_buildx_rm:
	@docker buildx rm ${COMFYUI_CONTAINER_NAME}

# Get the list of all existing Docker images
DOCKERHUB_REPO="mmartial"
DOCKER_PRESENT=$(shell for i in ${DOCKER_ALL}; do image="${COMFYUI_CONTAINER_NAME}:$$i"; if docker images --format "{{.Repository}}:{{.Tag}}" | grep -v ${DOCKERHUB_REPO} | grep -q $$image; then echo $$image; fi; done)

docker_rmi:
	@echo -n "== Images to delete: "
	@echo ${DOCKER_PRESENT} | wc -w
	@if [ `echo ${DOCKER_PRESENT} | wc -w` -eq 0 ]; then echo "No images to delete"; exit 1; fi
	@echo ${DOCKER_PRESENT} | sed -e 's/ /\n/g'
	@echo ""
	@echo "Press Ctl+c within 5 seconds to cancel"
	@for i in 5 4 3 2 1; do echo -n "$$i "; sleep 1; done; echo ""
	@for i in ${DOCKER_PRESENT}; do docker rmi $$i; done
	@echo ""; echo " ** Remaining image with the build label:"
	@make docker_tag_list


############################################### For maintainer only
###### push -- will only proceed with existing ("present") images

# user the highest numbered entry
#LATEST_ENTRY=$(shell echo ${DOCKER_ALL} | sed -e 's/ /\n/g' | tail -1)
# use the previous to last entry as the candidate: 12.8 is for 50xx series GPUs, not making it the default yet)
LATEST_ENTRY=$(shell echo ${DOCKER_ALL} | sed -e 's/ /\n/g' | tail -2 | head -1)

LATEST_CANDIDATE=$(shell echo ${COMFYUI_CONTAINER_NAME}:${LATEST_ENTRY})

docker_tag:
	@if [ `echo ${DOCKER_PRESENT} | wc -w` -eq 0 ]; then echo "No images to tag"; exit 1; fi
	@echo "== About to tag:"
	@for i in ${DOCKER_PRESENT}; do image_out1="${DOCKERHUB_REPO}/$$i-${COMFYUI_NVIDIA_DOCKER_VERSION}"; image_out2="${DOCKERHUB_REPO}/$$i-latest"; echo "  ++ $$i -> $$image_out1"; echo "  ++ $$i -> $$image_out2"; done
	@if echo ${DOCKER_PRESENT} | grep -q ${LATEST_CANDIDATE}; then image_out="${DOCKERHUB_REPO}/${COMFYUI_CONTAINER_NAME}:latest"; echo "  ++ ${LATEST_CANDIDATE} -> $$image_out"; else echo "  -- Unable to find latest candidate: ${LATEST_CANDIDATE}"; fi
	@echo ""
	@echo "tagging for hub.docker.com upload -- Press Ctl+c within 5 seconds to cancel"
	@for i in 5 4 3 2 1; do echo -n "$$i "; sleep 1; done; echo ""
	@for i in ${DOCKER_PRESENT}; do image_out1="${DOCKERHUB_REPO}/$$i-${COMFYUI_NVIDIA_DOCKER_VERSION}"; image_out2="${DOCKERHUB_REPO}/$$i-latest"; docker tag $$i $$image_out1; docker tag $$i $$image_out2; done
	@if echo ${DOCKER_PRESENT} | grep -q ${LATEST_CANDIDATE}; then image_out="${DOCKERHUB_REPO}/${COMFYUI_CONTAINER_NAME}:latest"; docker tag ${LATEST_CANDIDATE} $$image_out; fi

DOCKERHUB_READY=$(shell for i in ${DOCKER_ALL}; do image="${DOCKERHUB_REPO}/${COMFYUI_CONTAINER_NAME}:$$i"; image1=$$image-${COMFYUI_NVIDIA_DOCKER_VERSION}; image2=$$image-latest; if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q $$image1; then echo $$image1; fi; if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q $$image2; then echo $$image2; fi; done)
DOCKERHUB_READY_LATEST=$(shell image="${DOCKERHUB_REPO}/${COMFYUI_CONTAINER_NAME}:latest"; if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q $$image; then echo $$image; else echo ""; fi)


docker_push:
	@if [ `echo ${DOCKERHUB_READY} | wc -w` -eq 0 ]; then echo "No images to push"; exit 1; fi
	@echo "== About to push:"
	@for i in ${DOCKERHUB_READY} ${DOCKERHUB_READY_LATEST}; do echo "  ++ $$i"; done
	@echo "pushing to hub.docker.com -- Press Ctl+c within 5 seconds to cancel"
	@for i in 5 4 3 2 1; do echo -n "$$i "; sleep 1; done; echo ""
	@for i in ${DOCKERHUB_READY} ${DOCKERHUB_READY_LATEST}; do docker push $$i; done


docker_rmi_hub:
	@echo ""; echo " ** Potential images with the build label:"
	@make docker_tag_list
	@if [ `echo ${DOCKERHUB_READY} ${DOCKERHUB_READY_LATEST} | wc -w` -eq 0 ]; then echo "No expected images to delete"; exit 1; fi
	@echo "== About to delete:"
	@for i in ${DOCKERHUB_READY} ${DOCKERHUB_READY_LATEST}; do echo "  -- $$i"; done
	@echo "deleting -- Press Ctl+c within 5 seconds to cancel"
	@for i in 5 4 3 2 1; do echo -n "$$i "; sleep 1; done; echo ""
	@for i in ${DOCKERHUB_READY} ${DOCKERHUB_READY_LATEST}; do docker rmi $$i; done
	@echo ""; echo " ** Remaining images with the build label:"
	@make docker_tag_list
