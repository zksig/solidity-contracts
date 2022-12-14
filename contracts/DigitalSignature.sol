// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./nft/IAgreementNFT.sol";
import "./nft/AgreementNFTFactory.sol";
import "./callbacks/agreements/IAgreementCallback.sol";
import "./callbacks/signatures/ISignatureCallback.sol";
import "./types/DigitalSignatureTypes.sol";

struct CreateAgreementParams {
  string identifier;
  string cid;
  string encryptedCid;
  string descriptionCid;
  DigitalSignatureTypes.SignatureConstraint[] constraints;
  address agreementCallback;
  address signatureCallback;
  bytes extraInfo;
}

struct SignParams {
  address agreementOwner;
  uint256 agreementIndex;
  string identifier;
  string encryptedCid;
  bytes extraInfo;
}

contract DigitalSignature {
  mapping(address => DigitalSignatureTypes.Profile) profiles;
  mapping(address => mapping(uint256 => DigitalSignatureTypes.Agreement)) agreements;
  mapping(address => mapping(uint256 => DigitalSignatureTypes.SignaturePacket)) packets;

  function getProfile()
    public
    view
    returns (DigitalSignatureTypes.Profile memory)
  {
    return profiles[tx.origin];
  }

  function setProfileAgreementCallback(address agreementCallback) public {
    DigitalSignatureTypes.Profile storage profile = profiles[tx.origin];
    profile.agreementCallback = agreementCallback;
  }

  function setProfileSignatureCallback(address signatureCallback) public {
    DigitalSignatureTypes.Profile storage profile = profiles[tx.origin];
    profile.signatureCallback = signatureCallback;
  }

  function createAgreement(
    CreateAgreementParams memory params
  ) public returns (uint256) {
    DigitalSignatureTypes.Profile storage profile = profiles[tx.origin];
    DigitalSignatureTypes.Agreement storage agreement = agreements[tx.origin][
      profile.totalAgreements
    ];

    agreement.owner = tx.origin;
    agreement.status = DigitalSignatureTypes.AgreementStatus.NEW;
    agreement.index = profile.totalAgreements;
    agreement.identifier = params.identifier;
    agreement.cid = params.cid;
    agreement.encryptedCid = params.encryptedCid;
    agreement.descriptionCid = params.descriptionCid;
    agreement.signedPackets = 0;
    agreement.totalPackets = uint8(params.constraints.length);
    agreement.agreementCallback = params.agreementCallback;

    for (uint i = 0; i < params.constraints.length; i++) {
      agreement.constraints.push(params.constraints[i]);
    }

    _profileAgreementCallback(profile, agreement, params.extraInfo);
    _agreementCallback(agreement, params.extraInfo);

    if (agreement.status == DigitalSignatureTypes.AgreementStatus.NEW) {
      agreement.status = DigitalSignatureTypes.AgreementStatus.PENDING;
    }

    return profile.totalAgreements++;
  }

  function _profileAgreementCallback(
    DigitalSignatureTypes.Profile storage profile,
    DigitalSignatureTypes.Agreement storage agreement,
    bytes memory extraInfo
  ) internal {
    if (profile.agreementCallback == address(0)) {
      return;
    }

    IAgreementCallback cb = IAgreementCallback(profile.agreementCallback);
    AgreementCallbackResponse memory resp = cb.agreementCallback(
      agreement,
      extraInfo
    );
    agreement.status = resp.status;
    agreement.signatureCallback = resp.signatureCallback;
  }

  function _agreementCallback(
    DigitalSignatureTypes.Agreement storage agreement,
    bytes memory extraInfo
  ) internal {
    if (agreement.agreementCallback == address(0)) {
      return;
    }

    IAgreementCallback cb = IAgreementCallback(agreement.agreementCallback);
    AgreementCallbackResponse memory resp = cb.agreementCallback(
      agreement,
      extraInfo
    );
    agreement.status = resp.status;
    agreement.signatureCallback = resp.signatureCallback;
  }

  function sign(SignParams calldata params) public returns (uint256) {
    DigitalSignatureTypes.Agreement storage agreement = agreements[
      params.agreementOwner
    ][params.agreementIndex];
    require(agreement.owner == params.agreementOwner, "Invalid agreement");
    require(
      agreement.status == DigitalSignatureTypes.AgreementStatus.PENDING,
      "Agreement is not PENDING"
    );

    DigitalSignatureTypes.SignatureConstraint storage constraint;
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

    DigitalSignatureTypes.Profile storage profile = profiles[tx.origin];

    DigitalSignatureTypes.SignaturePacket memory packet = DigitalSignatureTypes
      .SignaturePacket({
        agreementOwner: agreement.owner,
        agreementIndex: agreement.index,
        index: profile.totalSignatures,
        identifier: params.identifier,
        encryptedCid: params.encryptedCid,
        signer: tx.origin,
        timestamp: block.timestamp,
        blockNumber: block.number
      });

    _profileSignatureCallback(profile, packet, params.extraInfo);
    _signatureCallback(agreement, packet, params.extraInfo);

    packets[tx.origin][profile.totalSignatures] = packet;

    agreement.signedPackets++;
    if (agreement.signedPackets == agreement.totalPackets) {
      agreement.status = DigitalSignatureTypes.AgreementStatus.COMPLETE;
      DigitalSignatureTypes.Profile storage agreementProfile = profiles[
        agreement.owner
      ];
      _profileAgreementCallback(agreementProfile, agreement, bytes(""));
      _agreementCallback(agreement, bytes(""));
    }

    return profile.totalSignatures++;
  }

  function _profileSignatureCallback(
    DigitalSignatureTypes.Profile storage profile,
    DigitalSignatureTypes.SignaturePacket memory packet,
    bytes memory extraInfo
  ) internal {
    if (profile.signatureCallback == address(0)) {
      return;
    }

    ISignatureCallback cb = ISignatureCallback(profile.signatureCallback);
    cb.signatureCallback(packet, extraInfo);
  }

  function _signatureCallback(
    DigitalSignatureTypes.Agreement storage agreement,
    DigitalSignatureTypes.SignaturePacket memory packet,
    bytes memory extraInfo
  ) internal {
    if (agreement.signatureCallback == address(0)) {
      return;
    }

    ISignatureCallback cb = ISignatureCallback(agreement.signatureCallback);
    cb.signatureCallback(packet, extraInfo);
  }

  function getAgreements(
    address owner,
    uint256 offset,
    uint8 limit
  ) public view returns (DigitalSignatureTypes.Agreement[] memory) {
    DigitalSignatureTypes.Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalAgreements - offset;
    uint totalToFetch = remaining > limit ? limit : remaining;
    DigitalSignatureTypes.Agreement[]
      memory ags = new DigitalSignatureTypes.Agreement[](totalToFetch);

    for (uint256 i = offset; i < offset + totalToFetch; i++) {
      ags[index++] = agreements[owner][i];
    }

    return ags;
  }

  function getSignatures(
    address owner,
    uint256 offset,
    uint8 limit
  ) public view returns (DigitalSignatureTypes.SignaturePacket[] memory) {
    DigitalSignatureTypes.Profile memory profile = profiles[owner];

    uint index = 0;
    uint remaining = profile.totalSignatures - offset;
    uint totalToFetch = remaining > limit ? limit : remaining;
    DigitalSignatureTypes.SignaturePacket[]
      memory sigs = new DigitalSignatureTypes.SignaturePacket[](totalToFetch);

    for (uint256 i = offset; i < offset + totalToFetch; i++) {
      sigs[index++] = packets[owner][i];
    }

    return sigs;
  }
}
