// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./MultiSigTimeLock.sol";

contract Token is Initializable, ERC20Upgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20BurnableUpgradeable, ReentrancyGuardUpgradeable {
    MultiSigTimeLock public timeLock;

    using SafeERC20 for IERC20;

    bool public isLockActive;

    struct LockInfo {
        uint256 lockedAt;
        uint256 lockedAmount;
        uint256 unlockAt;
    }

    mapping(address => LockInfo[]) private walletLockTimestamp;

    uint256 public initSupply;
    uint256 public maxSupply;
    uint256 public alreadyMinted;
    uint256 public supplyForStaking;
    uint256 public supplyForOrionStaking;

    mapping(address => uint256) public minter2MintAmount;
    mapping(address => bool) public lockTransferAdmins;

    event LockDisabled(uint256 timestamp, uint256 blockNumber);
    event LockEnabled(uint256 timestamp, uint256 blockNumber);
    event TransferAndLock(address indexed from, address indexed to, uint256 value, uint256 blockNumber);
    event UpdateLockDuration(address indexed wallet, uint256 lockSeconds);
    event Mint(address indexed to, uint256 amount);

    modifier onlyLockTransferAdmin() {
        require(lockTransferAdmins[msg.sender], "Not lock transfer admin");
        _;
    }


    modifier onlyMultiSigTimeLockContract() {
        require(msg.sender == address(timeLock), "Not multi sig time lock contract");
        _;
    }

    function initialize(address initialOwner,address timeLockAddress) public initializer {
        __ERC20_init("DecentralGPT", "DGC");
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();


        maxSupply = 1000_000_000_000 * 10 ** decimals();
        supplyForStaking = 400_000_000_000 * 10 ** decimals();
        supplyForOrionStaking = 45_000_000_000 * 10 ** decimals();
        initSupply = maxSupply - supplyForStaking - supplyForOrionStaking;
        alreadyMinted = initSupply;

        _mint(owner(), initSupply);
        isLockActive = true;
        timeLock = MultiSigTimeLock(timeLockAddress);
    }

    function requestSetMinter(address minter, uint256 amount) external pure returns (bytes memory) {
        bytes memory data = abi.encodeWithSignature("mint(address,uint256)", minter, amount);
        return data;
    }

    function setMinter(address minter, uint256 amount) external onlyMultiSigTimeLockContract {
        require(amount <= maxSupply - alreadyMinted, "Max supply reached");
        minter2MintAmount[minter] = amount;
    }

    function mint(address to, uint256 amount) external {
        uint256 totalAmount = minter2MintAmount[msg.sender];
        require(totalAmount >= amount, "Mint amount exceeds allowance");
        require(alreadyMinted + amount <= maxSupply, "Max supply reached");

        _mint(to, amount);
        minter2MintAmount[msg.sender] -= amount;
        alreadyMinted += amount;

        emit Mint(to, amount);
    }

    function requestDisableLockPermanently() external pure returns (bytes memory) {
        bytes memory data = abi.encodeWithSignature("disableLockPermanently()");
        return data;
    }

    function disableLockPermanently() external onlyMultiSigTimeLockContract {
        isLockActive = false;
        emit LockDisabled(block.timestamp, block.number);
    }

    function requestEnableLockPermanently() external pure returns (bytes memory) {
        bytes memory data = abi.encodeWithSignature("enableLockPermanently()");
        return data;
    }


    function enableLockPermanently() external onlyMultiSigTimeLockContract {
        isLockActive = true;
        emit LockEnabled(block.timestamp, block.number);
    }

    function requestUpdateLockDuration(address wallet, uint256 lockSeconds) external pure returns (bytes memory)  {
        bytes memory data = abi.encodeWithSignature("updateLockDuration(address,uint256)",wallet,lockSeconds);
        return data;
    }

    function updateLockDuration(address wallet, uint256 lockSeconds) external onlyMultiSigTimeLockContract {
        LockInfo[] storage lockInfos = walletLockTimestamp[wallet];
        for (uint256 i = 0; i < lockInfos.length; i++) {
            lockInfos[i].unlockAt = lockInfos[i].lockedAt + lockSeconds;
        }
        emit UpdateLockDuration(wallet, lockSeconds);
    }

    function transferAndLock(address to, uint256 value, uint256 lockSeconds) external onlyLockTransferAdmin {
        require(lockSeconds > 0, "Invalid lock duration");
        uint256 lockedAt = block.timestamp;
        uint256 unLockAt = lockedAt + lockSeconds;

        LockInfo[] storage infos = walletLockTimestamp[to];
        require(infos.length < 100, "Too many lock entries"); // Limit lock entries

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

    function canTransferAmount(address from, uint256 transferAmount) internal view returns (bool) {
        uint256 lockedAmount = calculateLockedAmount(from);
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

    function getLockAmountAndUnlockAt(address caller, uint16 index) public view returns (uint256, uint256) {
        require(index < walletLockTimestamp[caller].length, "Index out of range");
        LockInfo memory lockInfo = walletLockTimestamp[caller][index];
        return (lockInfo.lockedAmount, lockInfo.unlockAt);
    }

    function requestAddLockTransferAdmin(address addr) external pure returns (bytes memory) {
        bytes memory data = abi.encodeWithSignature("addLockTransferAdmin(address)",addr);
        return data;
    }

    function requestRemoveLockTransferAdmin(address addr) external pure returns (bytes memory)  {
        bytes memory data = abi.encodeWithSignature("removeLockTransferAdmin(address)",addr);
        return data;
    }

    function addLockTransferAdmin(address addr) external onlyMultiSigTimeLockContract {
        lockTransferAdmins[addr] = true;
    }

    function removeLockTransferAdmin(address addr) external onlyMultiSigTimeLockContract {
        lockTransferAdmins[addr] = false;
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}
