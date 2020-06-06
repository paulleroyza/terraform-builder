# Terraform cloud builder

A terraform container builder that checks for new terraform versions and builds them automatically and pushe s to your Google Container Registry

## How to use

- Install GCloud SDK or run in Google Cloud shell
- Make sure your gcloud cli is authenticated on GCP by running `gcloud init`
- Make sure you are in a project, in cloud shell type `gcloud config set project [PROJECT_ID]`, if running locally then set the environment variable `DEVSHELL_PROJECT_ID` to your project
- Run the setup.sh file (have a read through it to understand the elements)