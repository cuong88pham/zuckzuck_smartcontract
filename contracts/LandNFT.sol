// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
/// @custom:security-contact info@zuckzuck.land
contract LandNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    enum LandType{GoldMining, GoldKingdom, Forging}
    uint constant E6 = 10**6;
    uint constant LandLimited = 15000;    
    bool public onlyWhitelisted;
    bool public allowPublicMint;
    bool public allowPublicMintGMP;
    bool public allowPublicMintGKP;
    bool public allowPublicMintForging;
    uint256 public landPrice;
    ERC20Burnable private _token;
    struct Land {
      uint256 tokenId;
      address owner;
      bool isGenesis;
      LandType landType;
      uint256 minted_at;
      LandState landState;
    }

    Land[] public lands;
    address[] public whitelistedAddresses;

    
    mapping (uint256 => address) public gmpIndexToOwner;
    mapping (address => mapping(LandType => uint256)) public ownershipGMPCount;
    mapping (address => uint256) public WhiteListAddress;
    mapping (LandType => uint256) NFTLimitCount;
    mapping (address => mapping(LandType => Land[])) public gmpsOwner;
    event BoughtLand(uint256 gmp_id, LandType landType);
    enum LandState{Seed, Hatched}
    address public bundleAddress;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(ERC20Burnable token, address _bundleAddress, bool _onlyWhitelisted) initializer public {
        __ERC721_init("ZuckZuck's Land", "LAND");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        NFTLimitCount[LandType.GoldMining] = LandLimited;
        NFTLimitCount[LandType.GoldKingdom] = LandLimited;
        NFTLimitCount[LandType.Forging] = LandLimited;
        _token = token;
        onlyWhitelisted = _onlyWhitelisted;
        allowPublicMint = false;
        landPrice = 500 * E6;
        allowPublicMintGMP= true;
        allowPublicMintGKP=false;
        allowPublicMintForging=false;
        bundleAddress = _bundleAddress;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setOnlyWhitelisted(bool _state) external onlyOwner {
        onlyWhitelisted = _state;
    }

    function setAllowPublicMint(bool _state) external onlyOwner {
        allowPublicMint = _state;
    }
    function setLandPrice(uint256 _price) external onlyOwner {
        landPrice = _price;
    }

    function mint(uint256 quantity, LandType landType) external {
        require(allowPublicMint, "Can not mint at now");
        if(landType == LandType.GoldMining){
            require(allowPublicMintGMP, "Can not mint at now");
        }
        if(landType == LandType.GoldKingdom){
            require(allowPublicMintGKP, "Can not mint at now");
        }
        if(landType == LandType.Forging){
            require(allowPublicMintForging, "Can not mint at now");
        }

        require(quantity > 0, "Not zero");
        require(NFTLimitCount[landType] + quantity <= LandLimited, "Land is limited");
        
        require(_token.allowance(msg.sender, address(this)) >= quantity * landPrice, "Need increase allowance");
        _token.transferFrom(msg.sender, address(this), quantity * landPrice);
         for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, _baseURI());
            Land memory land = Land({
                tokenId: tokenId,
                owner: msg.sender,
                isGenesis: false,
                landType: landType,
                minted_at: block.timestamp,
                landState: LandState.Seed
            });
            lands.push(land);
            gmpsOwner[msg.sender][landType].push(land);
            gmpIndexToOwner[tokenId] = msg.sender;
            emit BoughtLand(tokenId, landType);
         }
        ownershipGMPCount[msg.sender][landType] += quantity;
    }

    function openBundles(address owner, LandType landType) external {
        require(msg.sender == bundleAddress, "Not allow to open");
        if(landType == LandType.GoldMining){
            require(allowPublicMintGMP, "Can not mint at now");
        }
        if(landType == LandType.GoldKingdom){
            require(allowPublicMintGKP, "Can not mint at now");
        }
        if(landType == LandType.Forging){
            require(allowPublicMintForging, "Can not mint at now");
        }
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, _baseURI());
        Land memory land = Land({
            tokenId: tokenId,
            owner: owner,
            isGenesis: true,
            landType: landType,
            minted_at: block.timestamp,
            landState: LandState.Seed
        });
        lands.push(land);
        gmpsOwner[owner][LandType.GoldMining].push(land);
        gmpIndexToOwner[tokenId] = owner;
        emit BoughtLand(tokenId, landType);    
    }

    function setToken(ERC20Burnable token) public onlyOwner{
      _token = token;
    }
    function setbundleAddress(address token) public onlyOwner{
      bundleAddress = token;
    }
    
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.zuckzuck.land/land/metadata/";
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}