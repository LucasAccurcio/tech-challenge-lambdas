#!/bin/bash
base_folder="../lambdas"

folders=$(find "$base_folder" -mindepth 1 -maxdepth 1 -type d)

for folder in $folders;
do
  echo "Deploying $folder..."
  
  cd "$folder" || { echo "Failed to enter $folder"; exit 1; }

  if aws lambda create-function --function-name tech-challenge-$folder --runtime nodejs18.x --handler index.handler --role arn:aws:iam::$AWS_ACCOUNT_ID:role/LabRole --zip-file fileb://$folder.zip --environment "Variables={USER=$DB_USER,HOST='$DB_AWS_HOST',DATABASE='$DB_DATABASE',PASSWORD='$DB_PASSWORD',PORT='$DB_PORT'}"; then
    echo "Deploy completed for $folder"
  else
    echo "Deploy failed for $folder"
    exit 1;
  fi
  
  cd ../..
done

echo "Deploy completed!"