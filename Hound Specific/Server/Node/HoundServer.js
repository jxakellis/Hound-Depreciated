const bodyParser = require('body-parser');
const express = require('express');

const app = express();

const { assignConnection } = require('./databaseConnection');
const userRouter = require('./routes/user');

// parse form data
app.use((req, res, next) => {
  bodyParser.urlencoded({ extended: true })(req, res, (error) => {
    if (error) {
      // before creating a pool connection for request, so no need to release said connection
      return res.status(400).json({ message: 'Invalid Body; Unable to parse', error });
    }

    return next();
  });
});
app.use(express.urlencoded({ extended: false }));

// parse json
app.use((req, res, next) => {
  bodyParser.json()(req, res, (error) => {
    if (error) {
      // before creating a pool connection for request, so no need to release said connection
      return res.status(400).json({ message: 'Invalid Body; Unable to parse', error });
    }

    return next();
  });
});

// router for user requests

/*
/api/v1/user/:userId (OPT)
/api/v1/user/:userId/dogs/:dogId (OPT)
/api/v1/user/:userId/dogs/:dogId/logs/:logId (OPT)
/api/v1/user/:userId/dogs/:dogId/reminders/:reminderId (OPT)
*/

app.use('/', assignConnection);

app.use('/api/v1/user', userRouter);

// unknown path is specified
app.use('*', (req, res) => {
  // release connection
  req.rollbackQueries(req);
  return res.status(404).json({ message: 'Not Found', error: 'ER_NOT_FOUND' });
});

app.listen(5000, () => {
  console.log('Listening on port 5000');
});