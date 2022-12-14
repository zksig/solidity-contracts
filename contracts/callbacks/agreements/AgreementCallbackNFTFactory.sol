// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IAgreementCallback.sol";
import "../../types/DigitalSignatureTypes.sol";
import "../../nft/AgreementNFT.sol";

contract AgreementCallbackNFTFactory is IAgreementCallback {
  function agreementCallback(
    DigitalSignatureTypes.Agreement memory agreement,
    bytes memory extraInfo
  ) public returns (AgreementCallbackResponse memory resp) {
    if (agreement.status == DigitalSignatureTypes.AgreementStatus.NEW) {
      AgreementNFT nftContract = new AgreementNFT(
        msg.sender,
        agreement.identifier,
        agreement.identifier,
        string(extraInfo)
      );

      return
        AgreementCallbackResponse({
          status: agreement.status,
          signatureCallback: address(nftContract)
        });
    } else {
      return
        AgreementCallbackResponse({
          status: agreement.status,
          signatureCallback: agreement.signatureCallback
        });
    }
  }
}
