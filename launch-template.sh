#!/bin/bash

#export AWS_BACKEND=vijay
#export AWS_PROFILE=test

#usage: bash launch-template.sh <Template _Name>
#Displays list of launch templates on Argument search and gives versions and latest version userData

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
groups=($(aws ec2 describe-launch-templates --output text --query 'LaunchTemplates[?contains(LaunchTemplateName, `'"$1"'`||`'"${1^^}"'`) == `true`].LaunchTemplateName' --profile $AWS_PROFILE))
select name in "${groups[@]}"; do
    echo "YOU HAVE CHOOSEN $name"  && break
done

echo "DefaultVersionNumber: $(aws ec2 describe-launch-templates --profile $AWS_PROFILE --launch-template-names $name --output text --query 'LaunchTemplates[].DefaultVersionNumber')"
echo "LatestVersionNumber: $(aws ec2 describe-launch-templates --profile $AWS_PROFILE --launch-template-names $name --output text --query 'LaunchTemplates[].LatestVersionNumber')"

echo "DO YOU WANT TO WANT TO SEE LATEST USERDATA ? enter 'y' or 'Y' to continue or any other key to exit " && echo
    read status && echo

if [ "$status" == "Y" -o "$status"  == "y" ]; then
      echo "####################################################"
      aws ec2 describe-launch-template-versions --profile $AWS_PROFILE --launch-template-name $name --query 'LaunchTemplateVersions[0].LaunchTemplateData.UserData' --output text | base64 -d && echo
      echo "####################################################"
