// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { specific_authenticate_message_params_parse, specific_deal_proposal_cbor_parse } from "../utils/CBORParse.sol";
import "../AgreementNFT.sol";
import "./CommonNFTDealClient.sol";

contract AgreementNFTDealClient is CommonNFTDealClient {
  string public providerTokenURI;
  string public clientTokenURI;

  constructor(
    address _nftAddress,
    string calldata _providerTokenURI,
    string calldata _clientTokenURI
  ) CommonNFTDealClient(_nftAddress) {
    providerTokenURI = _providerTokenURI;
    clientTokenURI = _clientTokenURI;
  }

  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    bytes calldata provider,
    uint size
  ) public {
    super.authorizeData(cidraw, client, provider);

    AgreementNFT nftContract = AgreementNFT(nftAddress);
    require(
      nftContract.verifyByTokenURI(client, clientTokenURI),
      "Client does not own the right NFT"
    );
    require(
      nftContract.verifyByTokenURI(provider, providerTokenURI),
      "Provider does not own the right NFT"
    );
  }
}
