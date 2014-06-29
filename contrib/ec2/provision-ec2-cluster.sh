#!/usr/bin/env bash
#
# Usage: ./provision-ec2-cluster.sh
#

set -e

###############
#### Variables
###############
DISCOVERY_URL="/tmp/discoveryurl.txt"
THIS_DIR=$(cd $(dirname $0); pwd) # absolute path
CONTRIB_DIR=$(dirname $THIS_DIR)

source $CONTRIB_DIR/utils.sh

##################
#### Check prereqs
##################

# check for EC2 API tools in $PATH
if ! which aws > /dev/null; then
  echo_red 'Please install the AWS command-line tool and ensure it is in your $PATH.'
  exit 1
fi

if [ -z "$DEIS_NUM_INSTANCES" ]; then
    DEIS_NUM_INSTANCES=3
fi

###############
#### User-Data
###############

# if its darwin (osx), (install and) use gnu sed
if [[ `uname` == 'Darwin' ]]; then
  if [[ `brew info gnu-sed | awk 'NR == 3'` == 'Not installed' ]]; then
    brew install gnu-sed --default-names
  fi
  SED_EXEC="/usr/local/opt/gnu-sed/bin/sed"
else
  SED_EXEC="sed"
fi
exec $SED_EXEC -i "8i\    discovery: $(curl -s https://discovery.etcd.io/new)" ${CONTRIB_DIR}/coreos/user-data

###############
#### Create AWS
###############

# create an EC2 cloudformation stack based on CoreOS's default template
aws cloudformation create-stack \
    --template-body "$(./gen-json.py)" \
    --stack-name deis \
    --parameters "$(<cloudformation.json)"

#################
#### Confirmation
#################

echo_green "Your Deis cluster has successfully deployed to AWS CloudFormation."
echo_green "Please continue to follow the instructions in the README."
