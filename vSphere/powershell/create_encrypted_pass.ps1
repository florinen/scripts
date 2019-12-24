## Using a powershell credentials file to pass encrypted credentials to this script

(get-credential).password | ConvertFrom-SecureString | set-content "C:\Users\florin\cred\my_pass.txt"
