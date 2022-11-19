const cbor = require("cbor");

console.log(
  cbor.encode(Buffer.from("a96bb1719fa7f78b8B2d3c24BBc79e52Ae9a3988", "hex"))
);
