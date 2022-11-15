import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import { expect } from "chai";

describe("ESignature", function () {
  async function deploy() {
    const [owner, otherAccount] = await ethers.getSigners();

    const ESignature = await ethers.getContractFactory("ESignature");
    const contract = await ESignature.deploy();

    return { contract, owner, otherAccount };
  }

  it("creates agreements", async function () {
    const { contract, owner } = await loadFixture(deploy);

    await contract.createAgreement("tax w9", "1234", "4321", "6789", [
      {
        identifier: "tax payer",
        signer: ethers.constants.AddressZero,
        used: false,
      },
    ]);

    const agreement = {
      ...(await contract.getAgreements(owner.address, 0))[0],
    };
    expect(agreement).to.include({
      owner: owner.address,
      status: 0,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      signedPackets: 0,
      totalPackets: 1,
    });
    expect({ ...agreement.constraints[0] }).to.include({
      identifier: "tax payer",
      signer: ethers.constants.AddressZero,
      used: false,
    });

    await contract.sign(owner.address, 0, "tax payer", "6543");

    expect({
      ...(await contract.getSignatures(owner.address, 0))[0],
    }).to.include({
      agreement_owner: owner.address,
      agreement_index: 0,
      index: 0,
      identifier: "tax payer",
      encryptedCid: "6543",
      signer: owner.address,
    });

    const agreementComplete = {
      ...(await contract.getAgreements(owner.address, 0))[0],
    };
    expect(agreementComplete).to.include({
      owner: owner.address,
      status: 1,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      signedPackets: 1,
      totalPackets: 1,
    });
    expect({ ...agreementComplete.constraints[0] }).to.include({
      identifier: "tax payer",
      signer: owner.address,
      used: true,
    });
  });
});
