// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./nft/IAgreementNFT.sol";
import "./nft/AgreementNFTFactory.sol";

struct CreateAgreementParams {
  string identifier;
  string cid;
  string encryptedCid;
  string descriptionCid;
  bool withNFT;
  string nftImageCid;
  SignatureConstraint[] constraints;
}

struct SignParams {
  address agreementOwner;
  uint256 agreementIndex;
  string identifier;
  string encryptedCid;
  string nftTokenURI;
}

enum AgreementStatus {
  PENDING,
  COMPLETE,
  APPROVED,
  REJECTED
}

struct Profile {
  uint256 totalAgreements;
  uint256 totalSignatures;
}

struct SignatureConstraint {
  string identifier;
  address signer;
  uint256 totalUsed;
  uint256 allowedToUse;
}

struct Agreement {
  address owner;
  AgreementStatus status;
  uint256 index;
  string identifier;
  string cid;
  string encryptedCid;
  string descriptionCid;
  uint8 signedPackets;
  uint8 totalPackets;
  address nftContractAddress;
  SignatureConstraint[] constraints;
}

struct SignaturePacket {
  address agreementOwner;
  uint256 agreementIndex;
  uint256 index;
  string identifier;
  string encryptedCid;
  address signer;
  address nftContractAddress;
  uint256 nftTokenId;
  uint timestamp;
  uint blockNumber;
}

contract DigitalSignature {
  address private _nftFactoryAddress;
  mapping(address => Profile) profiles;
  mapping(address => mapping(uint256 => Agreement)) agreements;
  mapping(address => mapping(uint256 => SignaturePacket)) packets;

  constructor(address nftFactoryAddress_) {
    _nftFactoryAddress = nftFactoryAddress_;
  }

  function getProfile() public view returns (Profile memory) {
    return profiles[tx.origin];
  }

  function createAgreement(
    CreateAgreementParams memory params
  ) public returns (uint256) {
    Profile storage profile = profiles[tx.origin];
    Agreement storage agreement = agreements[tx.origin][
      profile.totalAgreements
    ];

    agreement.owner = tx.origin;
    agreement.status = AgreementStatus.PENDING;
    agreement.index = profile.totalAgreements;
    agreement.identifier = params.identifier;
    agreement.cid = params.cid;
    agreement.encryptedCid = params.encryptedCid;
    agreement.descriptionCid = params.descriptionCid;
    agreement.signedPackets = 0;
    agreement.totalPackets = uint8(params.constraints.length);

    for (uint i = 0; i < params.constraints.length; i++) {
      agreement.constraints.push(params.constraints[i]);
    }

    if (params.withNFT) {
      _deployNFTContract(agreement, params.nftImageCid);
    }

    return profile.totalAgreements++;
  }

  function _deployNFTContract(
    Agreement storage agreement,
    string memory nftImageCid
  ) internal returns (address) {
    IAgreementNFTFactory factory = IAgreementNFTFactory(_nftFactoryAddress);
    address nftContract = factory.deploy(
      agreement.identifier,
      agreement.identifier,
      nftImageCid
    );

    agreement.nftContractAddress = address(nftContract);
    return agreement.nftContractAddress;
  }

  function sign(SignParams calldata params) public returns (uint256) {
    Agreement storage agreement = agreements[params.agreementOwner][
      params.agreementIndex
    ];
    require(agreement.owner == params.agreementOwner, "Invalid agreement");
    require(
      agreement.status == AgreementStatus.PENDING,
      "Agreement is not PENDING"
    );

    SignatureConstraint storage constraint;
    bool found = false;
    for (uint i = 0; i < agreement.constraints.length; i++) {
      if (
        keccak256(abi.encodePacked(agreement.constraints[i].identifier)) ==
        keccak256(abi.encodePacked(params.identifier))
      ) {
        found = true;
        constraint = agreement.constraints[i];
        require(
          constraint.allowedToUse == 0 ||
            constraint.totalUsed < constraint.allowedToUse,
          "Signature already gathered"
        );
        require(
          constraint.signer == tx.origin || constraint.signer == address(0),
          "Mismatched signer"
        );
        constraint.totalUsed++;
        if (constraint.allowedToUse == 1) {
          constraint.signer = tx.origin;
        }

        break;
      }
    }

    require(found, "Missing signature constraint");

    Profile storage profile = profiles[tx.origin];

    SignaturePacket memory packet = SignaturePacket({
      agreementOwner: agreement.owner,
      agreementIndex: agreement.index,
      index: profile.totalSignatures,
      identifier: params.identifier,
      encryptedCid: params.encryptedCid,
      signer: tx.origin,
      nftContractAddress: agreement.nftContractAddress,
      nftTokenId: 0,
      timestamp: block.timestamp,
      blockNumber: block.number
    });

    if (agreement.nftContractAddress != address(0)) {
      IAgreementNFT nftContract = IAgreementNFT(agreement.nftContractAddress);
      packet.nftTokenId = nftContract.signatureMint(
        tx.origin,
        params.nftTokenURI
      );
    }

    packets[tx.origin][profile.totalSignatures] = packet;

    agreement.signedPackets++;
    if (agreement.signedPackets == agreement.totalPackets) {
      agreement.status = AgreementStatus.COMPLETE;
    }

    return profile.totalSignatures++;
  }

  function getAgreements(
    address owner,
    uint256 offset,
    uint8 limit
  ) public view returns (Agreement[] memory) {
    Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalAgreements - offset;
    uint totalToFetch = remaining > limit ? limit : remaining;
    Agreement[] memory ags = new Agreement[](totalToFetch);

    for (uint256 i = offset; i < offset + totalToFetch; i++) {
      ags[index++] = agreements[owner][i];
    }

    return ags;
  }

  function getSignatures(
    address owner,
    uint256 offset,
    uint8 limit
  ) public view returns (SignaturePacket[] memory) {
    Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalSignatures - offset;
    uint totalToFetch = remaining > limit ? limit : remaining;
    SignaturePacket[] memory sigs = new SignaturePacket[](totalToFetch);

    for (uint256 i = offset; i < offset + totalToFetch; i++) {
      sigs[index++] = packets[owner][i];
    }

    return sigs;
  }
}
