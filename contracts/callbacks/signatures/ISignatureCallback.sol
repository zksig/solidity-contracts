// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../types/DigitalSignatureTypes.sol";

interface ISignatureCallback {
  function signatureCallback(
    DigitalSignatureTypes.SignaturePacket memory packet,
    bytes memory extraInfo
  ) external;
}
