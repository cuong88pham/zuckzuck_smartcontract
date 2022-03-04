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
contract MoleNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    enum MoleState{Seed, Hatched}
    uint constant E6 = 10**6;
    bool public onlyWhitelisted;
    bool public allowPublicMint;
    uint256 public molePrice;
    ERC20Burnable private _token;
    address public bundleAddress;
    struct Mole {
      uint256 tokenId;
      address owner;
      uint256 minted_at;
      MoleState moleState;
    }

    Mole[] public moles;
    address[] public whitelistedAddresses;

    
    mapping (uint256 => address) public moleIndexToOwner;
    mapping (address => uint256) public WhiteListAddress;
    mapping (address => Mole[]) public molesOwner;
    mapping (address => uint256) public ownershipMoleCount;
    event BoughtMole(uint256 mole_id);
  
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(ERC20Burnable token, address _bundleAddress, bool _onlyWhitelisted) initializer public {
        __ERC721_init("ZuckZuck Mole", "MOLE");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        _token = token;
        onlyWhitelisted = _onlyWhitelisted;
        allowPublicMint = false;
        molePrice = 100 * E6;
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
    function setMolePrice(uint256 _price) external onlyOwner {
        molePrice = _price;
    }

    function mint(uint256 quantity) external {
        require(allowPublicMint, "Can not mint at now");
        require(quantity > 0, "Not zero");
        
        require(_token.allowance(msg.sender, address(this)) >= quantity * molePrice, "Need increase allowance");
        _token.transferFrom(msg.sender, address(this), quantity * molePrice);
         for (uint256 index = 0; index < quantity; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, _baseURI());
            Mole memory mole = Mole({
                tokenId: tokenId,
                owner: msg.sender,
                minted_at: block.timestamp,
                moleState: MoleState.Seed
            });
            moles.push(mole);
            molesOwner[msg.sender].push(mole);
            moleIndexToOwner[tokenId] = msg.sender;
            emit BoughtMole(tokenId);
         }
        ownershipMoleCount[msg.sender] += quantity;
    }

    function openBundles(address owner) external {       
      require(msg.sender == bundleAddress, "Not allow to open");

      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      _safeMint(owner, tokenId);
      _setTokenURI(tokenId, _baseURI());
      Mole memory mole = Mole({
          tokenId: tokenId,
          owner: owner,
          minted_at: block.timestamp,
          moleState: MoleState.Seed
      });
      moles.push(mole);
      molesOwner[owner].push(mole);
      moleIndexToOwner[tokenId] = owner;
      ownershipMoleCount[owner] += 1;
      emit BoughtMole(tokenId);    
    }

    function setToken(ERC20Burnable token) public onlyOwner{
      _token = token;
    }
    
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    function _baseURI() internal pure override returns (string memory) {
        return "https://api.zuckzuck.land/mole/metadata/";
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