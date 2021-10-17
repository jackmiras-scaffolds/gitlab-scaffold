#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Variables
readonly LANGUAGES=("python" "javascript")
readonly APP_TYPES=("api" "cronjob" "frontend" "lambda" "monolith")

function validate_flag_or_fail() {
  validate_language "${1}" "${2}"
  validate_app_type "${1}" "${2}"
}

function validate_language() {
  language=$(echo "${1}" | cut -d= -f2)
  language_flag=$(echo "${1}" | cut -d= -f1)

  if [[ "${language_flag}" != "--language" ]]; then
    echo "Flag '${language_flag}' is invalid." && exit 1
  fi

  if [[ ! "${LANGUAGES[*]}" =~ "${language}" ]]; then
    echo "Language '${language}' is not supported." && exit 1
  fi
}

function validate_app_type() {
  app_type=$(echo "${2}" | cut -d= -f2)
  app_type_flag=$(echo "${2}" | cut -d= -f1)

  if [[ "${app_type_flag}" != "--type" ]]; then
    echo "Flag '${app_type_flag}' is invalid." && exit 1
  fi

  if [[ ! "${APP_TYPES[*]}" =~ "${app_type}" ]]; then
    echo "Language '${app_type}' is not supported." && exit 1
  fi
}

function moving_files() {
  app_type=$(echo "${1}" | cut -d= -f2)

  mkdir -p .k8s/base

  if [[ "${app_type}" == "api" || "${app_type}" == "frontend" || "${app_type}" == "monolith" ]]; then
    cp gitlab-ci-templates/.k8s/base/service.yml .k8s/base
    cp gitlab-ci-templates/.k8s/base/configmap.yml .k8s/base
    cp gitlab-ci-templates/.k8s/base/deployment.yml .k8s/base
    cp gitlab-ci-templates/.k8s/base/horizontal-pod-autoscaler.yml .k8s/base
  fi

  if [[ "${app_type}" == "cronjob" ]]; then
    cp gitlab-ci-templates/.k8s/base/cronjob.yml .k8s/base
    cp gitlab-ci-templates/.k8s/base/configmap.yml .k8s/base
  fi

  cp -R gitlab-ci-templates/.gitlab-ci/ .
  cp gitlab-ci-templates/.gitlab-ci.yml .
}

function set_docker_image() {
  language=$(echo "${1}" | cut -d= -f2)

  if [[ "${language}" == "python" ]]; then
    sed -i "s/<DOCKER_IMAGE>/jackmiras\/ci:python3-alpine-1.0/g" .gitlab-ci.yml
  elif [[ "${language}" == "javascript" ]]; then
    sed -i "s/<DOCKER_IMAGE>/jackmiras\/ci:node-fermium-alpine-1.0/g" .gitlab-ci.yml
  else
    echo "Language '${language}' is not supported." && exit 1
  fi
}

function set_app_type() {
  app_type=$(echo "${1}" | cut -d= -f2)

    sed -i "s/<APP_TYPE_VALUE>/${app_type}/g" .gitlab-ci/deploy.yml
    sed -i "s/<APP_TYPE_VALUE>/${app_type}/g" .gitlab-ci/end-to-end-tests.yml
    sed -i "s/<APP_TYPE_VALUE>/${app_type}/g" .gitlab-ci/integrations-tests.yml
    sed -i "s/<APP_TYPE_VALUE>/${app_type}/g" .gitlab-ci/promote-to-production.yml
}

function rename_gitlab_deploy_script() {
  app_type=$(echo "${1}" | cut -d= -f2)

  if [[ "${app_type}" == "lambda" ]]; then
    rm -rf .gitlab-ci/deploy.yml
    mv .gitlab-ci/deploy-lambda.yml .gitlab-ci/deploy.yml

    rm -rf .gitlab-ci/build.yml
    mv .gitlab-ci/build-lambda.yml .gitlab-ci/build.yml
  fi

  rm -rf .gitlab-ci/build-lambda.yml
  rm -rf .gitlab-ci/deploy-lambda.yml
}

function rename_k8s_deployment_script() {
  app_type=$(echo "${1}" | cut -d= -f2)

  if [[ "${app_type}" == "cronjob" ]]; then
    rm -rf .k8s/base/deployment.yml
    mv .k8s/base/cronjob.yml .k8s/base/deployment.yml
  fi
}

function clean_up() {
  rm -rf gitlab-ci-templates
}

function main() {
  validate_flag_or_fail "${1}" "${2}"

  moving_files "${2}"
  set_app_type "${2}"

  set_docker_image "${1}"
  rename_gitlab_deploy_script "${2}"
  rename_k8s_deployment_script "${2}"

  clean_up
}

main "${1}" "${2}"
