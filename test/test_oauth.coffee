#
# Copyright 2013 Kenichi Sato
# 
otogumo = require '../src/otogumo'

mocha = require 'mocha'
assert = require('chai').assert
nock = require 'nock'

CLIENT_ID = 'foo'
CLIENT_SECRET = 'bar'
SCOPE = undefined
REDIRECT_URL = 'http://example.com/callback'

oauth_server = nock "https://api.soundcloud.com"
oauth_server
 .filteringRequestBody(/.*/, '*')
 .post("/oauth2/token", '*')
 .reply 200, (uri, body)->
    access_token: 'my-access-token'
    expires_in: 'my-expires-in'
    refresh_token: 'my-refresh-token'
    scope: body.scope

describe 'Oauth', ->
  client = new otogumo.Client CLIENT_ID, CLIENT_SECRET

  describe 'get_token_by_credentials', ->
    it 'should get access token by a credential', (done)->
      client.get_token_by_credentials 'username', 'password', (err)->
        assert.equal client.access_token, 'my-access-token'
        assert.equal client.expires_in, 'my-expires-in'
        assert.equal client.refresh_token, 'my-refresh-token'
        assert.equal client.scope, SCOPE
        done()




