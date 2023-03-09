// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");
require("@nomiclabs/hardhat-waffle");

const NUO_ADDRESS = "0xf1af3a65444f08Ff0c2c931261039924a8740f28";
const WALLET = "0xE1043012936b8a877D37bd64839544204638d035";
const AIRDROP_CONTRACT_ADDRESS = "0x8088f908B0411C2d4Fb833F57306228a7BF32208";
const HARVEST_BONUS_PERCENTAGE = 30;

async function main() {
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await upgrades.deployProxy(
    Staking,
    [NUO_ADDRESS, WALLET, AIRDROP_CONTRACT_ADDRESS, HARVEST_BONUS_PERCENTAGE],
    {
      initializer: "initialise",
    }
  );

  await staking.deployed();

  console.log("Staking contract address", staking.address);

  console.log(
    "Verify command :",
    "npx hardhat verify --network goerli",
    staking.address,
    NUO_ADDRESS,
    WALLET,
    AIRDROP_CONTRACT_ADDRESS
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
