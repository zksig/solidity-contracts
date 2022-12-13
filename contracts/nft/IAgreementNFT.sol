// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAgreementNFT {
  function signatureMint(
    address signer,
    string calldata tokenURI
  ) external returns (uint256);
}
