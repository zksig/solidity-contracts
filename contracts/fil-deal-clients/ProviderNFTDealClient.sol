// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { bytesToAddress } from "../utils/helpers.sol";
import "./NFTDealClient.sol";
import "../utils/ERC721NoEvents.sol";

contract ProviderNFTDealClient is NFTDealClient {
  constructor(address nftAddress) NFTDealClient(nftAddress) {}

  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    bytes calldata provider,
    uint size
  ) internal virtual override {
    ERC721NoEvents nftContract = ERC721NoEvents(nftAddress);

    require(
      nftContract.balanceOf(bytesToAddress(provider)) > 0,
      "Provider is missing required NFT"
    );
  }
}
