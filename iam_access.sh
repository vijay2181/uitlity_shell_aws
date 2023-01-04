#! /bin/bash

#install jq utility
#export AWS_BACKEND=vijay
#export AWS_PROFILE=test

#we got a request to create iam user
#we will create iam user, give him programmatic and console access
#generate him random password to create new one for first time loggin
#give him iam change user permission
#show existing groups and add user in selected group with required permission
#output should be in proper manner with url,username,accessKey,secretKey,RandomPassword, so that we copy and paste to requesters

# read command will prompt you to enter the name of IAM user you wish to create
echo
read -r -p "Enter the username to create in $RCX_BACKEND": userName
echo
echo "enter 'y' to create user $userName in $RCX_BACKEND, or any other key to exit " && echo
read status && echo
#############
if [ "$status" == "Y" -o "$status"  == "y" ]; then
    RandomPass=$(aws secretsmanager get-random-password \
    --require-each-included-type \
    --password-length 15 \
    --include-space \
    --output text --profile $AWS_PROFILE)

    # Using AWS CLI Command create IAM user
    aws iam create-user --user-name $userName --profile $AWS_PROFILE
    aws iam attach-user-policy --user-name $userName  --policy-arn=arn:aws:iam::aws:policy/IAMUserChangePassword
    aws iam create-login-profile \
    --user-name $userName \
    --password $RandomPass \
    --password-reset-required \
    --output json \
    --profile $AWS_PROFILE


    # Here we are creating access and secret keys and then using query and storing the values in credentials
    credentials=$(aws iam create-access-key --user-name "${userName}" --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text --profile $AWS_PROFILE)


    # cut command formats the output with correct coloumn.
    access_key_id=$(echo ${credentials} | cut -d " " -f 1)
    secret_access_key=$(echo ${credentials} | cut --complement -d " " -f 1)

    #account-id
    #################################################################
    if [[ `aws iam list-account-aliases --profile $AWS_PROFILE | jq '.AccountAliases[0]' | tr -d '"'` -ne 0 ]]; then
        accountId=$(aws iam get-user --profile $AWS_PROFILE --query 'User.Arn'|awk -F\: '{print $5}')
    else
        accountId=$(aws iam list-account-aliases --profile $AWS_PROFILE | jq '.AccountAliases[0]' | tr -d '"')
    fi
    #########################################################
    echo "CREATED USER $userName SUCCESSFULLY in $RCX_BACKEND"
    echo
    echo "DO YOU WANT TO ADD $userName TO EXISTING GROUPS ? enter 'y' to continue or enter any key to exit " && echo
    read status && echo
    if [ "$status" == "Y" -o "$status"  == "y" ]; then

        groups=($(aws iam list-groups --profile $AWS_PROFILE --output text | awk {'print $5'}))
        select name in "${groups[@]}"; do
            aws iam add-user-to-group --user-name $userName --group-name $name --profile $AWS_PROFILE
            echo "YOU HAVE CHOOSEN $name GROUP TO ADD $userName user IN $RCX_BACKEND" && break
        done
    fi
    echo
    echo "CREATED "
    #########################################################
    echo "$RCX_BACKEND AWS Console Access:-"
    echo "=============================="
    echo "URL: https://${accountId}.signin.aws.amazon.com/console/"
    echo "username: $userName"
    echo "password: $RandomPass"
    echo "Access key ID: $access_key_id"
    echo "Secret access key: $secret_access_key"
else
   echo "Exited"
fi
