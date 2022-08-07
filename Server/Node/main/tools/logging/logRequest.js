const { requestLogger } = require('./loggers');
const { logServerError } = require('./logServerError');
const { databaseConnectionForLogging } = require('../database/establishDatabaseConnections');
const { databaseQuery } = require('../database/databaseQuery');
const { formatBoolean, formatString, formatNumber } = require('../format/formatObject');
const { areAllDefined } = require('../format/validateDefined');

// Outputs request to the console and logs to database
function logRequest(req, res, next) {
  let { appBuild } = req.params;
  let { ip, method } = req;
  const requestDate = new Date();

  appBuild = formatNumber(appBuild);
  appBuild = appBuild > 65535 ? 65535 : appBuild;

  ip = formatString(ip);
  ip = areAllDefined(ip) ? ip.substring(0, 32) : ip;

  method = formatString(method);
  method = areAllDefined(method) ? method.substring(0, 6) : method;

  let requestOriginalUrl = formatString(req.originalUrl);
  requestOriginalUrl = areAllDefined(requestOriginalUrl) ? requestOriginalUrl.substring(0, 500) : requestOriginalUrl;

  requestLogger.info(`Request for ${req.method} ${requestOriginalUrl}`);

  const hasBeenLogged = formatBoolean(req.hasBeenLogged);

  // Inserts request information into the previousRequests table.
  if (hasBeenLogged === false) {
    req.hasBeenLogged = true;
    databaseQuery(
      databaseConnectionForLogging,
      'INSERT INTO previousRequests(appBuild, requestIP, requestDate, requestMethod, requestOriginalURL) VALUES (?,?,?,?,?)',
      [appBuild, ip, requestDate, method, requestOriginalUrl],
    )
      .catch(
        (error) => {
          logServerError('logRequest', error);
        },
      );
  }

  next();
}

module.exports = { logRequest };