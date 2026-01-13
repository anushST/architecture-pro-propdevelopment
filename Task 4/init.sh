#!/bin/bash

kubectl create namespace propdev

kubectl create serviceaccount viewer -n propdev
kubectl create serviceaccount admin -n propdev

kubectl apply -f roles.yaml
kubectl apply -f bindings.yaml
