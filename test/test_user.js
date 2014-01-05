//
// Copyright 2014 Kenichi Sato
// 
var otogumo = require('..');

var assert = require('chai').assert;
var nock = require('nock');
var qs = require('querystring');

var co = require('co');

var CLIENT_ID = 'foo'
var CLIENT_SECRET = 'bar'
var USERNAME = 'username'
var PASSWORD = 'password'
var SCOPE = undefined

describe('User', function() {
	describe('get_me', function() {
		it('should get my account information', function(done) {
			nock("https://api.soundcloud.com")
				.get("/me.json?oauth_token=my-access-token")
				.reply(200, {
					id: 1234567890,
					kind: 'user',
					permalink: 'my-permalink',
					username: 'my-username'})
				.post("/oauth2/token", qs.stringify({
					client_id: CLIENT_ID,
					client_secret: CLIENT_SECRET,
					username: USERNAME,
					password: PASSWORD,
					scope: SCOPE,
					grant_type: 'password'}))
				.reply(200, {
					access_token: 'my-access-token',
					expires_in: 'my-expires-in',
					refresh_token: 'my-refresh-token',
					scope: SCOPE})

			var client = otogumo.getClient(CLIENT_ID, CLIENT_SECRET);
			co(function*(){
				var cred = yield client.get_token_by_credentials(USERNAME, PASSWORD);
				var data = yield client.get_me(cred);
				assert.equal(data.id, 1234567890);
				assert.equal(data.kind, 'user');
				assert.equal(data.permalink, 'my-permalink');
				assert.equal(data.username, 'my-username');
				done()
			})();
		})

		it('should fail if it was not authenticated', function(done) {
			nock("https://api.soundcloud.com")
				.get("/me.json?oauth_token=my-access-token")
				.reply(200, {
					id: 1234567890,
					kind: 'user',
					permalink: 'my-permalink',
					username: 'my-username'});

			var client = otogumo.getClient(CLIENT_ID, CLIENT_SECRET);
			co(function*(){
				var data = yield client.get_me();
				assert.isNull(data);
				done();
			})();
		})
	})
})
