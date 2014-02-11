/**
 * Post Install
 *
 * This is a simple script to check that everything on
 * the box has installed correctly
 *
 * @author Simon Emms <simon.emms@geopostuk.com>
 */


var exec = require("child_process").exec;
var http = require("http");
var os = require("os");


/* Only difference between scripts */
var is64Bit = true;


/**
 * Output
 *
 * Handles the output, with a simple success/fail
 * result
 *
 * @param {string} message
 * @param {boolean} success
 * @returns {undefined}
 */
function output(message, success) {

	function toColor(string) {

		var colors = {
			green: ["\x1B[32m", "\x1B[39m"],
			red: ["\x1B[31m", "\x1B[39m"],
			white: ["\x1B[37m", "\x1B[39m"]
		}

		message = "    - " + message + ": ";

		var out = "";

		out += success ? colors.white[0] : colors.red[0];
		out += message;
		out += success ? colors.white[1] : colors.red[1];

		for(var i = message.length; i < 100; i++) {
			out += " ";
		}

		out += "[";
		if(success) {
			out += colors.green[0];
			out += "OK";
			out += colors.green[1];
		} else {
			out += colors.red[0];
			out += "FAIL";
			out += colors.red[1];
		}
		out += "]";

		return out;
	}
	
	console.log(toColor(message));

}

/** Check system architecture **/
output("System architecture", is64Bit ? process.arch === "x64" : process.arch === "ia32");


/* Check global dependencies */
try {
	require("chai");
	output("NodeJS Chai", true);
} catch(err) {
	output("NodeJS Chai", false);
}

try {
	require("jshint");
	output("NodeJS JSHint", true);
} catch(err) {
	output("NodeJS JSHint", false);
}

try {
	require("mocha");
	output("NodeJS Mocha", true);
} catch(err) {
	output("NodeJS Mocha", false);
}

try {
	require("sinon");
	output("NodeJS Sinon", true);
} catch(err) {
	output("NodeJS Sinon", false);
}

try {
	require("supervisor");
	output("NodeJS Supervisor", true);
} catch(err) {
	output("NodeJS Supervisor", false);
}



/* N */
exec("which n", function(code, stdout, stderr) {

	if(typeof stdout === "string" && stdout.match(/\/bin\/n/)) {
		output("N", true);
	} else {
		output("N", false);
	}

});



/* MongoDB */
exec("which mongo", function(code, stdout, stderr) {

	if(typeof stdout === "string" && stdout.match(/mongo/)) {
		output("MongoDB", true);
	} else {
		output("MongoDB", false);
	}

});



/* MySQL */
exec("which mysql", function(code, stdout, stderr) {

	if(typeof stdout === "string" && stdout.match(/mysql/)) {
		output("MySQL", true);
	} else {
		output("MySQL", false);
	}

});



/* Apache */
var req = http.request({
	host: "localhost",
	port: 80,
	path: "/",
	method: "GET"
}, function(res) {
	
	res.setEncoding('utf8');

	var data = "";
	res.on("data", function(tmpData) {
		data += tmpData;
	});

	res.on("end", function() {
		if(data !== "") {
			output("Apache", true);
		}
	});

}).on("error", function(err) {
	output("Apache", false);
});
req.end();

/* Check IP */
var ip = is64Bit ? "10.20.30.60" : "10.20.30.50";
var interfaces = os.networkInterfaces();

var match = false;
for(var interface in interfaces) {
	var arrDetails = interfaces[interface];

	arrDetails.forEach(function(details) {
		if(details.address === ip) {
			match = true;
		}
	});
}

output("IP set to " + ip, match);