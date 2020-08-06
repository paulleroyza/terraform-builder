#setup file for the pipeline, run in cloud shell with your target project set
#git clone https://github.com/paulleroyza/terraform-builder.git
#cd terraform-builder

PROJECT_ID=$DEVSHELL_PROJECT_ID

#enable APIs
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud app create --region=us-central

#create the source repo to slave off the github repo
gcloud source repos create terraform-builder
git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/terraform-builder
git push google main

#create the build trigger in cloud build
gcloud alpha builds triggers create cloud-source-repositories \
	--build-config=cloudbuild.yaml --repo=terraform-builder \
	--branch-pattern=^main$ --description="terraform-builder-trigger"

#disable the trigger, we will run it from cloud functions
gcloud beta builds triggers export terraform-builder-trigger --destination=../cloudbuilder.yaml
echo disabled: True >> ../cloudbuilder.yaml
gcloud beta builds triggers import --source=../cloudbuilder.yaml

# create pub sub
gcloud pubsub topics create terraform-build-topic

# create cloud functions service account
gcloud iam service-accounts create terraform-builder --description="Cloud Function's Service Account to trigger build" --display-name="Terraform Builder"

#give Service account required perms
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:terraform-builder@$PROJECT_ID.iam.gserviceaccount.com \
  --role roles/cloudbuild.builds.editor

#create cloud function 

gcloud functions deploy terraform-builder \
--source https://source.developers.google.com/projects/$PROJECT_ID/repos/terraform-builder/moveable-aliases/main/paths/cloud-function \
--trigger-topic=terraform-build-topic --max-instances=1 --set-env-vars=PROJECT_ID=$PROJECT_ID \
--memory=128MB --update-labels=terraform-builder=cloudfunction --entry-point=trigger_build \
--runtime=python37 --service-account=terraform-builder@$PROJECT_ID.iam.gserviceaccount.com \
--timeout=300 --quiet

# create cron schedule
gcloud scheduler jobs create pubsub terrafrom-builder-cron --schedule="57 3 * * *" --topic=terraform-build-topic --message-body="gobuild"

#set up alerting
gcloud beta logging metrics create terraform-version-build --description="Metric on whether there is a new build" \
	--log-filter="resource.type=\"build\" AND textPayload=~\"Building New Version: \d\.\d*\.\d*\""

#set up build notification, set up the topic, this should exist if container registry has ever been used
gcloud pubsub topics create gcr || true #might exist already on the project

#split out notifier
gcloud iam service-accounts create terraform-build-notifier --description="Cloud Function's Service Account to trigger build" --display-name="Terraform Builder"

#set up secrets store
gcloud secrets create sendgridapikey \
	--replication-policy="automatic" \
	--labels=terraform-builder=secrets

gcloud secrets add-iam-policy-binding sendgridapikey \
	--member serviceAccount:terraform-build-notifier@$PROJECT_ID.iam.gserviceaccount.com \
	--role="roles/secretmanager.secretAccessor"

#set sendgrid API key here and no, you can't have mine
gcloud secrets versions add sendgridapikey --data-file="../sendgrid_apikey.txt"

#set email details
SENDER=info@example.com
RECIPIENT=info@example.com

gcloud functions deploy build-notifications \
--source https://source.developers.google.com/projects/$PROJECT_ID/repos/terraform-builder/moveable-aliases/main/paths/sendmail \
--trigger-topic=gcr --max-instances=1 --set-env-vars=PROJECT_ID=$PROJECT_ID,SENDER=$SENDER,RECIPIENT=$RECIPIENT \
--memory=128MB --update-labels=terraform-builder=sendmail --entry-point=sendmail \
--runtime=python37 --service-account=terraform-build-notifier@$PROJECT_ID.iam.gserviceaccount.com \
--timeout=300 --quiet
