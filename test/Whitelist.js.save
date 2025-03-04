const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether')
}

const ether = tokens

describe('NFT Whitelist', () => {
  const NAME = 'Dapp Punks'
  const SYMBOL = 'DP'
  const COST = ether(10)
  const MAX_SUPPLY = 25
  const MAX_MINT_AMOUNT = 5
  const BASE_URI = 'ipfs://QmQ2jnDYecFhrf3asEWjyjZRX1pZSsNWG3qHzmNDvXa9qg/'
  
  let nft, deployer, user1, user2, user3

  beforeEach(async () => {
    // Setup accounts
    let accounts = await ethers.getSigners()
    deployer = accounts[0]
    user1 = accounts[1]
    user2 = accounts[2]
    user3 = accounts[3]

    // Deploy NFT contract
    const ALLOW_MINTING_ON = Date.now().toString().slice(0, 10) // Now
    const NFT = await ethers.getContractFactory('NFT')
    nft = await NFT.deploy(
      NAME, 
      SYMBOL, 
      COST, 
      MAX_SUPPLY, 
      MAX_MINT_AMOUNT, 
      ALLOW_MINTING_ON, 
      BASE_URI
    )
  })

  describe('Whitelist Management', () => {
    it('should have whitelist mode enabled by default', async () => {
      expect(await nft.whitelistOnly()).to.equal(true)
    })

    it('allows owner to add addresses to whitelist', async () => {
      // Add user1 to whitelist
      await nft.connect(deployer).addToWhitelist(user1.address)
      expect(await nft.isAddressWhitelisted(user1.address)).to.equal(true)
      
      // Check that user2 is not whitelisted
      expect(await nft.isAddressWhitelisted(user2.address)).to.equal(false)
    })

    it('allows owner to add multiple addresses to whitelist', async () => {
      // Add multiple users to whitelist
      await nft.connect(deployer).addManyToWhitelist([
        user1.address,
        user2.address,
        user3.address
      ])
      
      // Verify all users are whitelisted
      expect(await nft.isAddressWhitelisted(user1.address)).to.equal(true)
      expect(await nft.isAddressWhitelisted(user2.address)).to.equal(true)
      expect(await nft.isAddressWhitelisted(user3.address)).to.equal(true)
    })

    it('allows owner to remove an address from whitelist', async () => {
      // First add user1 to whitelist
      await nft.connect(deployer).addToWhitelist(user1.address)
      expect(await nft.isAddressWhitelisted(user1.address)).to.equal(true)
      
      // Then remove them
      await nft.connect(deployer).removeFromWhitelist(user1.address)
      expect(await nft.isAddressWhitelisted(user1.address)).to.equal(false)
    })

    it('allows owner to toggle whitelist only mode', async () => {
      // Should be true by default
      expect(await nft.whitelistOnly()).to.equal(true)
      
      // Toggle it
      await nft.connect(deployer).toggleWhitelistOnly()
      expect(await nft.whitelistOnly()).to.equal(false)
      
      // Toggle it back
      await nft.connect(deployer).toggleWhitelistOnly()
      expect(await nft.whitelistOnly()).to.equal(true)
    })

    it('prevents non-owners from managing whitelist', async () => {
      // Try to add to whitelist as non-owner
      await expect(
        nft.connect(user1).addToWhitelist(user2.address)
      ).to.be.reverted
      
      // Try to add many as non-owner
      await expect(
        nft.connect(user1).addManyToWhitelist([user2.address, user3.address])
      ).to.be.reverted
      
      // Try to remove from whitelist as non-owner
      await expect(
        nft.connect(user1).removeFromWhitelist(user2.address)
      ).to.be.reverted
      
      // Try to toggle whitelist mode as non-owner
      await expect(
        nft.connect(user1).toggleWhitelistOnly()
      ).to.be.reverted
    })

    it('emits events when managing whitelist', async () => {
      // Test AddedToWhitelist event
      await expect(nft.connect(deployer).addToWhitelist(user1.address))
        .to.emit(nft, 'AddedToWhitelist')
        .withArgs(user1.address)
      
      // Test WhitelistOnlyToggled event
      await expect(nft.connect(deployer).toggleWhitelistOnly())
        .to.emit(nft, 'WhitelistOnlyToggled')
        .withArgs(false)
      
      // Test RemovedFromWhitelist event
      await expect(nft.connect(deployer).removeFromWhitelist(user1.address))
        .to.emit(nft, 'RemovedFromWhitelist')
        .withArgs(user1.address)
    })
  })

  describe('Minting with Whitelist', () => {
    it('allows whitelisted users to mint', async () => {
      // Add user1 to whitelist
      await nft.connect(deployer).addToWhitelist(user1.address)
      
      // User1 should be able to mint
      await nft.connect(user1).mint(1, { value: COST })
      
      // Check that the mint was successful
      expect(await nft.balanceOf(user1.address)).to.equal(1)
    })

    it('prevents non-whitelisted users from minting', async () => {
      // User2 is not whitelisted
      await expect(
        nft.connect(user2).mint(1, { value: COST })
      ).to.be.revertedWith('Address is not whitelisted')
    })

    it('allows anyone to mint when whitelist is disabled', async () => {
      // Disable whitelist
      await nft.connect(deployer).toggleWhitelistOnly()
      
      // User2 should now be able to mint without being whitelisted
      await nft.connect(user2).mint(1, { value: COST })
      
      // Check that the mint was successful
      expect(await nft.balanceOf(user2.address)).to.equal(1)
    })

    it('maintains other minting restrictions with whitelist', async () => {
      // Add user1 to whitelist
      await nft.connect(deployer).addToWhitelist(user1.address)
      
      // Test insufficient payment still fails
      await expect(
        nft.connect(user1).mint(1, { value: ether(1) })
      ).to.be.reverted
      
      // Test minting more than max amount still fails
      await expect(
        nft.connect(user1).mint(MAX_MINT_AMOUNT + 1, { value: COST.mul(MAX_MINT_AMOUNT + 1) })
      ).to.be.reverted
    })

    it('prevents minting when contract is paused even if whitelisted', async () => {
      // Add user1 to whitelist
      await nft.connect(deployer).addToWhitelist(user1.address)
      
      // Pause the contract
      await nft.connect(deployer).pause()
      
      // Try to mint
      await expect(
        nft.connect(user1).mint(1, { value: COST })
      ).to.be.revertedWith('Contract is paused')
    })
  })
})
