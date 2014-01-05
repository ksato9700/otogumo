co = require('co');
otogumo = require('..');

var client_id = process.env.SC_CLIENT_ID;
var client_secret = process.env.SC_CLIENT_SECRET;
var redirect_uri = process.env.SC_REDIRECT_URI;

client = otogumo.getClient(client_id, client_secret);

co(function* () {
	yield client.exchange_token('abc', redirect_uri);
})();


