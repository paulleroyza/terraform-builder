import sys
import os
import traceback

def trigger_build(data, context):
    from google.cloud.devtools import cloudbuild_v1
    client = cloudbuild_v1.CloudBuildClient()
    project_id = os.environ['PROJECT_ID']
    trigger_id = 'terraform-builder-trigger'
    source =  {"project_id": project_id,"branch_name": "master"}
    #try:
    response = client.run_build_trigger(project_id, trigger_id, source)
    print("Called Trigger")
    #except Exception as err:
    #    traceback.print_tb(err.__traceback__)
    
if __name__=="__main__":
    trigger_build(data=None,context=None)