// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { bytesToAddress } from "../utils/helpers.sol";
import "../nft/AgreementNFT.sol";
import "./CommonNFTDealClient.sol";

contract AgreementNFTDealClient is CommonNFTDealClient {
  string public clientTokenURI;
  string public providerTokenURI;

  constructor(
    address _nftAddress,
    string memory _clientTokenURI,
    string memory _providerTokenURI
  ) CommonNFTDealClient(_nftAddress) {
    clientTokenURI = _clientTokenURI;
    providerTokenURI = _providerTokenURI;
  }

  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    bytes calldata provider,
    uint size
  ) internal virtual override {
    super.authorizeData(cidraw, client, provider, size);

    AgreementNFT nftContract = AgreementNFT(nftAddress);
    require(
      nftContract.verifyByTokenURI(bytesToAddress(client), clientTokenURI),
      "Client does not own the right NFT"
    );
    require(
      nftContract.verifyByTokenURI(bytesToAddress(provider), providerTokenURI),
      "Provider does not own the right NFT"
    );
  }
}
