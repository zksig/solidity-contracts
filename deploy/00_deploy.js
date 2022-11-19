require("hardhat-deploy");
require("hardhat-deploy-ethers");

const ethers = require("ethers");
const fa = require("@glif/filecoin-address");
const util = require("util");
const request = util.promisify(require("request"));

const DEPLOYER_PRIVATE_KEY = network.config.accounts[0];

async function callRpc(method, params) {
  var options = {
    method: "POST",
    url: "https://wallaby.node.glif.io/rpc/v0",
    // url: "http://localhost:1234/rpc/v0",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: 1,
    }),
  };
  const res = await request(options);
  return JSON.parse(res.body).result;
}

const deployer = new ethers.Wallet(DEPLOYER_PRIVATE_KEY);

module.exports = async ({ deployments, hardhatArguments }) => {
  const { deploy } = deployments;

  if (hardhatArguments.network === "sepolia") {
    await deploy("DigitalSignature", {
      from: deployer.address,
      args: [],
      log: true,
    });
  } else {
    const priorityFee = await callRpc("eth_maxPriorityFeePerGas");
    const f4Address = fa.newDelegatedEthAddress(deployer.address).toString();

    console.log("Wallet Ethereum Address:", deployer.address);
    console.log("Wallet f4Address: ", f4Address);

    await deploy("DigitalSignature", {
      from: deployer.address,
      args: [],
      maxPriorityFeePerGas: priorityFee,
      log: true,
    });
  }
};
module.exports.tags = ["DigitalSignature"];
