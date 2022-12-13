// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IAgreementNFTFactory.sol";
import "./AgreementNFT.sol";

contract AgreementNFTFactory {
  function deploy(
    string memory name,
    string memory symbol,
    string memory imageCID
  ) public returns (address) {
    AgreementNFT nftContract = new AgreementNFT(
      msg.sender,
      name,
      symbol,
      imageCID
    );
    return address(nftContract);
  }
}
