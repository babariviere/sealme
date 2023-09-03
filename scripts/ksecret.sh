#!/bin/sh

kubectl get secrets $@ -o yaml | yq '.stringData = .data | del(.data) | .stringData.* |= @base64d'
