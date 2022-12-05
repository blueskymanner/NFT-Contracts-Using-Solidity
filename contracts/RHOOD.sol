// SPDX-License-Identifier: GPL-3.0
///@consensys SWC-103
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RHOOD is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;
    
    // Optional mapping for token URIs
    mapping (uint256 => string)  private _tokenURIs;
    mapping (address => uint256) private score;

    string public baseURI;
    string public baseExtension     = "";
    string public notRevealedUri    = "https://rhood-api.onrender.com/api/unrevealed";

    uint256 public cost             =   0.0799 ether;    
    uint256 public maxSupply        =   9999;
    uint256 public remainTokenAmount=   9999;
    uint256 public nftPerAddressLimit =  3;

    uint256 public onlyWhitelisted     = 0;
    uint256 public revealed            = 0;
    bool public paused              = false;
    
    uint256 public mintState        = 0; // 1 : Member pre-sale, 0: Public-sale
    address[] public whitelistedAddresses;

    address public manager;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    //owner & community manager can set score of any user 
    modifier onlyManager {
      require(msg.sender == owner() || msg.sender == manager);
      _;
    }

    // internal
    // convenience function to return the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Mint is paused");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "Cannot mint over supply cap of 9999");
        
        if (msg.sender != owner()) {
            require(getRemainNFTforUser(_to) >= _mintAmount, "Cannot mint over supply cap of each wallet amount");
            require(msg.value >= cost * _mintAmount, "Value below required mint fee for amount");
            if(mintState == 1) {  // mint state is private sale 
                require(isWhitelisted(msg.sender), "User is not whitelisted");
            }
        }
        _safeMint(_to, _mintAmount);
        remainTokenAmount -= _mintAmount;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721A Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if(revealed == 0) return notRevealedUri;
    
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, baseExtension));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    //set mint state 1: presale 0: public sale
    function setMintState(uint256 _mintState) public onlyOwner {
        require(_mintState < 2 && _mintState >= 0, "Input Wrong mint state" );
        mintState = _mintState;
    }

    //to be seen how many collections are minted and remained in frontend 
    function getRemainCollections() public view returns (uint256) {
        return remainTokenAmount;
    }

    function setRemainCollections(uint256 remainNFT) public onlyOwner{
        remainTokenAmount = remainNFT;
    }

    function setMaxSupply(uint256 _totalNFT) public onlyOwner{
        maxSupply = _totalNFT;
    }

    //to be seen how many nfts user minted and can mint
    function getRemainNFTforUser(address user) public view returns (uint256) {
        uint256 amount;
        if (user != owner()) {
            amount = nftPerAddressLimit - balanceOf(user);
        }else {
            amount = 200;
        }
        return amount;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_exists(tokenId), "ERC721A Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;  //"https://rhood-api.onrender.com/api/token/special_10"
    }
    
    //only owner
    function reveal(uint256 _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function getMintState() public view returns (uint256) {
        return mintState;
    }

    function getIsRevealed() public view returns (uint256) {
        return revealed;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setUnRevealedURI(string memory _UnRevealedURI) public onlyOwner {
        notRevealedUri = _UnRevealedURI;
    }

    function setRevealedURI(string memory _RevealedURI) public onlyOwner {
        reveal(1); setBaseURI(_RevealedURI);
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function isPaused() public view returns (uint256) {
        if(paused == true) return 1;
        return 0;
    }

    function setOnlyWhitelisted(uint256 _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setWhitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function addWhitelistUsers(address[] calldata _users) public onlyOwner {
        for(uint i = 0; i < _users.length; i++){
            whitelistedAddresses.push(_users[i]);
        }
    }

    function setScore(address _address, uint256 _newScore) public onlyManager {
        score[_address] = _newScore;
    }

    //user can get access special role if he/she has enough Score
    function getScore(address _address) public view returns (uint256) {
        return score[_address];
    }

    function setManagerAddress(address _address) public onlyOwner {
        manager = _address;
    }

    function withdraw() public payable onlyOwner {
        // =============================================================================

        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}