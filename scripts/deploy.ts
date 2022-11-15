import { ethers } from "hardhat";

async function main() {
  const ESignature = await ethers.getContractFactory("ESignature");
  const esig = await ESignature.deploy();

  await esig.deployed();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
