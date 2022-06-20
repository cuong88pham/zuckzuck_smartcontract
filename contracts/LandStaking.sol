// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./interfaces/ILandNFT.sol";
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

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
/// @custom:security-contact dev@zuckzuck.land
contract LandStaking is Initializable, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    IERC20 public rewardToken;
    IERC721 public nft;
    uint256 public lockedPercent;
    uint256 public epocPeriod;
    uint256 public totalStaked;
    bool public initialised;
    uint256 public stakingStartTime;
    mapping(address => uint256) public OwnerTokenLocked;
    mapping(uint256 => uint256) public landCurrentEpoc;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => mapping(uint256 => Staker)) public stakers;
    struct Staker {
        address user;
        uint256 tokenId;
        uint256 stakingStartTime;
        uint256 balance;
        uint256 tokenLocked;
        uint256 paid;
        uint256 currentEpoc;
    }
    address public nftAddress;
    event Staked(address _user, uint256 _tokenId);
    event UnStaked(address _user, uint256 _tokenId);
    event RewardPaid(address _user, uint256 amount);
    event EmergencyUnstake(address _user, uint256 _tokenId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {      
    }

    function initialize(address _nft, address _rewardToken) initializer public {
        nft = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        __Ownable_init();
        lockedPercent = 95;
        epocPeriod = 10 days;
        initialised = false;
        totalStaked = 0;
        nftAddress = _nft;
    }


    function stakes(uint256 tokenId) public {
        _stake(tokenId, msg.sender);
    }

    function _stake(uint256 _tokenId, address _user) private {
        require(initialised, "Staking is not initialized");
        require(nft.ownerOf(_tokenId) == _user, "Only Onwer can stake");
        uint256 epoc = 1;
        if(landCurrentEpoc[_tokenId] > 0){
            epoc = landCurrentEpoc[_tokenId];
        }
        stakers[_user][_tokenId] = (Staker(_user, _tokenId, block.timestamp,0,0,0,epoc));
        tokenOwner[_tokenId] = _user;
        nft.safeTransferFrom(_user, address(this), _tokenId);
        landCurrentEpoc[_tokenId] = epoc;
        emit Staked(_user, _tokenId);
        totalStaked++;
        
    }
    function unstake(uint256 tokenId) public {
        
        Staker storage staker = stakers[msg.sender][tokenId];
        OwnerTokenLocked[msg.sender] = staker.tokenLocked;
        _unstake(tokenId, msg.sender);
        _claimReward(msg.sender, tokenId);

    }
    function _unstake(uint256 _tokenId, address _user) private {
        require(tokenOwner[_tokenId] == _user, "Only Owner");
        delete stakers[_user][_tokenId];
        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit UnStaked(_user, _tokenId);
        totalStaked--;
    }
    function _updateReward(address user, uint256 tokenId) private {
        Staker storage staker = stakers[user][tokenId];
        uint256 epoc = (block.timestamp - staker.stakingStartTime) / epocPeriod;
        uint256 patialDay = (block.timestamp - staker.stakingStartTime) % epocPeriod;  
        require(tokenOwner[tokenId] == msg.sender, "Only Onwer");
        require(epoc > 0, "Cant update reward");
        uint256 total_reward = staker.balance;
        uint256 rarity = ILandNFT(nftAddress).getRarity(tokenId);
        
        for (uint256 index = staker.currentEpoc; index <= epoc; index++) {
            total_reward += rewardLookup(index, rarity);
        }
        if(patialDay > 0) {
            total_reward += rewardLookup(epoc+1, rarity) / epocPeriod;
            staker.currentEpoc = epoc+1;
        }else{
            staker.currentEpoc = epoc;
        }
        staker.balance = total_reward;
        staker.tokenLocked = staker.balance * lockedPercent / 100;
        landCurrentEpoc[tokenId] = staker.currentEpoc;
    }
    function _claimReward(address user, uint256 tokenId) private {
        require(tokenOwner[tokenId] == user, "Only Onwer");

        _updateReward(user, tokenId);
        Staker storage staker = stakers[user][tokenId];
        require(staker.balance >= staker.paid + staker.tokenLocked, "Cant claim");
        uint256 release_reward = staker.balance - staker.tokenLocked;
        staker.paid = release_reward;
        rewardToken.approve(address(this), release_reward);
        rewardToken.transfer(user, release_reward);
        emit RewardPaid(user, release_reward);
    }
    function claimReward(uint256 tokenId) public {
        _claimReward(msg.sender, tokenId);
    }

    function rewardLookup(uint256 epoc, uint256 rarity_index) public pure returns(uint256) {
        uint72[7] memory rewards;
        if(epoc < 21){
            rewards = [20713000000000000000, 28036000000000000000, 42054000000000000000, 63081000000000000000, 78851000000000000000, 100356000000000000000, 196429000000000000000];
        }else if(epoc < 41) {
            rewards = [18412000000000000000, 24921000000000000000, 37381000000000000000, 56072000000000000000, 70090000000000000000, 89205000000000000000, 174603000000000000000];
        }else if(epoc < 61) {
            rewards = [15064000000000000000, 20390000000000000000, 30585000000000000000, 45877000000000000000, 57346000000000000000, 72986000000000000000, 142857000000000000000];
        }else if(epoc < 91) {
            rewards = [13809000000000000000, 18691000000000000000, 28036000000000000000, 42054000000000000000, 52567000000000000000, 66904000000000000000, 130953000000000000000];
        }else if(epoc < 103){
            rewards = [13256000000000000000, 17943000000000000000, 26914000000000000000, 40372000000000000000, 50465000000000000000, 64228000000000000000, 125714000000000000000];
        }
        return rewards[rarity_index];
    }

    function setNFTToken(address _nft) external onlyOwner {
        nft = IERC721(_nft);
    }
    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }
    function setEpocPeriod(uint256 _period) external onlyOwner {
        epocPeriod = _period;
    }
    function InitStaking() external onlyOwner{
        require(!initialised, "Initialized" );
        initialised = true;
        stakingStartTime = block.timestamp;
    }


}