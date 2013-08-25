#
# Copyright 2013 Kenichi Sato
# 
request = require 'request'
qs = require 'querystring'
levelup = require 'levelup'
async = require 'async'
crypto = require 'crypto'

AUTHZ_URL = 'https://soundcloud.com/connect'
API_URL_BASE = 'https://api.soundcloud.com'
OEMBED_URL = 'http://soundcloud.com/oembed'

hashed_credential = (username, password)->
  md5sum = crypto.createHash 'md5'
  md5sum.update username+password, 'ascii'
  return md5sum.digest 'hex'

cache = null

#
# utility functions
#
_make_request = (url, options, cb)->
  request url, options, (err, resp, body)=>
    if err
      cb err
    else
      body = JSON.parse body
      if resp.statusCode isnt 200
        cb body
      else
        cb null, body

_api_make_request = (path, options, cb)->
  _make_request API_URL_BASE + path, options, cb

_api_get = (path, args, cb)->
  _api_make_request path, {method: 'GET', qs: args},  cb

_api_post = (path, args, cb)->
  _api_make_request path, {method: 'POST', form: args}, cb

get_oembed = (url, cb)->
  args =
    url: url
    format: 'json'
  _make_request OEMBED_URL, {method: 'GET', qs: args}, cb

#
# class
#
class Client
  constructor: (@client_id, @client_secret)->
    if not cache
      cache = levelup './cache'

  authorize_url: (redirect_uri)->
    options =
      scope: 'non-expiring'
      client_id: @client_id
      response_type: 'code'
      redirect_uri: redirect_uri
    return AUTHZ_URL + '?' + qs.stringify options

  _set_token: (args, cb)->
    _api_post '/oauth2/token', args, (err, data)=>
      if not err
        @access_token = data.access_token
        if data.expires_in
          @expires = new Date(new Date().getTime() + data.expires_in*1000)
        @scope = data.scope
        @refresh_token = data.refresh_token

        if args.username and args.password
          credential = hashed_credential args.username, args.password
          @_store_cache credential, cb
          return
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

  _store_cache:  (credential, cb)->
    cache.batch [
      {type:'put',key:credential+'access_token', value: @access_token},
      {type:'put',key:credential+'expires', value: @expires.toString()},
      {type:'put',key:credential+'refresh_token', value: @refresh_token}
    ], (err)->
      cb err
    
  _lookup_cache: (credential, cb)->
    async.map ['access_token','expires','refresh_token'], (item, callback)->
      cache.get credential+item, callback
    , (err, results)->
      results[1] = new Date results[1]
      cb err, results

  _do_get_token_by_credentials: (username, password, scope, cb)->
    args =
      client_id: @client_id
      client_secret: @client_secret
      username: username
      password: password
      scope: scope || ''
      grant_type: 'password'
    @_set_token args, cb

  get_token_by_credentials: (username, password, scope, cb)->
    if typeof scope is 'function'
      cb = scope
      scope = null

    credential = hashed_credential username, password
    @_lookup_cache credential, (err, data)=>
      if err
        if err.name == 'NotFoundError'
          @_do_get_token_by_credentials username, password, scope, cb
        else
          cb err
      else
        [@access_token, @expires, @refresh_token] = data
        cb()

  get_me: (cb)->
    if not @access_token
      cb 'need to auth first'
      return
    _api_get '/me.json', {oauth_token: @access_token}, cb

exports.Client = Client
exports.get_oembed = get_oembed
