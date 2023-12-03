import os
import logging
from google.cloud import pubsub_v1, storage, vision
from pymongo import MongoClient
from pymongo.errors import PyMongoError
from concurrent import futures # encapsulate the asynchronous execution of a callable and allow you to check on the callable’s status and result
from typing import Callable
import json

# Debug logging, uncomment if youi need more logging
#logging.basicConfig(level=logging.DEBUG) # INFO>DEBUG>RAW format less>more verbose logs.

"""
Cloud Function to be triggered by cloud storage event from image_handler_tr bucket.
Processes the images by checking against google Vision AI dataset and then if non-violent send Pub/Sub message.
All images analysis details are inserted in db "mongodb" and collection "violence_score". You could change names in lines 69-70.
Create db and collection when new documented is inserted.
"""

project_id = os.getenv('GOOGLE_CLOUD_PROJECT')  
topic_id = os.getenv('PUBSUB_TOPIC')             
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)
publish_futures = []

def get_callback(publish_future: pubsub_v1.publisher.futures.Future, data: str) -> Callable:
    def callback(publish_future: pubsub_v1.publisher.futures.Future) -> None:
        try:
            # Wait 60 seconds for the publish call to succeed.
            print(publish_future.result(timeout=60))
        except futures.TimeoutError:
            print(f"Publishing {data} timed out.")

    return callback

def imageAnalysis(event, context):
    """Triggered by a change to a Cloud Storage bucket."""
    file = event
    print(f"Processing file: {file['name']}.")

    # Analyze the violent score of the image with Google Cloud Vision
    client = vision.ImageAnnotatorClient()
    image = vision.Image(source=vision.ImageSource(gcs_image_uri=f"gs://{file['bucket']}/{file['name']}"))
    response = client.safe_search_detection(image=image)
    violent_score = response.safe_search_annotation.violence
    print(f"Violent score: {violent_score}.")

    mongo_client = None  # Initialize mongo_client
    try:
        mongo_uri = os.getenv('MONGODB_URI') 
        if not mongo_uri:
            logging.error('MongoDB URI not set.')
            return

        mongo_client = MongoClient(mongo_uri)
        db = mongo_client['mongodb']
        collection = db['violence_score']

        record = {'file_name': file['name'], 'violent_score': violent_score}
        collection.insert_one(record)
        print(f"Inserted record into MongoDB: {record}")
    except PyMongoError as e:
        logging.error(f"An error occurred while connecting to MongoDB: {e}")
    finally:
        if mongo_client:
            mongo_client.close()

    # Send a Pub/Sub message if the image is non-violent
    if violent_score == vision.Likelihood.VERY_UNLIKELY: #, vision.Likelihood.UNLIKELY):
        # Prepare a JSON string with the file name
        data_json = json.dumps({
         "source-bucket-name": "image_handler_tr",
         "destination-bucket-name": "safe_storage_tr",
         'fileName': file['name']
         })
        data = data_json.encode('utf-8')

        publish_future = publisher.publish(topic_path, data)
        publish_future.add_done_callback(get_callback(publish_future, file['name']))
        publish_futures.append(publish_future)

        print(f"Published messages to {topic_path}.")

    # Wait for all the publish futures to resolve before exiting
    futures.wait(publish_futures, return_when=futures.ALL_COMPLETED)
    print(f"Published messages with error handler to {topic_path}.")
