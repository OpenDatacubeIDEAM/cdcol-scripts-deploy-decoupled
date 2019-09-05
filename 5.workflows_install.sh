#!/bin/bash

API_REST_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/api-rest.git"
API_REST_BRANCH="master"

CLEANER_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/cdcol-cleaner.git"
CLEANER_BRANCH="master"

UPDATER_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/execution-monitor.git"
UPDATER_BRANCH="master"

WORKFLOWS_REPOSITORY="git@gitlab.virtual.uniandes.edu.co:datacube-ideam/workflows.git"
WORKFLOWS_BRANCH="master"

mkdir -p ~/projects/workflows

git clone $WORKFLOWS_REPOSITORY -b $WORKFLOWS_BRANCH ~/projects/workflows
cd ~/projects/workflows


cp -r dags/cdcol_utils /web_storage/dags/
cp -r plugins/cdcol_plugin /web_storage/plugins/

mkdir -p /web_storage/algorithms
mkdir -p /web_storage/media_root/algorithms
cp -r algorithms/workflows /web_storage/algorithms/



