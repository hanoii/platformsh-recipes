const fs = require('fs');
const { exec } = require("child_process");

const timeout = 2000

function watch() {
  console.log("Watching for changes on README.md...")
  let watcher = fs.watch('README.md', (event, filename) => {
    exec("ahoy readme", (error, stdout, stderr) => {
      console.log(stdout);
    })
    watcher.close()
    setTimeout(() => {
      watch();
    }, timeout);
  })
}

exec("ahoy readme", (error, stdout, stderr) => {
  console.log(stdout);
})
setTimeout(() => {
  watch();
}, timeout);
