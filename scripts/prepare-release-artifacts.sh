#!/usr/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/. *)

set -e

function usage() {
  echo "Usage: ${0} [-s EMAIL]" 1>&2
  exit 1
}

local_user=""

while getopts "s:" o; do
    case "${o}" in
        s)
            local_user=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

function spatial_version() {
  grep '^version:' spatial-shell.opam | sed 's/version: "\(.*\)"/\1/'
}

echo "Building artifacts for spatial-shell-$(spatial_version)"

if [ ! -z "$(git status -s)" ]; then
  echo "You have uncommitted changes. Press enter to continue."
  read

  if [ ! "$?" = "0" ]; then
    exit 1
  fi
fi

release_name="spatial-shell-$(spatial_version)"
archive_suffix="-linux-$(uname -m).tar.gz"
worktree=$(git rev-parse --show-toplevel)
tmp_workspace="$(mktemp -d)"

if [ -f "_artifacts/${release_name}${archive_suffix}" ]; then
  echo "_artifacts/${release_name}${archive_suffix} already exists. You need to delete it to run this script."
  exit 2
fi

# Building a static distribution

pushd "${tmp_workspace}"
git clone -q "${worktree}" .
OCAML_COMPILER=ocaml-option-static,ocaml-option-no-compression,ocaml.5.1.1 make build-deps
eval $(opam env)
BUILD_PROFILE=static make
DESTDIR=artifacts make install
opam switch remove . -y
popd
mkdir -p _artifacts
mv "${tmp_workspace}/artifacts" "_artifacts/${release_name}"

# Creating the archive

rm -rf "${tmp_workspace}"
pushd _artifacts
tar czvf "${release_name}${archive_suffix}" "${release_name}"
rm -rf ${release_name}

if [ -n "${local_user}" ]; then
  gpg --local-user "${local_user}" \
    --out "${release_name}${archive_suffix}.sig" \
    --detach-sig "${release_name}${archive_suffix}"
fi

popd
