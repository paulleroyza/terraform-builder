#setup file for the pipeline, run in cloud shell with your target project set
PROJECT_ID=$DEVSHELL_PROJECT_ID

#create the source repo to slave off the github repo
gcloud source repos create terraform-builder
git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/terraform-builder
git push --all google

#create the build trigger in cloud build
gcloud alpha builds triggers create cloud-source-repositories \
	--build-config=cloudbuild.yaml --repo=terraform-builder \
	--branch-pattern=^master$ --description="terraform-builder-trigger"

# create pub sub
gcloud pubsub topics create terraform-build-topic 

#create cloud function 

