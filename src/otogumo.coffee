#
# Copyright 2013 Kenichi Sato
# 
request = require 'request'

AUTHZ_URL = 'https://soundcloud.com/connect'
TOKEN_URL = 'https://api.soundcloud.com/oauth2/token'

class Client
  constructor: (@client_id, @client_secret)->

  get_token_by_credentials: (username, password, scope, cb)->
    if typeof scope is 'function'
      cb = scope
      scope = null
    options =
      method: 'POST'
      form:
        client_id: @client_id
        client_secret: @client_secret
        username: username
        password: password
        scope: scope || ''
        grant_type: 'password'

    request TOKEN_URL, options, (err, resp, body)=>
      if err
        cb err
      else
        body = JSON.parse body
        if resp.statusCode isnt 200
          cb body
        else
          @access_token = body.access_token
          @expires_in = body.expires_in
          @scope = body.scope
          @refresh_token = body.refresh_token
          cb err

exports.Client = Client
