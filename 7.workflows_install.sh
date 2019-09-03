#!/bin/bash

WORKFLOWS_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/web-app.git"
WORKFLOWS_BRANCH="master"

mkdir -p ~/projects/workflows

git clone $WORKFLOWS_REPOSITORY -b $WORKFLOWS_BRANCH ~/projects/workflows
cd ~/projects/workflows


cp -r dags/cdcol_utils /web_storage/dags/
cp -r plugins/cdcol_plugin /web_storage/plugins/

mkdir -p /web_storage/algorithms
cp -r algorithms/workflows /web_storage/algorithms/