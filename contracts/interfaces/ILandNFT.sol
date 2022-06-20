// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ILandNFT {
  enum LandType{GoldMiningPit, GoldKingdomPit, ForgingPit}
  function openBundle(address owner, LandType landType) external;
  function mint(address buyer, uint256 quantity, LandType landType, uint256 randomness) external;
  function getRarity(uint256 tokenId) external returns(uint256);
  
}