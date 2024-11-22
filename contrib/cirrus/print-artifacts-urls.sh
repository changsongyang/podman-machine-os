#!/usr/bin/env bash

CIRRUS_BUILD_ID=$1

if [[ -z "$CIRRUS_BUILD_ID" ]]; then
    echo "Requires cirrus build as first argument" 1>&2
    exit 1
fi

echo "Image Downloads for cirrus build [${CIRRUS_BUILD_ID}](https://cirrus-ci.com/build/${CIRRUS_BUILD_ID}):"
echo
echo "| x86_64 | aarch64 |"
echo "| --- | --- |"

for end in applehv.raw.zst hyperv.vhdx.zst qemu.qcow2.zst tar; do
    for arch in x86_64 aarch64; do
        name="podman-machine.$arch.$end"
        echo -n "| [$name](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image_build/image/$name) "
    done
    echo "|"
done

echo
echo "[Everything zip](https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/image.zip)"
