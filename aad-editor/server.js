var connect = require('connect');
var serveStatic = require('serve-static');
var opn = require('opn');

connect().use(serveStatic(__dirname)).listen(8080, function(){
    console.log('Editor running on http server on port 8080...');
});
opn('http://localhost:8080');