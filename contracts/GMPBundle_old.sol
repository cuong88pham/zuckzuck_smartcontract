// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "./LandNFT.sol";
import "./MoleNFT.sol";


/// @custom:security-contact info@zuckzuck.land
contract GMPBundleOld is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    ERC20Burnable public token;
    enum BundleType{Normal, Rare, Mythic}
    address public beneficiary;
    bool public onlyWhitelisted;
    uint256 public totalBalance;
    uint constant E6 = 10**6;
    uint public APY;
    uint public PERIOD;
    uint public delay;
    uint public startTime;

    struct Item {
      uint256 tokenId;
      address owner;
      bool isGenesis;
      bool isOpened;
      BundleType bundleType; 
      uint landSpotSize;
      uint moleQuantity;
      uint256 minted_at; 
    }
    
    address[] public whitelistedAddresses;
    Item[] public items;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;
    mapping(address => mapping(BundleType => Item[])) public ownerOfBundles;
    mapping(address => mapping(BundleType => uint256)) public ownerCountByBundles;
    mapping (BundleType => uint256) NFTLimitCount;
    mapping (BundleType => uint256) NFTPrice;
    mapping (BundleType => uint256) NFTLandSlot;
    mapping (BundleType => uint256) NFTMoleSlot;
    mapping(uint256 => address) public BundletoOwner;
    bool private burnAfterOpen;
    // LandNFT public land;
    MoleNFT public mole;
    // MoleNFT public mole;

    event claimToken(address operator, uint amount );
    event PreOrder(address sender, BundleType bundleType, uint quantity, uint amount );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(ERC20Burnable _token, address _beneficiary, bool _burnAfterBurn) initializer public {
        __ERC721_init("GMPBundle", "GMPB");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        token = _token;
        onlyWhitelisted = false;
        totalBalance = 0;
        APY = 6;
        beneficiary=_beneficiary;
        NFTLimitCount[BundleType.Normal] = 2999;
        NFTLimitCount[BundleType.Rare] = 999;
        NFTLimitCount[BundleType.Mythic] = 99;
        
        NFTPrice[BundleType.Normal] = 500 * E6;
        NFTPrice[BundleType.Rare] = 1899 * E6;
        NFTPrice[BundleType.Mythic] = 3899 * E6;
        
        NFTLandSlot[BundleType.Normal] = 1;
        NFTLandSlot[BundleType.Rare] = 4;
        NFTLandSlot[BundleType.Mythic] = 9;
        
        NFTMoleSlot[BundleType.Normal] = 0;
        NFTMoleSlot[BundleType.Rare] = 3;
        NFTMoleSlot[BundleType.Mythic] = 9;
        startTime = block.timestamp;
        delay = 0;
        PERIOD = 30 days;
        burnAfterOpen = _burnAfterBurn;
        // land = LandNFT(0xfA8572fE85B6FD49e364CB4548828936f4FC49fb);
        mole = MoleNFT(0xA14Dab9a7851A297D567fa96d0e14193077677c9);
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

    function setERC20Token(ERC20Burnable _token) external onlyOwner{
        token = _token;
    }


    // function setLandToken(LandNFT _token) external onlyOwner{
    //     land = _token;
    // }

    function setMoleToken(MoleNFT _token) external onlyOwner{
        mole = _token;
    }

    function setAPY(uint _apy) external onlyOwner{
        APY = _apy;
    }

    function setNFTLimit(BundleType bundleType, uint256 limit) external onlyOwner{
        NFTLimitCount[bundleType] = limit;
    }

    function setNFTPrice(BundleType bundleType, uint256 cost) external onlyOwner{
        NFTPrice[bundleType] = cost * E6;
    }


    // Update beneficiary address by the previous beneficiary.
    function setBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function setStartTime(uint _startTime) public onlyOwner{
      startTime = _startTime;
    }

    function setDelay(uint _delay) public onlyOwner{
      delay = _delay;
    }
    function setPERIOD(uint _period) public onlyOwner{
      PERIOD = _period;
    }

    function getMyNFTs(BundleType bundleType) public view returns(Item[] memory nfts) {
       nfts = ownerOfBundles[msg.sender][bundleType];
    }
    
    function getNFTsbyAddress(address owner, BundleType bundleType) external view returns(Item[] memory nfts) {
        nfts = ownerOfBundles[owner][bundleType];
    }
    

    function burn(address owner, uint256 tokenId, BundleType bundleType) private {
        require(ownerOf(tokenId) == owner, "You are not owned it");
        Item[] memory nfts = getMyNFTs(bundleType);
        delete ownerOfBundles[owner][bundleType];
        if(nfts.length > 1) {
            for (uint256 index = 0; index < nfts.length; index++) {
                if(tokenId != nfts[index].tokenId) {
                    ownerOfBundles[owner][bundleType].push(nfts[index]);
                }
            }
        }
        _burn(tokenId);
    }
    
    // function openBundles(BundleType bundleType, LandNFT.LandType landType) external {
    //     Item[] memory nfts = getMyNFTs(bundleType);
    //     require(nfts.length > 0, "No item");
    //     for (uint256 index = 0; index < nfts.length; index++) {
    //         if(nfts[index].bundleType == BundleType.Normal){
    //             land.openBundles(msg.sender, landType);
    //         }else{
    //             for (uint256 i = 0; i < nfts[index].landSpotSize; i++) {
    //                 land.openBundles(msg.sender, landType);    
    //             }
    //             for(uint256 i = 0; i < nfts[index].moleQuantity; i++) {
    //                 mole.openBundles(msg.sender);
    //             }
    //         }
    //         burn(msg.sender, nfts[index].tokenId, bundleType);
    //     }
    // }

    function setBurnAfterOpen(bool _state) external onlyOwner {
        burnAfterOpen = _state;
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

    function ClaimToken() external onlyOwner {
        uint256 total_amount = token.balanceOf(address(this));
        token.transfer(beneficiary, total_amount);
        emit claimToken(beneficiary, total_amount);
    }
    function getAvailableSlot(BundleType bundleType) public view returns (uint256 count) {
        count = NFTLimitCount[bundleType];
    }
    function preorder(BundleType bundleType, uint256 quantity) public whenNotPaused notContract{
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "Whitelist: not in list");
        }
        require(quantity > 0, "Quality not zero");
        uint256 estAmount = NFTPrice[bundleType] * quantity;
        require(token.balanceOf(msg.sender) >= estAmount, "Not enough to staking");
        require(NFTLimitCount[bundleType] >= quantity, "NFT is limited");
        token.transferFrom(msg.sender, address(this), estAmount);
        for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, "https://api.zuckzuck.land/nfts/gmpbundle/");
            BundletoOwner[tokenId] = msg.sender;
        }
        ownerCountByBundles[msg.sender][bundleType] += quantity;
        balances[msg.sender] += estAmount;
        totalBalance += estAmount;
        NFTLimitCount[bundleType] -= quantity;
        
        emit PreOrder(msg.sender, bundleType, quantity, estAmount);
       
    }
    
    function countOfBundle(address user, BundleType bundleType) public view returns(uint256 count) {
        count = ownerCountByBundles[user][bundleType];
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