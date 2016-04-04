import boto
import boto.s3.connection
#from boto.s3.key import Key
import os
import subprocess

import pdb
access_key = ''
secret_key = ''
host = 'dss.ind-west-1.internal.jiocloudservices.com'
bucket_name = 'rvrscss-cc1a6ae5-8e81'
conn = boto.connect_s3(host=host,aws_access_key_id=access_key, aws_secret_access_key=secret_key,
                       is_secure=True,
                       calling_format = boto.s3.connection.OrdinaryCallingFormat(),)

bucket = conn.get_bucket(bucket_name)
if bucket != None:
    print bucket


#key = bucket.new_key(backup_id)
#keys = bucket.list()

#for key in keys:
#    print "%s %s" % (key.name, key.size)
