// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ProviderNFTDealClient.sol";
import "./ClientNFTDealClient.sol";
import "./CommonNFTDealClient.sol";
import "./AgreementNFTDealClient.sol";

contract NFTDealClientFactory {
  address private _owner;
  uint256 private _payment;

  constructor(uint256 payment_) {
    _owner = msg.sender;
    _payment = payment_;
  }

  function setOwner(address newOwner) public {
    require(_owner == msg.sender);
    _owner = newOwner;
  }

  function setPayment(uint256 newPayment) public {
    require(_owner == msg.sender);
    _payment = newPayment;
  }

  function deployProviderDealClient(
    address nftAddress
  ) public payable returns (address) {
    require(msg.value == _payment, "Incorrect payment deposited");
    ProviderNFTDealClient client = new ProviderNFTDealClient(nftAddress);
    return address(client);
  }

  function deployClientDealClient(
    address nftAddress
  ) public payable returns (address) {
    require(msg.value == _payment, "Incorrect payment deposited");
    ClientNFTDealClient client = new ClientNFTDealClient(nftAddress);
    return address(client);
  }

  function deployCommonDealClient(
    address nftAddress
  ) public payable returns (address) {
    require(msg.value == _payment, "Incorrect payment deposited");
    CommonNFTDealClient client = new CommonNFTDealClient(nftAddress);
    return address(client);
  }

  function deployAgreementDealClient(
    address nftAddress,
    string calldata clientTokenURI,
    string calldata providerTokenURI
  ) public payable returns (address) {
    require(msg.value == _payment, "Incorrect payment deposited");
    AgreementNFTDealClient client = new AgreementNFTDealClient(
      nftAddress,
      clientTokenURI,
      providerTokenURI
    );
    return address(client);
  }
}
