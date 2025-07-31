// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @custom:oz-upgrades-from OldToken
contract Token is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20BurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    struct LockInfo {
        uint256 lockedAt;
        uint256 lockedAmount;
        uint256 unlockAt;
    }

    address public stakingContractAddress;
    bool public isLockActive;
    uint256 public initSupply;
    uint256 public supplyFixedYears;
    uint256 public amountCanMintPerYear;
    uint256 public lockLimit;
    uint256 public deployedAt;
    uint256 public amountToIAO;

    mapping(uint256 => uint256) public mintedPerYear;
    mapping(address => LockInfo[]) private walletLockTimestamp;
    mapping(address => bool) public lockTransferAdmins;

    event LockDisabled(uint256 timestamp, uint256 blockNumber);
    event LockEnabled(uint256 timestamp, uint256 blockNumber);
    event TransferAndLock(address indexed from, address indexed to, uint256 value, uint256 blockNumber);
    event Mint(address indexed to, uint256 amount);
    event AddLockTransferAdmin(address indexed addr);
    event RemoveLockTransferAdmin(address indexed addr);
    event SetStakingContract(address indexed target);

    modifier onlyLockTransferAdminOrOwner() {
        require(lockTransferAdmins[msg.sender] || msg.sender == owner(), "Not lock transfer admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("DecentralGPT", "DGC");
        __ReentrancyGuard_init();
        __ERC20Permit_init("DecentralGPT");
        __ERC20Burnable_init();
        __UUPSUpgradeable_init();
        __Ownable_init(initialOwner);

        supplyFixedYears = 4;
        amountCanMintPerYear = 50_000_000_000 * 10 ** decimals();

        initSupply = 400_000_000_000 * 10 ** decimals();
        _mint(initialOwner, initSupply);
        isLockActive = true;
        deployedAt = block.timestamp;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        require(newImplementation != address(0), "Invalid implementation address");
    }

    function disableLock() external onlyOwner {
        isLockActive = false;
        emit LockDisabled(block.timestamp, block.number);
    }

    function enableLock() external onlyOwner {
        isLockActive = true;
        emit LockEnabled(block.timestamp, block.number);
    }

    function updateLockLimit(uint256 _lockLimit) external onlyOwner {
        lockLimit = _lockLimit;
    }

    // function updateLockDuration(address wallet, uint256 lockSeconds) external onlyOwner {
    //     require(wallet != owner(), "Invalid wallet address");
    //     LockInfo[] storage lockInfos = walletLockTimestamp[wallet];
    //     for (uint256 i = 0; i < lockInfos.length; i++) {
    //         lockInfos[i].unlockAt = lockInfos[i].lockedAt + lockSeconds;
    //     }
    //     emit UpdateLockDuration(wallet, lockSeconds);
    // }

    function burn(uint256 amount) public virtual override {
        if (isLockActive && walletLockTimestamp[msg.sender].length > 0) {
            require(canTransferAmount(msg.sender, amount), "Insufficient unlocked balance");
        }
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        if (isLockActive && walletLockTimestamp[account].length > 0) {
            require(canTransferAmount(account, amount), "Insufficient unlocked balance");
        }
        super.burnFrom(account, amount);
    }

    function transferAndLock(address to, uint256 value, uint256 lockSeconds) external onlyLockTransferAdminOrOwner {
        require(lockSeconds > 0, "Invalid lock duration");
        uint256 lockedAt = block.timestamp;
        uint256 unLockAt = lockedAt + lockSeconds;

        LockInfo[] storage infos = walletLockTimestamp[to];
        require(infos.length < lockLimit, "Too many lock entries"); // Limit lock entries

        infos.push(LockInfo(lockedAt, value, unLockAt));
        transfer(to, value);

        emit TransferAndLock(msg.sender, to, value, block.number);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (to == address(0) || amount == 0) {
            return super.transfer(to, amount);
        }

        if (isLockActive && walletLockTimestamp[msg.sender].length > 0) {
            require(canTransferAmount(msg.sender, amount), "Insufficient unlocked balance");
        }

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        if (to == address(0) || amount == 0) {
            return super.transferFrom(from, to, amount);
        }

        if (isLockActive && walletLockTimestamp[from].length > 0) {
            require(canTransferAmount(from, amount), "Insufficient unlocked balance");
        }

        return super.transferFrom(from, to, amount);
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        stakingContractAddress = stakingContract;
        emit SetStakingContract(stakingContract);
    }

    function mint() external {
        require(stakingContractAddress != address(0), "Invalid staking contract address");
        uint256 yearsSinceDeploy = (block.timestamp - deployedAt) / 365 days;
        require(yearsSinceDeploy >= supplyFixedYears, "Minting not allowed yet");
        require(mintedPerYear[yearsSinceDeploy] < amountCanMintPerYear, "Exceeds annual mint limit");

        mintedPerYear[yearsSinceDeploy] += amountCanMintPerYear;
        _mint(stakingContractAddress, amountCanMintPerYear);
        emit Mint(stakingContractAddress, amountCanMintPerYear);
    }

    function calculateLockedAmountAndUpdate(address from) public returns (uint256) {
        LockInfo[] storage lockInfos = walletLockTimestamp[from];
        uint256 lockedAmount = 0;
        uint256 i = 0;

        while (i < lockInfos.length) {
            if (block.timestamp < lockInfos[i].unlockAt) {
                lockedAmount += lockInfos[i].lockedAmount;
                i++;
            } else {
                lockInfos[i] = lockInfos[lockInfos.length - 1];
                lockInfos.pop();
            }
        }

        return lockedAmount;
    }

    function canTransferAmount(address from, uint256 transferAmount) internal returns (bool) {
        uint256 lockedAmount = calculateLockedAmountAndUpdate(from);
        uint256 availableAmount = balanceOf(from) - lockedAmount;
        return availableAmount >= transferAmount;
    }

    function calculateLockedAmount(address from) internal view returns (uint256) {
        LockInfo[] storage lockInfos = walletLockTimestamp[from];
        uint256 lockedAmount = 0;

        for (uint256 i = 0; i < lockInfos.length; i++) {
            if (block.timestamp < lockInfos[i].unlockAt) {
                lockedAmount += lockInfos[i].lockedAmount;
            }
        }

        return lockedAmount;
    }

    function getAvailableAmount(address caller) public view returns (uint256, uint256) {
        uint256 lockedAmount = calculateLockedAmount(caller);
        uint256 total = balanceOf(caller);
        uint256 availableAmount = total - lockedAmount;
        return (total, availableAmount);
    }

    function getLockAmountAndUnlockAt(address caller, uint256 index) public view returns (uint256, uint256) {
        require(index < walletLockTimestamp[caller].length, "Index out of range");
        LockInfo memory lockInfo = walletLockTimestamp[caller][index];
        return (lockInfo.lockedAmount, lockInfo.unlockAt);
    }

    function getLockInfos(address caller) public view returns (LockInfo[] memory) {
        LockInfo[] memory lockInfos = walletLockTimestamp[caller];
        return lockInfos;
    }

    function addLockTransferAdmin(address addr) external onlyOwner {
        lockTransferAdmins[addr] = true;
        emit AddLockTransferAdmin(addr);
    }

    function removeLockTransferAdmin(address addr) external onlyOwner {
        lockTransferAdmins[addr] = false;
        emit RemoveLockTransferAdmin(addr);
    }

    function lockSize(address addr) external view returns (uint256) {
        LockInfo[] memory lockInfos = walletLockTimestamp[addr];
        return lockInfos.length;
    }

    function version() external pure returns (uint256) {
        return 0;
    }
}
