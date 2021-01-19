# Find username based on AccessKeyID
```
bash $HOME/omegnet.com/scripts/aws/aws_iam_get_user.sh -p <profile_name> AIDAVNCIX4ND5AYOBFIXY
```
# Rotate AWS AccessKeys 
For each profile this script can automaticaly rotate AWS Access Keys using Cron to execute script.

```
bash $HOME/omegnet.com/scripts/aws/rotate.sh -p <profile_name>
```
## Install Cron Job:
This cron job will execute script every Thursday at 1AM but key will get rotated after 90 day.
```
sudo crontab -l | { cat; echo '0 1 * * 4 bash $HOME/omegnet.com/scripts/aws/rotate.sh -p <profile_name>'; } | sudo crontab -
```

