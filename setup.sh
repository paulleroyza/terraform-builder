#setup file for the pipeline, run in cloud shell with your target project set
PROJECT_ID=$DEVSHELL_PROJECT_ID

#enable APIs
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable 

#create the source repo to slave off the github repo
gcloud source repos create terraform-builder
git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/terraform-builder
# might need to use this:
#git remote add ssh://user@domain@source.developers.google.com:2022/p/$PROJECT_ID/r/terraform-builder
git push --all google

#create the build trigger in cloud build
gcloud alpha builds triggers create cloud-source-repositories \
	--build-config=cloudbuild.yaml --repo=terraform-builder \
	--branch-pattern=^master$ --description="terraform-builder-trigger"

# create pub sub
gcloud pubsub topics create terraform-build-topic

# create cloud functions service account
gcloud iam service-accounts create terraform-builder --description="Cloud Function's Service Account to trigger build" --display-name="Terraform Builder"

#give Service account required perms
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:terraform-builder@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/cloudbuild.builds.editor

#create cloud function 
echo Select no to "allow unauthenticated"
gcloud functions deploy terraform-builder \
--source https://source.developers.google.com/projects/$PROJECT_ID/repos/terraform-builder/moveable-aliases/master/paths/cloud-function \
--trigger-topic=terraform-build-topic --max-instances=1 --set-env-vars=PROJECT_ID=$PROJECT_ID \
--memory=128MB --update-labels=terraform-builder=cloudfunction --entry-point=trigger_build \
--runtime=python37 --service-account=terraform-builder@$PROJECT_ID.iam.gserviceaccount.com \
--timeout=300 --allow-unauthenticated=FALSE

# create cron schedule
gcloud scheduler jobs create pubsub terrafrom-builder-cron --schedule="57 3 * * *" --topic=terraform-build-topic --message-body="gobuild"