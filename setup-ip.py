#!/usr/bin/python

import os
import sys
import requests
import json

api_base = 'https://api.digitalocean.com/v2'


def usage():
    print('{0} [Floating IP] [Droplet ID]'.format(sys.argv[0]))
    print('\nYour DigitialOcean API token must be in the "DO_TOKEN"'
          ' environmental variable.')


def main(floating_ip, droplet_id):
    payload = {'type': 'assign', 'droplet_id': droplet_id}
    headers = {'Authorization': 'Bearer {0}'.format(os.environ['DO_TOKEN']),
               'Content-type': 'application/json'}
    url = api_base + "/floating_ips/{0}/actions".format(floating_ip)
    r = requests.post(url, headers=headers,  data=json.dumps(payload))

    resp = r.json()
    if 'message' in resp:
        print('{0}: {1}'.format(resp['id'], resp['message']))
        sys.exit(1)
    else:
        print('Moving IP address: {0}'.format(resp['action']['status']))

if __name__ == "__main__":
    if 'DO_TOKEN' not in os.environ or not len(sys.argv) > 2:
        usage()
        sys.exit()
    main(sys.argv[1], sys.argv[2])

