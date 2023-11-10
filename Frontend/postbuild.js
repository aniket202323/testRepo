const fs = require("fs-extra");

fs.remove("../API/eCIL/Client", (err) => {
  if (!err) console.log("Files removed successfully!");

  fs.copy("./build", "../API/eCIL/Client")
    .then(() => console.log("Build copy in folder Client successfully!"))
    .catch((err) => console.error(err));
});
