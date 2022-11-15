// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

enum AgreementStatus {
  PENDING,
  COMPLETE,
  APPROVED,
  REJECTED
}

struct Profile {
  uint32 totalAgreements;
  uint32 totalSignatures;
}

struct SignatureConstraint {
  string identifier;
  address signer;
  bool used;
}

struct Agreement {
  address owner;
  AgreementStatus status;
  uint32 index;
  string identifier;
  string cid;
  string encryptedCid;
  string descriptionCid;
  uint8 signedPackets;
  uint8 totalPackets;
  SignatureConstraint[] constraints;
}

struct ESignaturePacket {
  address agreementOwner;
  uint32 agreementIndex;
  uint32 index;
  string identifier;
  string encryptedCid;
  address signer;
  uint timestamp;
  uint blockNumber;
}

contract ESignature {
  mapping(address => Profile) profiles;
  mapping(address => mapping(uint32 => Agreement)) agreements;
  mapping(address => mapping(uint32 => ESignaturePacket)) packets;

  function getProfile() public view returns (Profile memory) {
    return profiles[tx.origin];
  }

  function createAgreement(
    string calldata identifier,
    string calldata cid,
    string calldata encryptedCid,
    string calldata descriptionCid,
    SignatureConstraint[] memory constraints
  ) public returns (uint32) {
    Profile storage profile = profiles[tx.origin];
    Agreement storage agreement = agreements[tx.origin][
      profile.totalAgreements
    ];

    agreement.owner = tx.origin;
    agreement.status = AgreementStatus.PENDING;
    agreement.index = profile.totalAgreements;
    agreement.identifier = identifier;
    agreement.cid = cid;
    agreement.encryptedCid = encryptedCid;
    agreement.descriptionCid = descriptionCid;
    agreement.signedPackets = 0;
    agreement.totalPackets = uint8(constraints.length);

    for (uint i = 0; i < constraints.length; i++) {
      agreement.constraints.push(constraints[i]);
    }

    return profile.totalAgreements++;
  }

  function getAgreement(
    address owner,
    uint32 index
  ) public view returns (Agreement memory) {
    Profile memory profile = profiles[owner];
    require(index <= profile.totalAgreements, "index out of range");
    return agreements[owner][index];
  }

  function getAgreements(
    address owner,
    uint32 offset
  ) public view returns (Agreement[] memory) {
    Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalAgreements - offset;
    Agreement[] memory ags = new Agreement[](remaining > 10 ? 10 : remaining);

    for (uint32 i = offset; i < profile.totalAgreements; i++) {
      ags[index++] = agreements[owner][i];
    }

    return ags;
  }

  function sign(
    address agreementOwner,
    uint32 agreementIndex,
    string calldata identifier,
    string calldata encryptedCid
  ) public returns (uint32) {
    Agreement storage agreement = agreements[agreementOwner][agreementIndex];
    require(agreement.owner == agreementOwner, "Invalid agreement");
    require(
      agreement.status == AgreementStatus.PENDING,
      "Agreement is not PENDING "
    );

    SignatureConstraint storage constraint;
    bool found = false;
    for (uint i = 0; i < agreement.constraints.length; i++) {
      if (
        keccak256(abi.encodePacked(agreement.constraints[i].identifier)) ==
        keccak256(abi.encodePacked(identifier))
      ) {
        found = true;
        constraint = agreement.constraints[i];
        require(
          constraint.signer == tx.origin || constraint.signer == address(0),
          "Mismatched signer"
        );
        constraint.signer = tx.origin;
        constraint.used = true;
        break;
      }
    }

    require(found, "Missing signature constraint");

    Profile storage profile = profiles[tx.origin];

    packets[tx.origin][profile.totalSignatures] = ESignaturePacket({
      agreementOwner: agreement.owner,
      agreementIndex: agreement.index,
      index: profile.totalSignatures,
      identifier: identifier,
      encryptedCid: encryptedCid,
      signer: tx.origin,
      timestamp: block.timestamp,
      blockNumber: block.number
    });

    agreement.signedPackets++;
    if (agreement.signedPackets == agreement.totalPackets) {
      agreement.status = AgreementStatus.COMPLETE;
    }

    return profile.totalSignatures++;
  }

  function getSignature(
    address owner,
    uint32 index
  ) public view returns (ESignaturePacket memory) {
    Profile memory profile = profiles[owner];
    require(index <= profile.totalSignatures, "index out of range");
    return packets[owner][index];
  }

  function getSignatures(
    address owner,
    uint32 offset
  ) public view returns (ESignaturePacket[] memory) {
    Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalSignatures - offset;
    ESignaturePacket[] memory sigs = new ESignaturePacket[](
      remaining > 10 ? 10 : remaining
    );

    for (uint32 i = offset; i < profile.totalSignatures; i++) {
      sigs[index++] = packets[owner][i];
    }

    return sigs;
  }
}
