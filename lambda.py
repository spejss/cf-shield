from __future__ import print_function
import json, urllib2, urllib, boto3, os, json
from botocore.exceptions import ClientError

slackurl = os.environ['slack_url']
slackchannel = os.environ['slack_channel']
SG_LIST = list()
SG_LIST.append(os.environ['sg_shield_1'])
SG_LIST.append(os.environ['sg_shield_2'])

def chunk(xs, n):
    ''' Split the list, xs, into n chunks
        source: http://wordaligned.org/articles/slicing-a-list-evenly-with-python '''
    L = len(xs)
    assert 0 < n <= L
    s, r = divmod(L, n)
    chunks = [xs[p:p+s] for p in range(0, L, s)]
    chunks[n-1:] = [xs[-r-s:]]
    return chunks


def slackalert(message, channel, posturl):
    url = posturl
    data = json.dumps({'text': message, 'channel': channel, 'username': 'lambda-exec' }).encode('utf-8')

    try:
        clen = len(data)
        req = urllib2.Request(url, data, {'Content-Type': 'application/json', 'Content-Length': clen})
        f = urllib2.urlopen(req)
        response = f.read()
        if response == "ok":
            print("#slack- You have a message on %s" % channel)
            f.close()
    except:
        print("Response: %s" % str(response))
        

def sg_apply(SG, IP_LIST):
        # Definitions
        params_dict = {
            u'PrefixListIds': [],
            u'FromPort': 80,
            u'IpRanges': [],
            u'ToPort': 443,
            u'IpProtocol': 'tcp',
            u'UserIdGroupPairs': []
        }
        authorize_dict = params_dict.copy()
        slackmsg="Unfortunately, I had to do your job and change some rules on security group: " + SG
        # Call boto ec2
        ec2 = boto3.resource('ec2',region_name=os.environ['REGION_NAME'])
        sg_call = ec2.SecurityGroup(SG)
        
        for ip in IP_LIST:
            authorize_dict['IpRanges'].append({u'CidrIp': ip})

        if len(sg_call.ip_permissions) >= 1:
            sg_call.revoke_ingress(IpPermissions=sg_call.ip_permissions)
            print("ALL REVOKED!!!")
        else:
            print("Empty SG")

        if sg_call.authorize_ingress(IpPermissions=[authorize_dict]):
            print(len(IP_LIST),"CIDRs ADDED on", SG)
            if slackurl != "disabled":
                slackalert(slackmsg,slackchannel,slackurl)
        else:
            print("Fucking crises ingress add ERROR")
            



def lambda_handler(event, context):
    print(SG_LIST)
    IpSpaceURL="https://ip-ranges.amazonaws.com/ip-ranges.json"
    print("Loading data from "+ IpSpaceURL )
    response = urllib2.urlopen(IpSpaceURL)
    json_data = json.loads(response.read())
    new_ip_ranges = [ x['ip_prefix'] for x in json_data['prefixes'] if x['service'] == 'CLOUDFRONT' ]

    if new_ip_ranges > 50:            
        new_ip_ranges_chunked = chunk(new_ip_ranges,len(SG_LIST))
    else:
        new_ip_ranges_chunked = new_ip_ranges
    
    for x in xrange(len(new_ip_ranges_chunked)):
        sg_apply(SG_LIST[x],new_ip_ranges_chunked[x])
    
    return("WOoW")