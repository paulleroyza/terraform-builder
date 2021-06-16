import sys
import os
import traceback

def trigger_build(data, context):
    from google.cloud.devtools import cloudbuild
    client = cloudbuild.CloudBuildClient()
    project_id = os.environ['GCLOUD_PROJECT']
    trigger_id = 'terraform-builder-trigger'
    source =  {"project_id": project_id,"branch_name": "main"}
    try:
        response = client.run_build_trigger(project_id=project_id, trigger_id=trigger_id, source=source)
        print("Called Trigger")
    except Exception as err:
        traceback.print_tb(err.__traceback__)
    
if __name__=="__main__":
    trigger_build(data=None,context=None)