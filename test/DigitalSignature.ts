import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import {
  AgreementCallbackNFTFactory,
  DigitalSignature,
} from "../typechain-types";

describe("DigitalSignature", () => {
  let nftFactoryContract: AgreementCallbackNFTFactory;
  let contract: DigitalSignature;
  let owner: SignerWithAddress;
  let otherAccount: SignerWithAddress;

  before(async () => {
    [owner, otherAccount] = await ethers.getSigners();

    const nftFactory = await ethers.getContractFactory(
      "AgreementCallbackNFTFactory"
    );
    nftFactoryContract = await nftFactory.deploy();

    const DigitalSignature = await ethers.getContractFactory(
      "DigitalSignature"
    );

    contract = await DigitalSignature.deploy();
  });

  it("creates agreements", async function () {
    await contract.createAgreement({
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      constraints: [
        {
          identifier: "tax payer",
          signer: ethers.constants.AddressZero,
          totalUsed: 0,
          allowedToUse: 1,
        },
      ],
      agreementCallback: ethers.constants.AddressZero,
      signatureCallback: ethers.constants.AddressZero,
      extraInfo: Buffer.from(""),
    });
    const agreement = {
      ...(await contract.getAgreements(owner.address, 0, 1))[0],
    };
    expect(agreement).to.contain({
      owner: owner.address,
      status: 1,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      signedPackets: 0,
      totalPackets: 1,
      agreementCallback: ethers.constants.AddressZero,
      signatureCallback: ethers.constants.AddressZero,
    });
  });

  it("creates NFT agreements", async function () {
    await contract.createAgreement({
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      constraints: [
        {
          identifier: "tax payer",
          signer: ethers.constants.AddressZero,
          totalUsed: 0,
          allowedToUse: 1,
        },
        {
          identifier: "manager",
          signer: ethers.constants.AddressZero,
          totalUsed: 0,
          allowedToUse: 1,
        },
      ],
      agreementCallback: nftFactoryContract.address,
      signatureCallback: ethers.constants.AddressZero,
      extraInfo: Buffer.from("12345"),
    });
    const agreement = {
      ...(await contract.getAgreements(owner.address, 1, 1))[0],
    };
    expect(agreement).to.contain({
      owner: owner.address,
      status: 1,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      signedPackets: 0,
      totalPackets: 2,
    });
    expect(agreement.signatureCallback).to.not.equal(
      ethers.constants.AddressZero
    );
  });

  it("signs an agreement", async () => {
    await contract.sign({
      agreementOwner: owner.address,
      agreementIndex: 0,
      identifier: "tax payer",
      encryptedCid: "6543",
      extraInfo: Buffer.from("67676"),
    });

    const signature = {
      ...(await contract.getSignatures(owner.address, 0, 1))[0],
    };
    const agreement = {
      ...(await contract.getAgreements(owner.address, 0, 1))[0],
    };

    expect(signature).to.contain({
      agreementOwner: owner.address,
      identifier: "tax payer",
      encryptedCid: "6543",
      signer: owner.address,
    });

    expect(agreement).to.contain({
      owner: owner.address,
      status: 2,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      signedPackets: 1,
      totalPackets: 1,
      signatureCallback: ethers.constants.AddressZero,
    });
  });

  it("signs an NFT agreement", async () => {
    await contract.sign({
      agreementOwner: owner.address,
      agreementIndex: 1,
      identifier: "tax payer",
      encryptedCid: "6543",
      extraInfo: Buffer.from("67676"),
    });

    const signature = {
      ...(await contract.getSignatures(owner.address, 1, 1))[0],
    };
    const agreement = {
      ...(await contract.getAgreements(owner.address, 1, 1))[0],
    };

    expect({ ...signature }).to.contain({
      agreementOwner: owner.address,
      identifier: "tax payer",
      encryptedCid: "6543",
      signer: owner.address,
    });

    expect(agreement).to.contain({
      owner: owner.address,
      status: 1,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      signedPackets: 1,
      totalPackets: 2,
    });

    const nftContract = (
      await ethers.getContractFactory("AgreementNFT")
    ).attach(agreement.signatureCallback);

    expect(await nftContract.verifyByTokenURI(owner.address, "67676")).to.be
      .true;
  });

  it("errors when signing an already signed field", async () => {
    return expect(
      contract.sign({
        agreementOwner: owner.address,
        agreementIndex: 1,
        identifier: "tax payer",
        encryptedCid: "6543",
        extraInfo: Buffer.from("67676"),
      })
    ).to.rejectedWith("Signature already gathered");
  });

  it("signs an NFT agreement with a second signer", async () => {
    await contract.sign({
      agreementOwner: owner.address,
      agreementIndex: 1,
      identifier: "manager",
      encryptedCid: "6543",
      extraInfo: Buffer.from("4444"),
    });

    const signature = {
      ...(await contract.getSignatures(owner.address, 2, 1))[0],
    };
    const agreement = {
      ...(await contract.getAgreements(owner.address, 1, 1))[0],
    };

    expect({ ...signature }).to.contain({
      agreementOwner: owner.address,
      identifier: "manager",
      encryptedCid: "6543",
      signer: owner.address,
    });

    expect(agreement).to.contain({
      owner: owner.address,
      status: 2,
      identifier: "tax w9",
      cid: "1234",
      encryptedCid: "4321",
      descriptionCid: "6789",
      signedPackets: 2,
      totalPackets: 2,
    });

    const nftContract = (
      await ethers.getContractFactory("AgreementNFT")
    ).attach(agreement.signatureCallback);

    expect(await nftContract.verifyByTokenURI(owner.address, "4444")).to.be
      .true;
  });

  it("errors when signing a complete agreement", async () => {
    return expect(
      contract.sign({
        agreementOwner: owner.address,
        agreementIndex: 1,
        identifier: "manager",
        encryptedCid: "6543",
        extraInfo: Buffer.from("4444"),
      })
    ).to.rejectedWith("Agreement is not PENDING");
  });

  it("verifies true by token URI", async () => {
    const agreement = {
      ...(await contract.getAgreements(owner.address, 1, 1))[0],
    };

    const nftContract = (
      await ethers.getContractFactory("AgreementNFT")
    ).attach(agreement.signatureCallback);

    expect(await nftContract.verifyByTokenURI(owner.address, "67676")).to.be
      .true;
  });

  it("verifies false by token URI", async () => {
    const agreement = {
      ...(await contract.getAgreements(owner.address, 1, 1))[0],
    };

    const nftContract = (
      await ethers.getContractFactory("AgreementNFT")
    ).attach(agreement.signatureCallback);

    expect(await nftContract.verifyByTokenURI(owner.address, "123123")).to.be
      .false;
  });
});
