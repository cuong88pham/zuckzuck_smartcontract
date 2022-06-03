// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/// @custom:security-contact info@zuckzuck.land
contract LandNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable {

    uint constant E6 = 10**6;
    uint constant LandLimited = 15000;    
    bool public onlyWhitelisted;
    bool public allowPublicMint;
    bool public allowPublicMintGMP;
    bool public allowPublicMintGKP;
    bool public allowPublicMintForging;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    IERC20 private _token;
    enum State{Seed, Hatched}
    enum LandType{GoldMiningPit, GoldKingdomPit, ForgingPit}
    enum Rarity{Special, Uncommon, Rare, Epic, Legendary, Mythic, Unique}
    enum ResourceType{Gold, Crystal, Water, Fire, Light, Mushroom, Rock, Wood}
    address private operatorAddress;
    struct Land {
      uint256 tokenId;
      address owner;
      bool isGenesis;
      LandType landType;
      uint256 minted_at;
      Rarity rarity;
      State state;
      uint256 asset_id;
      uint256 randomResult;
    }

    struct Resource {
        uint256 gold;
        uint256 copper;
        uint256 silver;
        uint256 water;
        uint256 gem;
        uint256 flame;
        uint256 score;
    }
    
    address[] public whitelistedAddresses;
    mapping (LandType => uint256) NFTLimitCount;
    mapping (LandType => uint256) public LandPrice;
    mapping(uint256 => Land) public lands;
    mapping(uint256 => Resource) public resourceOfLand;
    mapping(uint256 => string) private _tokenURIs;

    event BuyLand(uint256 tokenId, LandType landType, uint256 totalAmount);
    event OpenBundle(uint256 tokenId, LandType landType);
    address public bundleAddress;
    AggregatorV3Interface internal priceFeed;
    string public baseURL;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    
    modifier onlyOperatorOrOwner() {
        require(msg.sender == operatorAddress || msg.sender == this.owner(), "Not allow to do");
        _;
    }
    
    function setOperator(address _user) external onlyOwner{
        operatorAddress = _user;
    }
    
    function getLand(uint256 tokenId) external view returns(Land memory) {
        return lands[tokenId];
    }

    function initialize(string memory _name, string memory _symbol, IERC20 token, bool _onlyWhitelisted) initializer public {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        NFTLimitCount[LandType.GoldMiningPit] = LandLimited;
        NFTLimitCount[LandType.GoldKingdomPit] = LandLimited;
        NFTLimitCount[LandType.ForgingPit] = LandLimited;
        _token = token;
        onlyWhitelisted = _onlyWhitelisted;
        allowPublicMint = false;
        LandPrice[LandType.GoldMiningPit] = 500 * E6;
        LandPrice[LandType.GoldKingdomPit] = 500 * E6;
        LandPrice[LandType.ForgingPit] = 500 * E6;
        allowPublicMintGMP= true;
        allowPublicMintGKP=false;
        allowPublicMintForging=false;
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
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
    function setLandPrice(LandType landType, uint256 _price) external onlyOwner {
        LandPrice[landType] = _price;
    }
    function setBaseURL(string memory _baseURL) external onlyOwner {
        baseURL = _baseURL;
    }
    function mint(uint256 quantity, LandType landType) external {
        require(allowPublicMint, "Can not mint at now");
        if(landType == LandType.GoldMiningPit){
            require(allowPublicMintGMP, "Can not mint at now");
        }
        if(landType == LandType.GoldKingdomPit){
            require(allowPublicMintGKP, "Can not mint at now");
        }
        if(landType == LandType.ForgingPit){
            require(allowPublicMintForging, "Can not mint at now");
        }

        require(quantity > 0, "Not zero");
        require(NFTLimitCount[landType] + quantity <= LandLimited, "Land is limited");
        
        require(_token.allowance(msg.sender, address(this)) >= quantity * LandPrice[landType], "Need increase allowance");
        _token.transferFrom(msg.sender, address(this), quantity * LandPrice[landType]);
         for (uint256 index = 0; index < quantity; index++) {
            uint tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
            emit BuyLand(tokenId, landType, LandPrice[landType]);
         }
    }

    function openBundle(address owner, LandType landType) external {
        require(msg.sender == bundleAddress, "Cannot open");
        if(landType == LandType.GoldMiningPit){
            require(allowPublicMintGMP, "Can not mint at now");
        }
        if(landType == LandType.GoldKingdomPit){
            require(allowPublicMintGKP, "Can not mint at now");
        }
        if(landType == LandType.ForgingPit){
            require(allowPublicMintForging, "Can not mint at now");
        }
        
        uint256 tokenId = totalSupply();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uint2str(tokenId));

        emit OpenBundle(tokenId, landType);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    
    }
    function setDataPriceFeed(address maticUSD) external onlyOwner{
        priceFeed = AggregatorV3Interface(maticUSD);
    }

    function setToken(IERC20 token) public onlyOwner{
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
    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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
        override(ERC721Upgradeable)
    {
        super._burn(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

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