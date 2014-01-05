//
// Copyright 2014 Kenichi Sato
//
var qs = require('querystring');
var request = require('co-request');

var AUTHZ_URL = 'https://soundcloud.com/connect';
var API_URL_BASE = 'https://api.soundcloud.com';
var OEMBED_URL = 'http://soundcloud.com/oembed';

//
//
//
function getClient(client_id, client_secret) {
	return new Client(client_id, client_secret);
}

var Client = function(client_id, client_secret) {
	this.client_id = client_id;
	this.client_secret = client_secret;
}

Client.prototype.authorize_url = function (redirect_uri) {
	var options = {
		'scope': 'non-expiring',
		'client_id': this.client_id,
		'response_type': 'code',
		'redirect_uri': redirect_uri
	};
    return AUTHZ_URL + '?' + qs.stringify(options);
}

Client.prototype._make_request = function* (url, options) {
	options = options || {};
	options.url = url;
	var resp = yield request(options);
	return JSON.parse(resp.body);
}

Client.prototype._api_make_request = function* (path, options) {
	return yield this._make_request(API_URL_BASE + path, options);
}

Client.prototype._api_get = function* (path, args) {
	return yield this._api_make_request(path, {method: 'GET', qs: args});
}

Client.prototype._api_post = function* (path, args) {
	return yield this._api_make_request(path, {method: 'POST', form: args});
}

Client.prototype._set_token = function* (args) {
	return yield this._api_post('/oauth2/token', args);
}

Client.prototype.exchange_token = function* (code, redirect_uri) {
	return yield this._set_token({
		grant_type: 'authorization_code',
		redirect_uri: redirect_uri,
		client_id: this.client_id,
		client_secret: this.client_secret,
		code: code,
		verify_ssl: true,
		proxies: null
	});
}

Client.prototype._do_get_token_by_credentials = function* (username, password, scope) {
    return yield this._set_token({
		client_id: this.client_id,
		client_secret: this.client_secret,
		username: username,
		password: password,
		scope: scope || '',
		grant_type: 'password',
	});
}

Client.prototype.get_token_by_credentials = function* (username, password, scope) {
    return yield this._do_get_token_by_credentials(username, password, scope);
}

Client.prototype.get_me = function* (data) {
	if (data && data.access_token) {
		return yield this._api_get('/me.json', {oauth_token: data.access_token});
	} else {
		return null;
	}
}

module.exports.getClient = getClient;
