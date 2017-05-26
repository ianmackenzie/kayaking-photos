import requests
import iptcinfo
import glob
import uuid

database_url = 'http://localhost:5984/kayaking-photos'

image_filenames = glob.glob('C:/Users/ian.mackenzie/Kayaking photos/*.jpg')[:100]

for filename in image_filenames:
    print(filename)
    # Generate a random UUID for this file
    uuid_string = uuid.uuid4().hex
    document_url = database_url + '/' + uuid_string

    print('  Reading tags')
    # Get EXIF tags that have been added to the image
    tags = iptcinfo.IPTCInfo(filename).keywords

    print('  Uploading tags')
    # Send a request to the CouchDB server to add a JSON document with a single
    # 'tags' field with a list of the tags we extracted
    tag_response = requests.put(document_url, json = {'tags': tags})
    # Throw an exception if the request failed
    tag_response.raise_for_status()
    # Get the revision tag of the document we just uploaded
    rev = tag_response.json()['rev']

    print('  Reading image data')
    # Get binary JPEG data
    image_data = open(filename, 'rb').read()

    print('  Uploading image data')
    # Send a request to the CouchDB server to add the binary image data to our
    # existing document as an attachment. We have to explicitly pass the
    # revision tag so that CouchDB can make sure we're not accidentally editing
    # a more recent version of the document than we think we are; that is, we
    # say 'please add this attachment to this particular revision of this
    # particular document', and if the given revision is *not* the most recent
    # revision of the given document (someone else has edited it in the
    # meantime) then CouchDB will return an error.
    image_response = requests.put(document_url + '/image.jpg', params = {'rev': rev}, data = image_data, headers = {'Content-Type': 'image/jpg'})
    # Throw an exception if the request failed
    image_response.raise_for_status()
