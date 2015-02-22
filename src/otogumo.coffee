#
# Copyright 2013 Kenichi Sato
#
request = require 'request'
qs = require 'querystring'
levelup = require 'levelup'
crypto = require 'crypto'

require('es6-promise').polyfill()

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
_make_request = (url, options)->
  new Promise (resolve, reject)->
    request url, options, (err, resp, body)->
      if err
        reject err
      else
        body = JSON.parse body
        if resp.statusCode isnt 200
          reject body
        else
          resolve body

_api_make_request = (path, options)->
  _make_request API_URL_BASE + path, options

_api_get = (path, args)->
  _api_make_request path, {method: 'GET', qs: args}

_api_post = (path, args)->
  _api_make_request path, {method: 'POST', form: args}

_get_cache = (key)->
  new Promise (resolve, reject)->
    cache.get key, (err, data)->
      if err
        reject err
      else
        resolve data

get_oembed = (url)->
  args =
    url: url
    format: 'json'
  _make_request OEMBED_URL, {method: 'GET', qs: args}

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

  _set_token: (args)->
    _api_post('/oauth2/token', args)
    .then (data)=>
      @access_token = data.access_token
      if data.expires_in
        @expires = new Date(new Date().getTime() + data.expires_in*1000)
      @scope = data.scope
      @refresh_token = data.refresh_token

      if args.username and args.password
        credential = hashed_credential args.username, args.password
        return @_store_cache credential
      else
        return Promise.resolve()

    .catch (error)->
      Promise.reject error

  exchange_token: (code, redirect_uri)->
    args =
      grant_type: 'authorization_code'
      redirect_uri: redirect_uri
      client_id: @client_id
      client_secret: @client_secret
      code: code
      verify_ssl: true
      proxies: null
    @_set_token args

  _store_cache:  (credential)->
    batch = cache.batch()
      .put(credential+'access_token', @access_token)
      .put(credential+'refresh_token', @refresh_token)
    if @expires
      batch.put(credential+'expires', @expires.toString())

    batch.write (err)->
      if err
        Promise.reject err
      else
        Promise.resolve()

  _lookup_cache: (credential)->
    Promise.all(['access_token','expires','refresh_token']
      .map((key)->credential+key)
      .map(_get_cache))
    .then (results)->
      results[1] = new Date results[1]
      Promise.resolve results
    .catch (error)->
      Promise.reject error

  _do_get_token_by_credentials: (username, password, scope)->
    args =
      client_id: @client_id
      client_secret: @client_secret
      username: username
      password: password
      scope: scope || ''
      grant_type: 'password'
    @_set_token args

  get_token_by_credentials: (username, password, scope)->
    credential = hashed_credential username, password
    @_lookup_cache credential
    .then (data)=>
      [@access_token, @expires, @refresh_token] = data
      Promise.resolve()
    .catch (error)=>
      if error.name == 'NotFoundError'
        return @_do_get_token_by_credentials username, password, scope
      else
        Promise.reject error

  get_me: ->
    if not @access_token
      Promise.reject 'need to auth first'
    else
      _api_get '/me.json', {oauth_token: @access_token}

exports.Client = Client
exports.get_oembed = get_oembed
