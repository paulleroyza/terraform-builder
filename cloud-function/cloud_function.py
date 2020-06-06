import sys

def trigger_build(data, context):

    from google.cloud.devtools import cloudbuild_v1
    client = cloudbuild_v1.CloudBuildClient()
    project_id = 'paul-leroy'
    trigger_id = 'terraform-builder-trigger'

    source =  {"project_id": project_id,"branch_name": "master"}
    response = client.run_build_trigger(project_id, trigger_id, source)