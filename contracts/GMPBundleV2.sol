// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
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
contract GMPBundleV2 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    
    enum Rarity {Normal, Rare, Mythic}
    enum TypeOfBox {GoldMiningPit, GoldKingdomPit, ForgingPit}
    
    struct Attribute {
      string name;
      string image_url;
      bool isGenesis;
      bool isOpened;
      uint landSpotSize;
      uint moleQuantity;
      Rarity rarity;
      TypeOfBox typeOfBox;
    }
    address[] public whitelistedAddresses;
    address public beneficiary;
    bool public onlyWhitelisted;
    bool public lockedTranfer;
    uint256 public totalBalance;
    uint256 public startingIndexBlock;
    uint256 public lockTime;
    uint256 public startSale;
    uint constant max_mint_number = 20;
    uint constant E6 = 10**6;
    string public baseURI;
    
    IERC20 public token;
    AggregatorV3Interface internal priceFeed;
    
    mapping (TypeOfBox => mapping(Rarity => uint256)) public NFTLimitCount;
    mapping (TypeOfBox => mapping(Rarity => uint256)) public NFTPrice;
    mapping (TypeOfBox => mapping(Rarity => uint256)) public NFTLandSlot;
    mapping (TypeOfBox => mapping(Rarity => uint256)) public NFTMoleSlot;
    mapping (TypeOfBox => mapping(Rarity => uint256)) public APY;
    
    mapping(uint256 => Attribute) public attributes;

    event Withdraw(address operator, uint amount );
    event PreOrder(address sender, Rarity rarity, uint quantity, uint amount );
    
    
    
    function initialize(string memory name, string memory symbol, address _beneficiary, IERC20 _token, uint256 _startSale) initializer public {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Ownable_init();
        beneficiary = _beneficiary;
        lockedTranfer = true;
        token = _token;
        
        NFTLimitCount[TypeOfBox.GoldMiningPit][Rarity.Normal] = 2999;
        NFTLimitCount[TypeOfBox.GoldMiningPit][Rarity.Rare] = 999;
        NFTLimitCount[TypeOfBox.GoldMiningPit][Rarity.Mythic] = 99;
        
        NFTPrice[TypeOfBox.GoldMiningPit][Rarity.Normal] = 500 * E6;
        NFTPrice[TypeOfBox.GoldMiningPit][Rarity.Rare] = 1899 * E6;
        NFTPrice[TypeOfBox.GoldMiningPit][Rarity.Mythic] = 3899 * E6;
        
        NFTLandSlot[TypeOfBox.GoldMiningPit][Rarity.Normal] = 1;
        NFTLandSlot[TypeOfBox.GoldMiningPit][Rarity.Rare] = 4;
        NFTLandSlot[TypeOfBox.GoldMiningPit][Rarity.Mythic] = 9;
        
        NFTMoleSlot[TypeOfBox.GoldMiningPit][Rarity.Normal] = 0;
        NFTMoleSlot[TypeOfBox.GoldMiningPit][Rarity.Rare] = 3;
        NFTMoleSlot[TypeOfBox.GoldMiningPit][Rarity.Mythic] = 9;
        
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        baseURI = "ipfs://";
        if(_startSale == 0) {
            _startSale = block.timestamp;
        }
        startSale = _startSale;
        lockTime = 86400 * 30 + startSale;
    }
    function setStartSale(uint256 _startSale) external onlyOwner{
        
        if(_startSale == 0) {
            _startSale = block.timestamp;
        }
        startSale = _startSale;
        lockTime = 86400 * 30 + startSale;
    }
    function setBaseURI(string memory _uri) external onlyOwner {
      baseURI = _uri;
    }
    // function safeMint(address to, uint256 tokenId, string memory _name, string memory _image_url, bool _isGenesis, uint _landSpotSize, uint _moleQuantity, Rarity _rarity, TypeOfBox _typeOfBox) public onlyOwner {
    function setDataPriceFeed(address maticUSD) external onlyOwner{
        priceFeed = AggregatorV3Interface(maticUSD);
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

    function setERC20Token(IERC20 _token) external onlyOwner{
        token = _token;
    }

    function setNFTLimit(TypeOfBox typeOfBox, Rarity rarity, uint256 limit) external onlyOwner{
        NFTLimitCount[typeOfBox][rarity] = limit;
    }

    function setNFTPrice(TypeOfBox typeOfBox, Rarity rarity, uint256 cost) external onlyOwner{
        NFTPrice[typeOfBox][rarity] = cost * E6;
    }

    // Update beneficiary address by the previous beneficiary.
    function setBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function getAvailableSlot(TypeOfBox typeOfBox, Rarity rarity) public view returns (uint256 count) {
        count = NFTLimitCount[typeOfBox][rarity];
    }
    function convertTOBtoString(TypeOfBox typeOfBox) internal pure returns(string memory) {
        if(typeOfBox == TypeOfBox.GoldMiningPit) {
            return "Gold Mining Pit";
        }
        if(typeOfBox == TypeOfBox.GoldKingdomPit) {
            return "Gold Kingdom Pit";
        }
        if(typeOfBox == TypeOfBox.ForgingPit) {
            return "Forging Pit";
        }
    }
    function convertRaritytoString(Rarity rarity) internal pure returns(string memory) {
        if(rarity == Rarity.Normal) {
            return "Single";
        }
        if(rarity == Rarity.Rare) {
            return "Rare";
        }
        if(rarity == Rarity.Mythic) {
            return "Mythic";
        }
    }
    function safeMint(address to, uint256 quantity, uint256 amount, Rarity rarity, TypeOfBox typeOfBox, string memory uri) public onlyOwner {
        require(quantity > 0, "Quality not zero");
        require(quantity < max_mint_number + 1, "Limited");
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, string(
                    abi.encodePacked(baseURI, uri)));
            string memory package_name = string(abi.encodePacked(convertTOBtoString(typeOfBox), " # ", uint2str(tokenId)));
            string memory image = string(abi.encodePacked(convertRaritytoString(rarity), ".gif"));
            attributes[tokenId] = Attribute(package_name, image , true, false, NFTLandSlot[typeOfBox][rarity], NFTMoleSlot[typeOfBox][rarity], rarity, TypeOfBox.GoldMiningPit);
        }
        
        emit PreOrder(to, rarity, quantity, amount * E6);
    }

    function preorder_with_erc20(TypeOfBox typeOfBox, Rarity rarity, uint256 quantity, string memory uri) public whenNotPaused notContract {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "Whitelist: not in list");
        }
        require(quantity > 0, "Quality not zero");
        uint256 estAmount = NFTPrice[typeOfBox][rarity] * quantity;
        require(token.balanceOf(msg.sender) >= estAmount, "Not enough to purchase");
        require(NFTLimitCount[typeOfBox][rarity] >= quantity, "NFT is limited");
        token.transferFrom(msg.sender, address(beneficiary), estAmount);
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, string(
                abi.encodePacked(baseURI, uri)));
            string memory package_name = string(abi.encodePacked(convertTOBtoString(typeOfBox), " # ", uint2str(tokenId)));
            string memory image = string(abi.encodePacked(convertRaritytoString(rarity), ".gif"));
            attributes[tokenId] = Attribute(package_name, image , true, false, NFTLandSlot[typeOfBox][rarity], NFTMoleSlot[typeOfBox][rarity], rarity, TypeOfBox.GoldMiningPit);
        }
        NFTLimitCount[typeOfBox][rarity] -= quantity;
        emit PreOrder(msg.sender, rarity, quantity, estAmount);
        
    }
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    function preorder_with_matic(TypeOfBox typeOfBox, Rarity rarity, uint256 quantity, string memory uri) payable public  whenNotPaused notContract {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "Whitelist: not in list");
        }
        require(quantity > 0, "Quality not zero");

        uint256 estAmount = 10**2 *  NFTPrice[typeOfBox][rarity] * quantity;
        int maticPrice = getLatestPrice();
        
        uint256 amount = 10**18 * estAmount / uint256(maticPrice);
        require(msg.value >= amount, "Not enough to purchase");
        require(NFTLimitCount[typeOfBox][rarity] >= quantity, "NFT is limited");
        
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, string(
                abi.encodePacked(baseURI, uri)));
            string memory package_name = string(abi.encodePacked(convertTOBtoString(typeOfBox), " # ", uint2str(tokenId)));
            string memory image = string(abi.encodePacked(convertRaritytoString(rarity), ".gif"));
            attributes[tokenId] = Attribute(package_name, image , true, false, NFTLandSlot[typeOfBox][rarity], NFTMoleSlot[typeOfBox][rarity], rarity, TypeOfBox.GoldMiningPit);
        }
        NFTLimitCount[typeOfBox][rarity] -= quantity;
        emit PreOrder(msg.sender, rarity, quantity, amount);
    }
    function SetLockTime(uint256 _lockTime) external onlyOwner {
        lockTime =_lockTime;
    }

    function SetStartingIndexBlock(uint256 number) public onlyOwner {
        startingIndexBlock = number;
    }
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

    function withdraw(bool erc_token) external onlyOwner whenNotPaused notContract {
        if(erc_token){
            uint256 total_amount = token.balanceOf(address(this));
            require(total_amount > 0, "empty");
            token.transfer(beneficiary, total_amount);
            emit Withdraw(beneficiary, total_amount);
        }
        else{
            require(address(this).balance > 0, "Empty");
            (bool succeed, bytes memory data) = payable(beneficiary).call{value: address(this).balance}("");
            require(succeed, "Failed to withdraw Ether");

        }
    } 
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyNFTs() public view returns (uint256[] memory tokenIds) {
        for (uint256 index = 0; index < balanceOf(msg.sender); index++) {
            tokenIds[index] = tokenOfOwnerByIndex(msg.sender, index);
        }
        return tokenIds;
    }
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        if(lockedTranfer){
            require(from == address(0), "Locked time");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function openBundle(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not owner");
        require(block.timestamp > lockTime, "Locked");
        _burn(tokenId);
    }
    
    function openBundles(uint256[] memory tokenIds) public {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            openBundle(tokenIds[index]);
        }
    }
    
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