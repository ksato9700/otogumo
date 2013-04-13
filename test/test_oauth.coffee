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
REDIRECT_URI = 'http://example.com/redirect'

describe 'Oauth', ->
  describe 'authorize_url', ->
    it 'should get authorize URL', (done)->
      client = new otogumo.Client CLIENT_ID, CLIENT_SECRET
      authz_url = client.authorize_url REDIRECT_URI
      assert.isString authz_url
      options = qs.parse authz_url.split('?')[1]
      assert.equal options.scope, 'non-expiring'
      assert.equal options.client_id, CLIENT_ID
      assert.equal options.response_type, 'code'
      assert.equal options.redirect_uri, REDIRECT_URI
      done()

  describe 'exchange_token', ->
    it 'should exchange authorization_code with access_token', (done)->
      code = 'my-authorization-code'
      server = nock "https://api.soundcloud.com"
      server.post("/oauth2/token", qs.stringify
        grant_type: 'authorization_code'
        redirect_uri: REDIRECT_URI
        client_id: CLIENT_ID
        client_secret: CLIENT_SECRET
        code: code
        verify_ssl: true
        proxies: null)
      .reply 200,
        access_token: 'my-access-token'
        refresh_token: 'my-refresh-token'
      client = new otogumo.Client CLIENT_ID, CLIENT_SECRET
      client.exchange_token code, REDIRECT_URI, (err)->
        assert.isNull err
        assert.equal client.access_token, 'my-access-token'
        assert.equal client.refresh_token, 'my-refresh-token'
        assert.isUndefined client.expires_in
        assert.isUndefined client.scope
        done()

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




