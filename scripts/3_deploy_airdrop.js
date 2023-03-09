// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

require("@nomiclabs/hardhat-waffle");

const NUO_ADDRESS = "0xf1af3a65444f08Ff0c2c931261039924a8740f28";
const STAKING_CONTRACT_ADDRESS = "0x3b127f370f5Fb4822566c613FFeAf9C425B4325E";
const START_TIME = 1676640182;
const TRANCHE_TIME_IN_DAYS = 10;
const CLAIM_PERCENT = 10;
const CLAIMS_CAP = 10;

async function main() {
  const Airdrop = await ethers.getContractFactory("Airdrop");
  const airdrop = await upgrades.deployProxy(
    Airdrop,
    [
      NUO_ADDRESS,
      STAKING_CONTRACT_ADDRESS,
      START_TIME,
      TRANCHE_TIME_IN_DAYS,
      CLAIM_PERCENT,
      CLAIMS_CAP,
    ],
    { initializer: "initialise" }
  );

  await airdrop.deployed();

  console.log("Airdrop contract address", airdrop.address);

  console.log(
    "Verify command :",
    "npx hardhat verify --network goerli",
    airdrop.address,
    NUO_ADDRESS,
    STAKING_CONTRACT_ADDRESS,
    START_TIME,
    TRANCHE_TIME_IN_DAYS,
    CLAIM_PERCENT,
    CLAIMS_CAP
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
