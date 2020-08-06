from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
import os
import json
import base64

def get_secret_version(project_id, secret_id):
    # Import the Secret Manager client library.
    from google.cloud import secretmanager

    # Create the Secret Manager client.
    client = secretmanager.SecretManagerServiceClient()

    # Build the resource name of the secret.
    name = client.secret_version_path(project_id, secret_id, "latest")

    # Get the secret.
    response = client.access_secret_version(name)

    return response.payload.data.decode('UTF-8')

def sendmail(event, context):
    print("Received pubsub message")
    print(event)
    if 'data' in event:
        build = json.loads(str(base64.b64decode(event['data']).decode('utf-8')))
        print(build)
        try:
            project_id = os.environ['PROJECT_ID']
        except:
            raise SystemExit('PROJECT_ID environment variable not set.')
        sender=os.environ['SENDER']
        recipient=os.environ['RECIPIENT']
        if 'digest' in build.keys():
            digest=build['digest']
        else:
            digest=""
        if 'tag' in build.keys():
            tag=build['tag']
        else:
            tag=""
        print("Message is about container version")
        message = Mail(
            from_email=sender,
            to_emails=recipient,
            subject='{} Container Registry Change'.format(project_id),
            html_content='{} Container Registry has had a container update: {} {} {}'.format(project_id,build['action'],tag,digest) )
        try:
            sg = SendGridAPIClient(os.environ.get(get_secret_version(project_id, "sendgridapikey")))
            response = sg.send(message)
            print(response.status_code)
            print(response.body)
            print(response.headers)
        except Exception as e:
            print(e.message)
    else:
        raise SystemExit('data key not present in JSON')

if __name__ == "__main__":
    sendmail(None,None)