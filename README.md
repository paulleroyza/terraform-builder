# Terraform cloud builder

A terraform container builder that checks for new terraform versions and builds them automatically and pushe s to your Google Container Registry

## How to use

- Install GCloud SDK or run in Google Cloud shell
- Make sure your gcloud cli is authenticated on GCP by running `gcloud init`
- Make sure you are in a project, in cloud shell type `gcloud config set project [PROJECT_ID]`, if running locally then set the environment variable `DEVSHELL_PROJECT_ID` to your project
- Run the setup.sh file (have a read through it to understand the elements)

The steps are as follows:
- *source repository configuration*
- get the current project from `cloud shell` environment, if you're not using cloud shell then make sure you are using an authenticated [gcloud](https://cloud.google.com/sdk) environment and set the `$DEVSHELL_PROJECT_ID` environment variable
- creates a [source reposity](https://source.cloud.google.com/) in the current project called `terraform-builder`
- sets up the git authentication to push this directory into that source repository
- sets the google remote as the newly created repo
- pushes the code into the repo
- *cloud build*
- the build checks for a new version on the Hashicorp site against the [container registry](https://console.cloud.google.com/gcr/) where the terraform builder will/does reside
- sets up a build [trigger](https://console.cloud.google.com/cloud-build/triggers) in cloud build which is either triggered by a commit (unlikely because we want to trigger off a schedule which checks changes on the [Hashicorp](https://www.terraform.io/) website) 
- if you look at the cloudbuild.yaml file, you'll see that it clones the [cloud-builder-community](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/terraform) repo and triggers the terraform build.
- set a [pubsub](https://console.cloud.google.com/cloudpubsub/topic/list) topic which we'll then use to trigger a cloud function
- set up a [service account](https://console.cloud.google.com/iam-admin/serviceaccounts) with limited scope for the cloud function to run as
- set the [role](https://console.cloud.google.com/iam-admin/iam) of the cloud function service account as cloud build editor. The minimum I could find, maybe custom roles could make this tighter
- deploy the [cloud function](https://console.cloud.google.com/functions/list) using the cloud functions directory of the uploaded repo and set it to listen to the pubsub topic.
- set a [scheduled](https://console.cloud.google.com/cloudscheduler) job to run every morning to trigger the pipeline
