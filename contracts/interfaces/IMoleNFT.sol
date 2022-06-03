// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMoleNFT {
  enum LandType{GoldMiningPit, GoldKingdomPit, ForgingPit}

  function openBundle(address owner) external; 
  function mint(uint256 quantity, LandType landType) external;
}