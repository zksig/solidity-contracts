// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAgreementNFTFactory {
  function deploy(
    string memory name,
    string memory symbol,
    string memory imageCID
  ) external returns (address);
}
