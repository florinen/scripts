 #!/bin/bash

DIR=$(pwd)
DATAFILE="$DIR/$1"


# These all variables should be created on your config file before you run script.
# <ENVIRONMENT> <BUCKET> <DEPLOYMENT> <PROJECT> <CREDENTIALS> etc..

if [ ! -f "$DATAFILE" ]; then
  echo "setenv: Configuration file not found: $DATAFILE"
  return 1
fi

wget --quiet -O "$PWD/common_configuration.tfvars"\
  "https://raw.githubusercontent.com/florinen/vsphere-env/master/consul_backend.tfvars"

BACKEND=$(sed -nr 's/^backend\s*=\s*"([^"]*)".*$/\1/p'                       "$PWD/common_configuration.tfvars")
ADDRESS=$(sed -nr 's/^address\s*=\s*"([^"]*)".*$/\1/p'                       "$PWD/common_configuration.tfvars")
SCHEME=$(sed -nr 's/^scheme\s*=\s*"([^"]*)".*$/\1/p'                         "$PWD/common_configuration.tfvars")
ENVIRONMENT=$(sed -nr 's/^deployment_environment\s*=\s*"([^"]*)".*$/\1/p'    "$DATAFILE")
DEPLOYMENT=$(sed -nr 's/^deployment_name\s*=\s*"([^"]*)".*$/\1/p'            "$DATAFILE")
#CREDENTIALS=$(sed -nr 's/^credentials\s*=\s*"([^"]*)".*$/\1/p'               "$DATAFILE")



if [ -z "$BACKEND" ]
then
    echo "setenv: 'backend' variable not set in configuration file."
    return 1
fi

if [ -z "$ADDRESS" ]
then
    echo "setenv: 'address' variable not set in configuration file."
    return 1
fi

if [ -z "$SCHEME" ]
then
  echo "setenv: 'scheme' variable not set in configuration file."
  return 1
fi

if [ -z "$ENVIRONMENT" ]
then
    echo "setenv: 'deployment_environment' variable not set in configuration file."
    return 1
fi

if [ -z "$DEPLOYMENT" ]
then
    echo "setenv: 'deployment_name' variable not set in configuration file."
    return 1
fi

# if [ -z "$CREDENTIALS" ]
# then
#     echo "setenv: 'credentials' file not set in configuration file."
#     return 1
# fi

cat << EOF > "$DIR/backend.tf"
terraform {
  backend "${BACKEND}" {
    address  = "${ADDRESS}"
    scheme   = "${SCHEME}"
    path     = "${ENVIRONMENT}/${DEPLOYMENT}"
  }
}
EOF
cat "$DIR/backend.tf"

#VSPHERE_CREDENTIALS="${DIR}/${CREDENTIALS}"
#export VSPHERE_CREDENTIALS
#export DATAFILE
/bin/rm -rf "$PWD/common_configuration.tfvars" 2>/dev/null
/bin/rm -rf "$DIR/.terraform" 2>/dev/null
echo "setenv: Initializing terraform"
terraform init 


