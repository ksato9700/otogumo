#
# Copyright 2013 Kenichi Sato
# 
otogumo = require '../lib/otogumo'

mocha = require 'mocha'
assert = require('chai').assert
nock = require 'nock'
qs = require 'querystring'

CLIENT_ID = 'foo'
CLIENT_SECRET = 'bar'
USERNAME = 'username'
PASSWORD = 'password'
SCOPE = undefined

describe 'User', ->
  describe 'get_me', ->
    it 'should get my account information', (done)->
      server = nock "https://api.soundcloud.com"
      server.get("/me.json?oauth_token=my-access-token")
      .reply 200,
        id: 1234567890
        kind: 'user'
        permalink: 'my-permalink'
        username: 'my-username'
      .post("/oauth2/token", qs.stringify
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
        assert.isUndefined err
        client.get_me (err, data)->
          assert.isNull err
          assert.equal data.id, 1234567890
          assert.equal data.kind, 'user'
          assert.equal data.permalink, 'my-permalink'
          assert.equal data.username, 'my-username'
          done()

    it 'should fail if it was not authenticated', (done)->
      server = nock "https://api.soundcloud.com"
      server.get("/me.json?oauth_token=my-access-token")
      .reply 200,
        id: 1234567890
        kind: 'user'
        permalink: 'my-permalink'
        username: 'my-username'

      client = new otogumo.Client CLIENT_ID, CLIENT_SECRET

      client.get_me (err, data)->
        assert.isString err
        assert.isUndefined data
        done()

