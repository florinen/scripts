# Script to set the environment for you.
Before start working with terraform run the script as follows:
Specify the config file as an argument that contains all values/variable specific for the environment you need to work.  
```
source ./vsphere-set-env.sh ../data/c-tools.tfvars 
```
Then run:
```
terraform apply  --var-file $DATAFILE 
```
$DATAFILE will contain the location of your config file.

