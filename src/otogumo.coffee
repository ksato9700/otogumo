#
# Copyright 2013 Kenichi Sato
# 
request = require 'request'
qs = require 'querystring'

AUTHZ_URL = 'https://soundcloud.com/connect'
API_URL_BASE = 'https://api.soundcloud.com'

class Client
  constructor: (@client_id, @client_secret)->

  _make_request: (url, options, cb)->
    request url, options, (err, resp, body)=>
      if err
        cb err
      else
        body = JSON.parse body
        if resp.statusCode isnt 200
          cb body
        else
          cb null, body

  _api_make_request: (path, options, cb)->
    @_make_request API_URL_BASE + path, options, cb

  _api_get: (path, args, cb)->
    @_api_make_request path, {method: 'GET', qs: args},  cb

  _api_post: (path, args, cb)->
    @_api_make_request path, {method: 'POST', form: args}, cb

  authorize_url: (redirect_uri)->
    options =
      scope: 'non-expiring'
      client_id: @client_id
      response_type: 'code'
      redirect_uri: redirect_uri
    return AUTHZ_URL + '?' + qs.stringify options

  _set_token: (args, cb)->
    @_api_post '/oauth2/token', args, (err, data)=>
      if not err
        @access_token = data.access_token
        @expires_in = data.expires_in
        @scope = data.scope
        @refresh_token = data.refresh_token
      cb err

  exchange_token: (code, redirect_uri, cb)->
    args =
      grant_type: 'authorization_code'
      redirect_uri: redirect_uri
      client_id: @client_id
      client_secret: @client_secret
      code: code
      verify_ssl: true
      proxies: null
    @_set_token args, cb

  get_token_by_credentials: (username, password, scope, cb)->
    if typeof scope is 'function'
      cb = scope
      scope = null

    args =
      client_id: @client_id
      client_secret: @client_secret
      username: username
      password: password
      scope: scope || ''
      grant_type: 'password'
    @_set_token args, cb

  get_me: (cb)->
    if not @access_token
      cb 'need to auth first'
      return
    @_api_get '/me.json', {oauth_token: @access_token}, cb

exports.Client = Client
