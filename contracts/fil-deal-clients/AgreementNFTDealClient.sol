// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { bytesToAddress } from "../utils/helpers.sol";
import { specific_authenticate_message_params_parse, specific_deal_proposal_cbor_parse } from "../utils/CBORParse.sol";
import "../AgreementNFT.sol";
import "./CommonNFTDealClient.sol";

contract AgreementNFTDealClient is CommonNFTDealClient {
  string public providerTokenURI;
  string public clientTokenURI;

  constructor(
    address _nftAddress,
    string memory _providerTokenURI,
    string memory _clientTokenURI
  ) CommonNFTDealClient(_nftAddress) {
    providerTokenURI = _providerTokenURI;
    clientTokenURI = _clientTokenURI;
  }

  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    bytes calldata provider,
    uint size
  ) public virtual override {
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
