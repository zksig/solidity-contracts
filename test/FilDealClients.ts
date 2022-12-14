import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import {
  AgreementNFT,
  AgreementNFTDealClient,
  ClientNFTDealClient,
  CommonNFTDealClient,
  DigitalSignature,
  ProviderNFTDealClient,
} from "../typechain-types";

describe.skip("Deal Clients", () => {
  let owner: SignerWithAddress;
  let otherAccount: SignerWithAddress;

  describe("ProviderNFTDealClient", () => {
    let contract: ProviderNFTDealClient;

    before(async () => {
      [owner, otherAccount] = await ethers.getSigners();

      const AgreementNFT = await ethers.getContractFactory("AgreementNFT");
      const nftContract = await AgreementNFT.deploy("nft", "NFT", "231");

      await nftContract.signatureMint(otherAccount.address, "1234");

      const ProviderNFTDealClient = await ethers.getContractFactory(
        "ProviderNFTDealClient"
      );
      contract = await ProviderNFTDealClient.deploy(nftContract.address);
    });

    it("allows an NFT owner", async () => {
      await contract.handle_filecoin_method(
        0,
        2643134072,
        Buffer.from(
          `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${owner.address.slice(
            2
          )}54${otherAccount.address.slice(
            2
          )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
          "hex"
        )
      );
    });

    it("rejects a non-NFT owner", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
              2
            )}54${owner.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Provider is missing required NFT");
    });
  });

  describe("ClientNFTDealClient", () => {
    let contract: ClientNFTDealClient;

    before(async () => {
      [owner, otherAccount] = await ethers.getSigners();

      const AgreementNFT = await ethers.getContractFactory("AgreementNFT");
      const nftContract = await AgreementNFT.deploy("nft", "NFT", "231");

      await nftContract.signatureMint(otherAccount.address, "1234");

      const ClientNFTDealClient = await ethers.getContractFactory(
        "ClientNFTDealClient"
      );
      contract = await ClientNFTDealClient.deploy(nftContract.address);
    });

    it("allows an NFT owner", async () => {
      await contract.handle_filecoin_method(
        0,
        2643134072,
        Buffer.from(
          `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
            2
          )}54${owner.address.slice(
            2
          )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
          "hex"
        )
      );
    });

    it("rejects a non-NFT owner", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${owner.address.slice(
              2
            )}54${otherAccount.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Client is missing required NFT");
    });
  });

  describe("CommonNFTDealClient", () => {
    let contract: CommonNFTDealClient;
    let nftContract: AgreementNFT;

    before(async () => {
      [owner, otherAccount] = await ethers.getSigners();

      const AgreementNFT = await ethers.getContractFactory("AgreementNFT");
      nftContract = await AgreementNFT.deploy("nft", "NFT", "231");

      await nftContract.signatureMint(otherAccount.address, "1234");

      const CommonNFTDealClient = await ethers.getContractFactory(
        "CommonNFTDealClient"
      );
      contract = await CommonNFTDealClient.deploy(nftContract.address);
    });

    it("rejects both client and provider are non-NFT owners", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${owner.address.slice(
              2
            )}54${otherAccount.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Client is missing required NFT");
    });

    it("rejects both client and provider are non-NFT owners", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
              2
            )}54${owner.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Provider is missing required NFT");
    });

    it("allows if both client and provider are NFT owners", async () => {
      await nftContract.signatureMint(owner.address, "5432");

      await contract.handle_filecoin_method(
        0,
        2643134072,
        Buffer.from(
          `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
            2
          )}54${owner.address.slice(
            2
          )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
          "hex"
        )
      );
    });
  });

  describe("AgreementNFTDealClient", () => {
    let contract: AgreementNFTDealClient;
    let nftContract: AgreementNFT;

    before(async () => {
      [owner, otherAccount] = await ethers.getSigners();

      const AgreementNFT = await ethers.getContractFactory("AgreementNFT");
      nftContract = await AgreementNFT.deploy("nft", "NFT", "231");

      await nftContract.signatureMint(otherAccount.address, "1234");

      const AgreementNFTDealClient = await ethers.getContractFactory(
        "AgreementNFTDealClient"
      );
      contract = await AgreementNFTDealClient.deploy(
        nftContract.address,
        "1234",
        "5432"
      );
    });

    it("rejects both client and provider are non-NFT owners", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${owner.address.slice(
              2
            )}54${otherAccount.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Client is missing required NFT");
    });

    it("rejects both client and provider are non-NFT owners", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
              2
            )}54${owner.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Provider is missing required NFT");
    });

    it("allows if both client and provider are NFT owners", async () => {
      await nftContract.signatureMint(owner.address, "5432");

      await contract.handle_filecoin_method(
        0,
        2643134072,
        Buffer.from(
          `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
            2
          )}54${owner.address.slice(
            2
          )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
          "hex"
        )
      );
    });

    it("rejects if the client owns the wrong NFT", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${owner.address.slice(
              2
            )}54${otherAccount.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Client does not own the right NFT");
    });

    it("rejects if the provider owns the wrong NFT", async () => {
      return expect(
        contract.handle_filecoin_method(
          0,
          2643134072,
          Buffer.from(
            `8240584c8bd82a5828000181e2039220206b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b190800f454${otherAccount.address.slice(
              2
            )}54${otherAccount.address.slice(
              2
            )}656c6162656c0a1a0008ca0a42000a42000a42000a`,
            "hex"
          )
        )
      ).to.be.rejectedWith("Provider does not own the right NFT");
    });
  });
});
