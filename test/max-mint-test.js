const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

describe('NFT Max Mint Amount Test', () => {
  let nft, deployer, minter;
  const NAME = 'Dapp Punks';
  const SYMBOL = 'DP';
  const COST = tokens(10);
  const MAX_SUPPLY = 25;
  const MAX_MINT_AMOUNT = 5; // Maximum minting amount per transaction
  const BASE_URI = 'ipfs://QmQ2jnDYecFhrf3asEWjyjZRX1pZSsNWG3qHzmNDvXa9qg/';
  const ALLOW_MINTING_ON = Date.now().toString().slice(0, 10); // Now

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    deployer = accounts[0];
    minter = accounts[1];

    // Deploy the contract
    const NFT = await ethers.getContractFactory('NFT');
    nft = await NFT.deploy(
      NAME, SYMBOL, COST, MAX_SUPPLY, MAX_MINT_AMOUNT, ALLOW_MINTING_ON, BASE_URI
    );
    await nft.deployed();
  });

  it('sets the maximum mint amount correctly', async () => {
    const maxMintAmount = await nft.maxMintAmount();
    console.log(`Max mint amount set in contract: ${maxMintAmount}`);
    expect(maxMintAmount).to.equal(MAX_MINT_AMOUNT);
  });

  it('allows minting up to the maximum mint amount', async () => {
    // Mint the maximum allowed amount
    const mintAmount = MAX_MINT_AMOUNT;
    const totalCost = COST.mul(mintAmount);
    
    // This should succeed
    const tx = await nft.connect(minter).mint(mintAmount, { value: totalCost });
    await tx.wait();
    
    // Verify the minter received the tokens
    const balance = await nft.balanceOf(minter.address);
    console.log(`Minter balance after minting ${mintAmount} tokens: ${balance}`);
    expect(balance).to.equal(mintAmount);
  });

  it('reverts when trying to mint more than the maximum amount', async () => {
    // Try to mint one more than the maximum allowed
    const mintAmount = MAX_MINT_AMOUNT + 1;
    const totalCost = COST.mul(mintAmount);
    
    // This should fail
    await expect(
      nft.connect(minter).mint(mintAmount, { value: totalCost })
    ).to.be.revertedWith("Cannot mint more than max mint amount");
  });
});