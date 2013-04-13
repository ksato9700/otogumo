#
# Copyright 2013 Kenichi Sato
# 
otogumo = require '../src/otogumo'

client_id = process.env.SC_CLIENT_ID
client_secret = process.env.SC_CLIENT_SECRET
redirect_uri = process.env.SC_REDIRECT_URI

client = new otogumo.Client client_id, client_secret

# username = process.argv[2]
# password = process.argv[3]
# console.log username, password
# client.get_token_by_credentials username, password, (err)->
#   console.log err
#   client.get_me (err, data)->
#     console.log err
#     console.log data

console.log client.authorize_url(redirect_uri)

code = process.argv[2]
client.exchange_token code, redirect_uri, (err)->
 console.log err
 console.log client.access_token
