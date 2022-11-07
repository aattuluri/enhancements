#!/usr/bin/env bash

# Copyright 2022 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

if ! command -v gsutil &> /dev/null
then
    echo "gsutil could not be found"
    exit
fi

# create a temporary directory
TMP_DIR=$(mktemp -d)

# cleanup
exitHandler() (
  echo "=== Cleaning up..."
  rm -rf "${TMP_DIR}"
)
trap exitHandler EXIT

# cd to the root path
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${ROOT}"

# compile kepctl
echo "=== Compiling kepctl"
make tools

# generate KEP manifest and store it in TMP_DIR
echo "=== Generating manifest"
kepctl query --output json > "${TMP_DIR}/keps.json"

# copy manifest to bucket
echo "=== Copying manifest to bucket"
gsutil -h 'Cache-Control: no-store, must-revalidate' -m cp -Z "${TMP_DIR}/keps.json" "${KEPS_BUCKET}/keps.json"

echo "=== Done"
