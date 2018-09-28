import json
from urllib.request import urlopen

response = urlopen('https://ip-ranges.amazonaws.com/ip-ranges.json')
json_data = json.loads(response.read())
new_ip_ranges = [ x['ip_prefix'] for x in json_data['prefixes'] if x['service'] == 'CLOUDFRONT' ]

for x in json_data['prefixes']:
    if x['service'] == "CLOUDFRONT":
        print(x['ip_prefix'] +" "+ x['region'] + " " + x['service'])


