#
# Copyright 2013 Kenichi Sato
# 
otogumo = require '../src/otogumo'

mocha = require 'mocha'
assert = require('chai').assert
nock = require 'nock'
qs = require 'querystring'

CLIENT_ID = 'foo'
CLIENT_SECRET = 'bar'
USERNAME = 'username'
PASSWORD = 'password'
SCOPE = undefined

describe 'Oauth', ->
  describe 'get_token_by_credentials', ->
    it 'should get access token by a credential', (done)->
      server = nock "https://api.soundcloud.com"
      server.post("/oauth2/token", qs.stringify
          client_id: CLIENT_ID
          client_secret: CLIENT_SECRET
          username: USERNAME
          password: PASSWORD
          scope: SCOPE
          grant_type: 'password')
      .reply 200,
          access_token: 'my-access-token'
          expires_in: 'my-expires-in'
          refresh_token: 'my-refresh-token'
          scope: SCOPE
      client = new otogumo.Client CLIENT_ID, CLIENT_SECRET
      client.get_token_by_credentials USERNAME, PASSWORD, (err)->
        assert.isNull err
        assert.equal client.access_token, 'my-access-token'
        assert.equal client.expires_in, 'my-expires-in'
        assert.equal client.refresh_token, 'my-refresh-token'
        assert.equal client.scope, SCOPE
        done()

    it 'should handle error response properly', (done)->
      server = nock "https://api.soundcloud.com"
      server.filteringRequestBody(/.*/, '*')
      .post("/oauth2/token", '*')
      .reply 401,
          error: 'invalid_client'
      client = new otogumo.Client CLIENT_ID, CLIENT_SECRET
      client.get_token_by_credentials USERNAME, PASSWORD, (err)->
        assert.equal err.error, 'invalid_client'
        done()




