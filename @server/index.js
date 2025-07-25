const express = require('express');
const app = express();
const port = 3000;

// A successful route
app.get('/', (req, res) => {
  res.send('<h1>Server is up!</h1><p>This is the content from the remote server.</p>');
});

// Note: There is no /logo.png route. 
// The Cordova app will try to load this and get a 404 error, triggering the native fallback.

app.listen(port, () => {
  console.log(`Server listening at http://localhost:${port}`);
});
