import boto3
import redis
import json  # Import the json module

def set_data_in_redis(r, key, value):
    # Set the key with the specified value
    r.set(key, value)

def upload_data_to_s3(bucket_name, key, data):
    s3 = boto3.client('s3')
    # Convert 'data' to a JSON string
    json_data = json.dumps(data)
    # Specify the 'ContentType' as 'application/json'
    s3.put_object(Bucket=bucket_name, Key=f"{key}.json", Body=json_data, ContentType='application/json')

def fetch_data_from_redis(redis_host, key):
    r = redis.Redis(host=redis_host, port=6379, db=0, decode_responses=True)
    data = r.get(key)
    return data

def main():
    redis_host = 'suri-redis-cluster.cdurew.0001.use1.cache.amazonaws.com'
    bucket_name = 'redis-suri'
    key = 'your_key'
    
    r = redis.Redis(host=redis_host, port=6379, db=0, decode_responses=True)
    
    # Check if the key exists
    data = fetch_data_from_redis(redis_host, key)
    
    if not data:
        # If not, set some data for the key
        # Assuming you want to save a more complex structure as JSON, modify accordingly
        value_to_set = {"message": "This is a test value"}
        set_data_in_redis(r, key, json.dumps(value_to_set))  # Convert dict to JSON string before setting in Redis
        data = value_to_set  # Use the newly set value (as a dict) for data
        
    # Now upload the data to S3 as JSON
    upload_data_to_s3(bucket_name, key, data)
    print(f"Data uploaded to S3 in JSON format: {data}")

if __name__ == "__main__":
    main()

