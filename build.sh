#!/bin/bash

# Copyright 2016 Google Inc. All rights reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

LOCAL=0
if [ "$1" == "--local" ]; then
  LOCAL=1
  shift;
fi

CANDIDATE_NAME=`date +%Y-%m-%d_%H_%M`
echo "CANDIDATE_NAME:${CANDIDATE_NAME}"

if [ -z "${DOCKER_NAMESPACE+set}" ] ; then
  echo "Error: DOCKER_NAMESPACE is not set; invoke with something like DOCKER_NAMESPACE=gcr.io/YOUR-PROJECT-NAME" >&2
  exit 1
fi
export IMAGE_NAME="${DOCKER_NAMESPACE}/${RUNTIME_NAME}:${CANDIDATE_NAME}"

if [ -z "${GOOGLE_CLOUD_PROJECT+set}" ] ; then
  echo "Error: GOOGLE_CLOUD_PROJECT is not set; invoke with something like GOOGLE_CLOUD_PROJECT=YOUR-PROJECT-NAME" >&2
  exit 1
fi

export IMAGE_NAME=$1

if [ -z "$IMAGE_NAME" ]; then
  echo "Usage: ./build.sh [image_path]"
  echo "Please provide fully qualified path to target image."
  exit 1
fi

envsubst < cloudbuild.yaml.in > cloudbuild.yaml
envsubst '$DOCKER_NAMESPACE $CANDIDATE $BUILDER_SPEC_DIR' < build-pipeline/python.yaml.in > build-pipeline/python.yaml

if [ "$LOCAL" -eq 1 ]; then
  ./scripts/local_cloudbuild.py --config=cloudbuild.yaml
else
  gcloud beta container builds submit . --config=cloudbuild.yaml
fi
