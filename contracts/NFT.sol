// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    uint256 public allowMintingOn;

    bool public paused = false; // Pause minting
    bool public whitelistOnly = true; // Only allow whitelisted addresses to mint

    mapping (address => bool) public whitelist; // Whitelisted addresses

    event Mint(uint256 amount, address minter);
    event Withdraw(uint256 amount, address owner);
    event PauseStateChanged(bool paused);
    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event WhitelistOnlyToggled (bool whitelistOnly);
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        uint256 _allowMintingOn,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        allowMintingOn = _allowMintingOn;
        baseURI = _baseURI;
    }
    // Create a custom modifier to check if minting is paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    // Create a custom modifier to check if minting is whitelisted
    modifier whenWhitelisted() {
        require(whitelist[msg.sender] || !whitelistOnly, "Address is not whitelisted");
        _;
    }
    function pause() public onlyOwner {
        paused = true;
        emit PauseStateChanged(true);
    }
    function unpause() public onlyOwner {
        paused = false;
        emit PauseStateChanged(false);
    }
    // Toggle whitelist only mode
    function toggleWhitelistOnly() public onlyOwner {
        whitelistOnly = !whitelistOnly;
        emit WhitelistOnlyToggled(whitelistOnly);
    }

    // Add a single address to whitelist
    function addToWhitelist(address _user) public onlyOwner {
        whitelist[_user] = true;
        emit AddedToWhitelist(_user);
    }

    // Add multiple addresses to whitelist in one transaction
    function addManyToWhitelist(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
            emit AddedToWhitelist(_users[i]);
        }
    }

    // Remove an address from whitelist
    function removeFromWhitelist(address _user) public onlyOwner {
        whitelist[_user] = false;
        emit RemovedFromWhitelist(_user);
    }

    // Check if an address is whitelisted
    function isAddressWhitelisted(address _user) public view returns (bool) {
        return whitelist[_user];
    }
    function mint(uint256 _mintAmount) public payable whenNotPaused whenWhitelisted {
        // Only allow minting after specified time
        require(block.timestamp >= allowMintingOn);
        // Must mint at least 1 token
        require(_mintAmount > 0);
        // Require enough payment
        require(msg.value >= cost * _mintAmount);
        require(_mintAmount <= maxMintAmount, "Cannot mint more than max mint amount");
        uint256 supply = totalSupply();

        // Do not let them mint more tokens than available
        require(supply + _mintAmount <= maxSupply);

        // Create tokens
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        // Emit event
        emit Mint(_mintAmount, msg.sender);
    }

    // Return metadata IPFS url
    // EG: 'ipfs://QmQ2jnDYecFhrf3asEWjyjZRX1pZSsNWG3qHzmNDvXa9qg/1.json'
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns(string memory)
    {
        require(_exists(_tokenId), 'token does not exist');
        return(string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension)));
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for(uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Owner functions
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success);

        emit Withdraw(balance, msg.sender);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    // Add a function to change the max mint amount
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }
}
