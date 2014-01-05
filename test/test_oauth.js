//
// Copyright 2014 Kenichi Sato
// 
var otogumo = require('..');

var assert = require('chai').assert;
var nock = require('nock');
var qs = require('querystring');

var co = require('co');

var CLIENT_ID = 'foo';
var CLIENT_SECRET = 'bar';
var USERNAME = 'username';
var PASSWORD = 'password';
var SCOPE = undefined;
var REDIRECT_URI = 'http://example.com/redirect';

describe('Oauth', function() {
	describe('authorize_url', function() {
		it('should get authorize URL', function(done) {
			var client = new otogumo.getClient(CLIENT_ID, CLIENT_SECRET);
			var authz_url = client.authorize_url(REDIRECT_URI);
			assert.isString(authz_url);
			var options = qs.parse(authz_url.split('?')[1]);
			assert.equal(options.scope, 'non-expiring');
			assert.equal(options.client_id, CLIENT_ID);
			assert.equal(options.response_type, 'code');
			assert.equal(options.redirect_uri, REDIRECT_URI);
			done();
		})
	})

	describe('exchange_token', function() {
		it('should exchange authorization_code with access_token', function(done) {
			var code = 'my-authorization-code'
			var server = nock("https://api.soundcloud.com");
			server.post("/oauth2/token", qs.stringify({
					'grant_type': 'authorization_code',
					'redirect_uri': REDIRECT_URI,
					'client_id': CLIENT_ID,
					'client_secret': CLIENT_SECRET,
					'code': code,
					'verify_ssl': true,
					'proxies': null}))
				.reply(200, {
					'access_token': 'my-access-token',
					'refresh_token': 'my-refresh-token'
				});
			co(function* () {
				var client = otogumo.getClient(CLIENT_ID, CLIENT_SECRET);
				var resp = yield client.exchange_token(code, REDIRECT_URI);
				assert.isObject(resp);
				assert.equal(resp.access_token, 'my-access-token');
				assert.equal(resp.refresh_token, 'my-refresh-token');
				assert.isUndefined(resp.expires_in);
				assert.isUndefined(resp.scope);
				done();
			})();
		})
	})
})




