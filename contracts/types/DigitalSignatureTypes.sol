// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DigitalSignatureTypes {
  enum AgreementStatus {
    NEW,
    PENDING,
    COMPLETE,
    APPROVED,
    REJECTED
  }

  struct Profile {
    uint256 totalAgreements;
    uint256 totalSignatures;
    address agreementCallback;
    address signatureCallback;
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
    SignatureConstraint[] constraints;
    address agreementCallback;
    address signatureCallback;
  }

  struct SignaturePacket {
    address agreementOwner;
    uint256 agreementIndex;
    uint256 index;
    string identifier;
    string encryptedCid;
    address signer;
    uint timestamp;
    uint blockNumber;
  }
}
