#!/usr/bin/env bash

### ----------------------------------------------------------------------------
# Creates a new Docker image, from the base image provided, containing the additional
# Carbon application files from the directory provided and pushes the new Docker image to the
# same Docker repository as the base image with the new tag provided.
# 
# Usage:
# addCarbonApps.sh <arguments>
# NOTE: All arguments are required.
# Arguments:
# -d <path>   | --dir <path>  Absoulte path of the directory containing the additional CAR files,
#                             e.g.  -d "/home/user1/carbon-apps"
#                                   --dir "/home/user1/carbon-apps"
# -i <image>  | --baseImage <image>   Complete path of the Docker image with tag, in Google artifact registry,
#                                     e.g.  -i "us-west2-docker.pkg.dev/gcp-project1/docker-repo/cumulator-mi:1.2-ubilinux"
#                                           --baseImage "us-west2-docker.pkg.dev/gcp-project1/docker-repo/cumulator-mi:1.2-ubilinux"
# -t <tag>    | --tag <tag>    New tag for the Docker image with additional CAR files,
#                              e.g. -t "1.2-ubilinux-modified"
#                                   --tag "1.2-ubilinux-modified"
#
### ----------------------------------------------------------------------------

### --- Function definitions -----------------------------------------------------------
function logInfo() {
  echo "$(date +%Y%m%d_%H%M%S) INFO :: ${@}"
}

function logError() {
  echo "$(date +%Y%m%d_%H%M%S) ERROR :: ${@}"
}

function showHelp() {
  echo \
'------------------------------------
Usage: addCarbonApps.sh <arguments>
NOTE: All arguments are required.

Arguments:
-d <path>   | --dir <path>  Absoulte path of the directory containing the additional CAR files,
                            e.g.  -d "/home/user1/carbon-apps"
                                  --dir "/home/user1/carbon-apps"
-i <image>  | --baseImage <image>   Complete path of the Docker image with tag, in Google artifact registry,
                                    e.g.  -i "us-west2-docker.pkg.dev/gcp-project1/docker-repo/cumulator-mi:1.2-ubilinux"
                                          --baseImage "us-west2-docker.pkg.dev/gcp-project1/docker-repo/cumulator-mi:1.2-ubilinux"
-t <tag>    | --tag <tag>    New tag for the Docker image with additional CAR files,
                             e.g. -t "1.2-ubilinux-modified"
                                  --tag "1.2-ubilinux-modified"
------------------------------------'
}

function showAllArgs() {
  echo \
"Carbon application directory: ${carSrcDir}
Base image: ${baseImage}
New image tag: ${newImageTag}"
}


function setGcpContext() {
  local project="${1}"
  local dockerRegistry="${2}"

  # Configure Docker registry.
  logInfo "gcloud auth configure-docker: registry: ${dockerRegistry}, project: ${project}"
  gcloud auth configure-docker "${dockerRegistry}" --project="${project}" --quiet
}

function listDockerImages() {
  logInfo "List of Docker images in local image cache:"
  docker images --all
}

function preReqTools() {
  logInfo "Verifying Docker and gcloud cli installations."
  
  local ver=$(docker --version 2>&1)
  if [[ ${?} -gt 0 ]];
  then
      logError "Docker CLI not installed."
      exit 1
  else
      logInfo "Docker version: ${ver}"
  fi

  ver=$(gcloud --version 2>&1)
  if [[ ${?} -gt 0 ]];
  then
      logError "gcloud CLI not installed."
      exit 1
  else
      logInfo "gcloud version: ${ver}"
  fi
}

### ------------------------------------------------------------------------------

### ===============================================================================
### --- Start of script execution -------------------------------------------------
#set -x

prgPath="${0}"
prgDir=$(dirname ${prgPath})
prgName=$(basename ${prgPath})
logFile=$(date "+${prgName%%.*}-log-%Y%m%d_%H%M%S.log")
logFilePath="${prgDir}/${logFile}"
carStageDir="${prgDir}/cars"

exec > >(tee -a "${logFilePath}") 
exec 2>&1

logInfo "Start execution of: ${prgPath}, arguments: |${@}|"

### Process cmd-line arguments

VALID_ARGS=$(getopt -o d:hi:t: --long dir:,baseImage:,help,tag: -- "$@" 2>/dev/null)
getOptCmdStatus=${?}
if [[ ${getOptCmdStatus} -ne 0 ]]; then
    logError "Invalid argument(s) provided: ${@}"
    VALID_ARGS=" -h --"
fi
eval set -- "$VALID_ARGS"

if [[ ${#} -lt 6 ]];
then
    logError "Not all arguments provided: ${@}"
    showHelp
    exit 1
fi

## Validate that Docker and gcloud CLI has been installed.
preReqTools

### Iterate over the valid arguments and validate arguments provided.
carSrcDir=""
svcAccountKeyPath=""
baseImage=""
newImageTag=""
while [ : ]; do
  case "$1" in
    -d | --dir)
        carSrcDir="${2}"
        ## Validate: Directory exists and contains atleast one .car file
        if [[ -d "${carSrcDir}" ]];
        then
            carFileCount=$(ls -1 ${carSrcDir}/*.car 2>/dev/null | wc -l)
            if [[ ${carFileCount} -gt 0 ]];
            then
                logInfo "Carbon application files in directory: ${carSrcDir} :"
                ls -1 ${carSrcDir}/*.car
            else
                logError "No Carbon application (.car) files present in directory: ${carSrcDir}"
                exit 1
            fi
        else
            logError "Directory does not exist: ${carSrcDir}"
            showHelp
            exit 1
        fi
        shift 2
        ;;
    -i | --baseImage)
        baseImage="${2}"
        if [[ "${baseImage}" == "" ]];
        then
            logError "Docker base image name not provided in -i | --baseImage"
            showHelp
            exit 1
        else
          logInfo "Docker base image: ${baseImage}"
        fi
        shift 2
        ;;
    -h | --help)
        showHelp
        shift
        ;;
    -t | --tag)
        newImageTag="${2}"
        if [[ "${newImageTag}" == "" ]];
        then
            logError "New Docker image tag not provided for -t | --tag"
        else
            logInfo "New Docker image tag: ${newImageTag}"
        fi
        shift 2
        ;;
    --) shift; 
        break 
        ;;
  esac
done


# Extract Docker repository and image names from base image arg.
IFS='/' read -ra repoPathElems <<< "${baseImage}"
gcpDockerRegistry="${repoPathElems[0]}"
gcpProjectName="${repoPathElems[1]}"
gcpDockerRepo="${repoPathElems[2]}"
taggedImageName="${repoPathElems[3]}"

baseImagePath=${baseImage%%:*}
baseImageTag=${taggedImageName##*:}

logInfo "New Carbon application source dir: ${carSrcDir}"
logInfo "Base image: ${baseImage}"
logInfo "GCP details:
Project name: ${gcpProjectName}
Docker registry: ${gcpDockerRegistry}
Docker repository: ${gcpDockerRepo}
Base image name: ${baseImagePath}
Base image tag: ${baseImageTag}
"
logInfo "New image tag: ${newImageTag}"

logInfo "Creating directory for staging CAR file: ${carStageDir}"
mkdir --verbose -p "${carStageDir}"

## Copy CAR files into dest dir
logInfo "Copying Carbon App files from ${carSrcDir} to image build directory: ${carStageDir}"
cp -v "${carSrcDir}"/*.car "${carStageDir}"

# Set gcloud context - login and set Docker registry
setGcpContext "${gcpProjectName}" "${gcpDockerRegistry}"

# List images in local image cache before building a new Docker image.
listDockerImages

# Delete existing Docker image with new tag from local image cache. 
logInfo "Deleting any existing image with new image tag: ${baseImagePath}:${newImageTag}"
docker rmi -f "${baseImagePath}":"${newImageTag}"

# cd to directory with Dockerfile (Docker build root) and build Docker image.
logInfo "Change dir to: ${prgDir}"
cd "${prgDir}"; pwd; ls -hlF;

logInfo "Build Docker image from base image: ${baseImage}, new tag: ${newImageTag}, build dir: ${prgDir}"
docker build --build-arg "baseImage=${baseImage}" --tag "${baseImagePath}:${newImageTag}"  ${prgDir}

# List images in local image cache after building a new Docker image.
listDockerImages

# Push nwe image to Docker repository of base image.
logInfo "Pushing Docker image: ${baseImagePath}:${newImageTag}"
docker push "${baseImagePath}:${newImageTag}"

# List the images in the remote Docker repository.
logInfo "Listing Docker images in Docker repository: ${gcpDockerRegistry}/${gcpProjectName}/${gcpDockerRepo}"
gcloud artifacts docker images list "${gcpDockerRegistry}/${gcpProjectName}/${gcpDockerRepo}" --include-tags

logInfo "End execution of: ${prgPath}"
