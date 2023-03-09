const { ethers, upgrades } = require("hardhat");
require("@nomiclabs/hardhat-waffle");

const NAME = "NUO Token";
const SYMBOL = "NUO";
const TOTAL_SUPPLY = ethers.utils.parseEther("1000000000000");

async function main() {
  const NuoToken = await hre.ethers.getContractFactory("NuoToken");

  const nuoToken = await upgrades.deployProxy(
    NuoToken,
    [NAME, SYMBOL, TOTAL_SUPPLY],
    {
      initializer: "initialise",
    }
  );
  await nuoToken.deployed();
  console.log("NUO Token contract address:", nuoToken.address);

  console.log(
    "Verify command :",
    "npx hardhat verify --network goerli",
    nuoToken.address,
    NAME,
    SYMBOL,
    TOTAL_SUPPLY.toString()
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
