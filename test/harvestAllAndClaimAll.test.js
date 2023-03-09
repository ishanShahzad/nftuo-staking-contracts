const { expect, assert } = require("chai");
const {
  ethers: {
    utils: { parseEther, formatEther },
  },
  waffle,
  ethers,
} = require("hardhat");
const web3 = require("web3");
const {
  BNToFloat,
  to18Decimals,
  stringToFloat,
} = require("../utils/conversions");
const provider = waffle.provider;

const BN = web3.utils.BN;

require("chai")
  .use(require("chai-as-promised"))
  .use(require("chai-bn")(BN))
  .should();

const NAME = "NUO Token";
const SYMBOL = "NUO";
const TOTAL_SUPPLY = parseEther((300_000_000_000_000).toString());
const USERS_BAL = parseEther((1_000_000_000_010).toString());

const HARVESTING_BONUS_PERCENTAGE = 30;

const VAULT_0 = {
  apr: 60,
  maxCap: parseEther((1_000_000_000_000).toString()),
  cliff: 12 * 30 * 24 * 60 * 60,
};
const VAULT_1 = {
  apr: 90,
  maxCap: parseEther((500_000_000_000).toString()),
  cliff: 2 * 12 * 30 * 24 * 60 * 60,
};

const VAULT_2 = {
  apr: 120,
  maxCap: parseEther((500_000_000_000).toString()),
  cliff: 3 * 12 * 30 * 24 * 60 * 60,
};

const AMOUNT_TO_STAKE = parseEther((1_000).toString());
let STAKE_ID = 0;

const ONE_MONTH = 30 * 24 * 60 * 60;
const ONE_DAY = 24 * 60 * 60;
const ONE_YEAR = ONE_MONTH * 12 + ONE_DAY * 5;

let Vaults = [];

let Staking;
let NuoToken;

describe("Deploying Contracts", function () {
  it("Should Deploy NUO token Contract", async () => {
    [OWNER, _wallet, ZeroBalUser, ...users] = await ethers.getSigners();

    const NUO_TOKEN = await ethers.getContractFactory("NuoToken");
    NuoToken = await upgrades.deployProxy(
      NUO_TOKEN,
      [NAME, SYMBOL, TOTAL_SUPPLY],
      {
        initializer: "initialise",
      }
    );
    await NuoToken.deployed();
  });

  it("NUO token should be deployed successfully", async () => {
    let nuoAddress = NuoToken.address;
    nuoAddress.should.not.equal(ethers.constants.AddressZero);
  });

  it("Parameter should have been set accurately", async () => {
    let tokenName = await NuoToken.name();
    let tokenSymbol = await NuoToken.symbol();
    let tokenTotalSupply = await NuoToken.totalSupply();

    tokenName.should.be.equal(NAME);
    tokenSymbol.should.be.equal(SYMBOL);
    tokenTotalSupply.should.be.equal(TOTAL_SUPPLY);
  });

  it("Owner should be holding all supply", async () => {
    let ownerBal = await NuoToken.balanceOf(OWNER.address);
    ownerBal.should.be.equal(TOTAL_SUPPLY);
  });

  it("Should Deploy Staking Contract", async () => {
    const STAKING = await ethers.getContractFactory("Staking");
    Staking = await upgrades.deployProxy(
      STAKING,
      [
        NuoToken.address,
        _wallet.address,
        _wallet.address,
        HARVESTING_BONUS_PERCENTAGE,
      ],
      {
        initializer: "initialise",
      }
    );
    await Staking.deployed();
  });

  it("Staking should be deployed accurately", async () => {
    let stakingAddress = Staking.address;
    stakingAddress.should.not.equal(ethers.constants.AddressZero);

  });

  it("NUO contract should have been set accurately", async () => {
    let nuoToken = await Staking.getNuoToken();
    nuoToken.should.be.equal(NuoToken.address);
  });

  it("Wallet address should have been set accurately", async () => {
    let walletAddress = await Staking.getWalletAddress();
    walletAddress.should.be.equal(_wallet.address);
  });

  it("Deployer should be the owner", async () => {
    let ownerAddr = await Staking.owner();
    ownerAddr.should.be.equal(OWNER.address);

    ownerAddr = await NuoToken.owner();
    ownerAddr.should.be.equal(OWNER.address);
  });
});

describe("Vaults", function () {
  it("Should fetch Vaults", async () => {
    let vaults = await Staking.getVaults();
    Vaults = vaults;
    console.log("vaults", vaults);
  });
});


describe("Distribute NUO token for test accounts and update balances", function () {
  it("Should transfer tokens to all test accounts", async () => {
    await NuoToken.transfer(_wallet.address, USERS_BAL);
    for (let i = 0; i < users.length; i++) {
      await NuoToken.transfer(users[i].address, USERS_BAL);
    }

  });

  it("Users should have accurate NUO token balance to stake", async () => {
    let walletBal = await NuoToken.balanceOf(_wallet.address);
    walletBal.should.be.equal(USERS_BAL);
    for (let i = 0; i < users.length; i++) {
      let userBal = await NuoToken.balanceOf(users[i].address);
      userBal.should.be.equal(USERS_BAL);
    }
  });
});

describe("Set ERC20 allowance for test users", function () {
  it("should set allowance", async () => {
    await NuoToken.connect(_wallet).approve(Staking.address, USERS_BAL);

    for (let i = 0; i < users.length; i++) {
      await NuoToken.connect(users[i]).approve(Staking.address, USERS_BAL)
        .should.be.fulfilled;
    }
  });
  it("Validate approvals", async () => {
    let walletAllowance = await NuoToken.allowance(
      _wallet.address,
      Staking.address
    );
    walletAllowance.should.be.equal(USERS_BAL);

    for (let i = 0; i < users.length; i++) {
      let allowance = await NuoToken.allowance(
        users[i].address,
        Staking.address
      );
      allowance.should.be.equal(USERS_BAL);
    }
  });
});

describe("Stake", function () {
  describe("VAult 1", function () {
    it("Initially staked Tokens should be zero in Vault 1", async () => {
      let stakedInVault = await Staking.tokensStakedInVault(0);
      stakedInVault.should.be.equal(parseEther("0"));
    });

    it("User1 Should Stake In Vault 1 successfully", async () => {
      for (let i = 0; i < 3; i++) {
        STAKE_ID++;
        await Staking.connect(users[0]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }

    });

    it(" User2 Should Stake In Vault 1 successfully", async () => {

      for (let i = 0; i < 2; i++) {
        STAKE_ID++;
        await Staking.connect(users[1]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }
    });

    it("User3 Should Stake In Vault 1 successfully", async () => {
      for (let i = 0; i < 3; i++) {
        STAKE_ID++;
        await Staking.connect(users[2]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }
    });

    it("Should have updated staked amount in Vault 1", async () => {
      let stakedInVault = await Staking.tokensStakedInVault(0);
      stakedInVault.should.be.equal(AMOUNT_TO_STAKE.mul(8));
    });

    it("Total Stakes so far", async () => {
      let totalStakes = await Staking.totalStakes();

      totalStakes.should.be.equal(8);
    });

    it("Should update Stake balance in Vault_1", async () => {
      let tokensInVault1 = await Staking.tokensStakedInVault(0);
      tokensInVault1.should.be.equal(AMOUNT_TO_STAKE.mul(8));
    });

    it("users1 should be able to claim their rewards from Vault_1", async () => {
      await ethers.provider.send("evm_increaseTime", [ONE_YEAR]);
      await ethers.provider.send("evm_mine");

      stakeId1Reward = await Staking.getStakingReward(1);
      stakeId2Reward = await Staking.getStakingReward(2);
      stakeId3Reward = await Staking.getStakingReward(3);

      User1rewards = [stakeId1Reward, stakeId2Reward, stakeId3Reward];

      let user1Balance = await NuoToken.connect(users[0]).balanceOf(users[0].address)

      console.log("user1Balance is:", user1Balance)

      await Staking.connect(users[0]).claimAllReward(0);

      user1BalanceAfterClaim = await NuoToken.connect(users[0]).balanceOf(users[0].address)
      console.log("user1BalanceAfterClaim is:", user1BalanceAfterClaim)

    });

    it("user1 rewards info should have updated accordingly", async () => {
      for (let i = 0; i < 3; i++) {
        let {
          walletAddress,
          stakeId,
          stakedAmount,
          totalClaimed,
          vault,
          unstaked,
        } = await Staking.getStakeInfoById(i + 1);
        walletAddress.should.be.equal(users[0].address);
        stakeId.should.be.equal(i + 1);
        stakedAmount.should.be.equal(AMOUNT_TO_STAKE);
        totalClaimed.should.be.equal(User1rewards[i]);
        vault.should.be.equal(0);
        unstaked.should.be.equal(false);
      }
    });

    it("users2 should be able to claim their rewards from Vault_1", async () => {

      stakeId4Reward = await Staking.getStakingReward(4);
      stakeId5Reward = await Staking.getStakingReward(5);

      await Staking.connect(users[1]).claimAllReward(0);
      user2Rewards = [stakeId4Reward, stakeId5Reward]
    });

    it("user2 rewards info should have updated accordingly", async () => {
      for (let i = 0; i < 2; i++) {
        for (let j = 3; j < 5; j++) {
          let {
            walletAddress,
            stakeId,
            stakedAmount,
            totalClaimed,
            vault,
            unstaked,
          } = await Staking.getStakeInfoById(j + 1);
          walletAddress.should.be.equal(users[1].address);
          stakeId.should.be.equal(j + 1);
          stakedAmount.should.be.equal(AMOUNT_TO_STAKE);
          totalClaimed.should.be.equal(user2Rewards[i]);
          vault.should.be.equal(0);
          unstaked.should.be.equal(false);
        }
      }
    });

    it("users3 should be able to claim their rewards from Vault_1", async () => {

      stakeId6Reward = await Staking.getStakingReward(6);
      stakeId7Reward = await Staking.getStakingReward(7);
      stakeId8Reward = await Staking.getStakingReward(8);

      await Staking.connect(users[2]).claimAllReward(0);
      user3Rewards = [stakeId6Reward, stakeId7Reward, stakeId8Reward]

    });

    it("user3 rewards info should have updated accordingly", async () => {
      for (let i = 0; i < 3; i++) {
        for (let j = 5; j < 8; j++) {
          let {
            walletAddress,
            stakeId,
            stakedAmount,
            totalClaimed,
            vault,
            unstaked,
          } = await Staking.getStakeInfoById(j + 1);
          walletAddress.should.be.equal(users[2].address);
          stakeId.should.be.equal(j + 1);
          stakedAmount.should.be.equal(AMOUNT_TO_STAKE);
          totalClaimed.should.be.equal(user3Rewards[i]);
          vault.should.be.equal(0);
          unstaked.should.be.equal(false);
        }
      }
    });

    it("users3 should be able to harvest their rewards in Vault_1", async () => {

      await Staking.connect(users[0]).harvestAllRewardTokens(0, 0).
        should.be.rejectedWith("Stake: Insufficient rewards to stake");

    });
  });

  describe("Vault 1", function () {

    it("User4 Should Stake In Vault 1 successfully", async () => {
      for (let i = 0; i < 3; i++) {
        STAKE_ID++;
        await Staking.connect(users[4]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }

    });

    it(" User5 Should Stake In Vault 1 successfully", async () => {

      for (let i = 0; i < 2; i++) {
        STAKE_ID++;
        await Staking.connect(users[5]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }


    });

    it("User6 Should Stake In Vault 1 successfully", async () => {
      for (let i = 0; i < 3; i++) {
        STAKE_ID++;
        await Staking.connect(users[6]).stake(AMOUNT_TO_STAKE, 0).should.be
          .fulfilled;
      }

    });

    it("Should have updated staked amount in Vault 1", async () => {
      let stakedInVault = await Staking.tokensStakedInVault(0);
      stakedInVault.should.be.equal(AMOUNT_TO_STAKE.mul(16));
    });

    it("Total Stakes so far", async () => {
      let totalStakes = await Staking.totalStakes();
      totalStakes.should.be.equal(16);
    });

    it("Should update Stake balance in Vault_1", async () => {
      let tokensInVault1 = await Staking.tokensStakedInVault(0);
      tokensInVault1.should.be.equal(AMOUNT_TO_STAKE.mul(16));
    });

    it("users4 should be able to harvest their rewards from Vault_1", async () => {
      await ethers.provider.send("evm_increaseTime", [ONE_YEAR]);
      await ethers.provider.send("evm_mine");

      let harvestBalanceBeforeHarvest = await NuoToken.balanceOf(Staking.address)

      StakeId9Reward = await Staking.getStakingReward(9)
      StakeId10Reward = await Staking.getStakingReward(10)
      StakeId11Reward = await Staking.getStakingReward(11)


      await Staking.connect(users[4]).harvestAllRewardTokens(0, 1);

      harvestBalanceAfterHarvest = await NuoToken.balanceOf(Staking.address)

      harvestReward = harvestBalanceAfterHarvest - harvestBalanceBeforeHarvest

    });

    it("user4 harvest info should have updated accordingly", async () => {
      let newStaker = await Staking.totalStakes();
      let newStakerStackInfo = await Staking.getStakeInfoById(newStaker);
      harvestAmountUser4 = newStakerStackInfo.stakedAmount
      let vaultValue = newStakerStackInfo.vault;

      let user4StakedInVaults = await Staking.tokensStakedInVault(1)
      user4StakedInVaults.should.be.equal(harvestAmountUser4);

      let {
        walletAddress,
        stakeId,
        stakedAmount,
        totalClaimed,
        vault,
        unstaked,
      } = await Staking.getStakeInfoById(newStaker);
      walletAddress.should.be.equal(users[4].address);
      stakeId.should.be.equal(newStaker);
      stakedAmount.should.be.equal(harvestAmountUser4);
      totalClaimed.should.be.equal(0);
      vault.should.be.equal(vaultValue);
      unstaked.should.be.equal(false);
    });

    it("users5 should be able to harvest their rewards from Vault_1", async () => {

      await Staking.connect(users[5]).harvestAllRewardTokens(0, 2);
    });

    it("user5 harvest info should have updated accordingly", async () => {
      let newStaker = await Staking.totalStakes();
      let newStakerStackInfo = await Staking.getStakeInfoById(newStaker);
      harvestingAmountUser5 = newStakerStackInfo.stakedAmount

      let vaultValue = newStakerStackInfo.vault;

      console.log(vaultValue, 'VaultValue')

      user5StakedInVaults = await Staking.tokensStakedInVault(2)
      harvestingAmountUser5.should.be.equal(user5StakedInVaults);

      let {
        walletAddress,
        stakeId,
        stakedAmount,
        totalClaimed,
        vault,
        unstaked,
      } = await Staking.getStakeInfoById(newStaker);
      walletAddress.should.be.equal(users[5].address);
      stakeId.should.be.equal(newStaker);
      stakedAmount.should.be.equal(harvestingAmountUser5);
      totalClaimed.should.be.equal(0);
      vault.should.be.equal(vaultValue);
      unstaked.should.be.equal(false);
    });

    it("users6 should be able to harvest their rewards from Vault_1", async () => {

      await Staking.connect(users[6]).harvestAllRewardTokens(0, 2);

    });
    it("user6 harvest info should have updated accordingly", async () => {
      let newStaker = await Staking.totalStakes();
      let newStakerStackInfo = await Staking.getStakeInfoById(newStaker);
      harvestingAmountUser6 = newStakerStackInfo.stakedAmount

      let vaultValue = newStakerStackInfo.vault;
      user6StakedInVaults = await Staking.tokensStakedInVault(2)
      user6StakedInVaults.should.be.equal(harvestingAmountUser6.add(harvestingAmountUser5));

      let {
        walletAddress,
        stakeId,
        stakedAmount,
        totalClaimed,
        vault,
        unstaked,
      } = await Staking.getStakeInfoById(newStaker);
      walletAddress.should.be.equal(users[6].address);
      stakeId.should.be.equal(newStaker);
      stakedAmount.should.be.equal(harvestingAmountUser6);
      totalClaimed.should.be.equal(0);
      vault.should.be.equal(vaultValue);
      unstaked.should.be.equal(false);
    });
  });

  describe("Shouldn't claim the Reward ", function () {
    let reward;

    it("user1 tries to claim", async () => {
      await ethers.provider.send("evm_increaseTime", [ONE_YEAR]);
      await ethers.provider.send("evm_mine");

      await Staking.connect(users[0]).claimAllReward(0).
        should.be.rejectedWith("Stake: No Rewards to Claim");

    });

    it("users2 tries to claim", async () => {

      await Staking.connect(users[1]).claimAllReward(0).
        should.be.rejectedWith("Stake: No Rewards to Claim");
    });

    it("users3 tries to claim", async () => {

      await Staking.connect(users[2]).claimAllReward(0).
        should.be.rejectedWith("Stake: No Rewards to Claim");
    });
    it("should return the stake amount", async () => {

      let totalStakeAmount = await NuoToken.balanceOf(Staking.address)

      stakeBalance = await NuoToken.balanceOf(Staking.address)
      console.log("Stake Balance is", stakeBalance)
      let tokensInVault1 = await Staking.tokensStakedInVault(0);
      stakeBalance.should.be.equal(totalStakeAmount);
    });
  });
})
