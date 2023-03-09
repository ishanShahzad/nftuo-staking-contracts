const { ethers, upgrades } = require("hardhat");
require("@nomiclabs/hardhat-waffle");

const NUO_TOKEN_ADDRESS = "0xE1043012936b8a877D37bd64839544204638d035";
const TOKEN_PRICE_IN_USD = "100000000000000";
const MIN_AMOUNT = "100000000000000";
const USDC_TOKEN = "0x07865c6E87B9F70255377e024ace6630C1Eaa37F";
const WALLET = "0xE1043012936b8a877D37bd64839544204638d035";

const CHAINLINK_GOERLI_USDC_USD = "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7";

async function main() {
  const TokenSwap = await ethers.getContractFactory("TokenSwap");
  const tokenSwap = await upgrades.deployProxy(
    TokenSwap,
    [
      NUO_TOKEN_ADDRESS,
      TOKEN_PRICE_IN_USD,
      MIN_AMOUNT,
      USDC_TOKEN,
      CHAINLINK_GOERLI_USDC_USD,
    ],
    {
      initializer: "initialise",
    }
  );

  await tokenSwap.deployed();
  console.log("Token Swap contract address:", tokenSwap.address);

  console.log(
    "Verify command :",
    "npx hardhat verify --network goerli",
    tokenSwap.address,
    NUO_TOKEN_ADDRESS,
    TOKEN_PRICE_IN_USD,
    MIN_AMOUNT,
    CHAINLINK_GOERLI_USDC_USD,
    WALLET
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
