// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../types/DigitalSignatureTypes.sol";

struct AgreementCallbackResponse {
  DigitalSignatureTypes.AgreementStatus status;
  address signatureCallback;
}

interface IAgreementCallback {
  function agreementCallback(
    DigitalSignatureTypes.Agreement memory agreement,
    bytes memory extraInfo
  ) external returns (AgreementCallbackResponse memory resp);
}
