import base64
import io
import json
import logging
from PIL import Image
from google.cloud import storage

def imageProcessing(event, context):
    """
    Cloud Function to be triggered by Pub/Sub. If there is a message (which means non-vilent score), function triggers.
    Processes the image by resizing (10% of original) and then saves it to safe_storage_tr bucket.
    """
    # Initialize a client to interact with Google Cloud Storage
    storage_client = storage.Client()

    # Log the raw event data
    logging.info(f"Raw event data: {event}")

    # Decode the Pub/Sub message
    try:
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        logging.info(f"Decoded Pub/Sub message: {pubsub_message}")
    except Exception as e:
        logging.error(f"Error decoding message: {str(e)}")
        return

    # Convert the JSON message to a dictionary
    try:
        message_data = json.loads(pubsub_message)
        logging.info(f"Parsed message data: {message_data}")
    except json.JSONDecodeError as e:
        logging.error(f"Failed to parse pubsub message as JSON: {str(e)}")
        return

    # Extract details from the message
    source_bucket_name = message_data.get('source-bucket-name')
    destination_bucket_name = message_data.get('destination-bucket-name')
    file_name = message_data.get('fileName')

    if not all([source_bucket_name, destination_bucket_name, file_name]):
        logging.error("Missing required data in the message")
        return

    try:
        # Get the source bucket and blob
        source_bucket = storage_client.bucket(source_bucket_name)
        blob = source_bucket.blob(file_name)

        # Download the image as bytes
        blob_data = blob.download_as_bytes()

        # Open the image and resize it
        image = Image.open(io.BytesIO(blob_data))
        width, height = image.size
        image = image.resize((width // 10, height // 10))

        # Save the resized image to a byte array
        image_byte_arr = io.BytesIO()
        image.save(image_byte_arr, format='JPEG')
        image_byte_arr = image_byte_arr.getvalue()

        # Upload the processed image to the destination bucket
        destination_bucket = storage_client.bucket(destination_bucket_name)
        new_blob = destination_bucket.blob(file_name)
        new_blob.upload_from_string(image_byte_arr, content_type='image/jpeg')

        logging.info(f'Successfully resized image {file_name} and uploaded to {destination_bucket_name}')
    except Exception as e:
        logging.error(f'Error processing image {file_name}: {str(e)}')

# Ensure the function doesn't execute at import time
if __name__ == "__main__":
    # Example event and context for local testing
    test_message = {
        "image_handler_tr": "source-bucket", 
        "safe_storage_tr": "destination-bucket", 
        "fileName": "image.jpg"
    }
    event = {'data': base64.b64encode(json.dumps(test_message).encode())}
    context = None
    imageProcessing(event, context)
