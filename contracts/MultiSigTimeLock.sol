// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MultiSigTimeLock is Initializable, UUPSUpgradeable {
    struct Proposal {
        address target;
        bytes data;
        uint256 value;
        uint256 canExecuteAfterTimestamp;
        bool executed;
    }

    address[] public signers;
    uint256 public requiredApproveCount;
    uint256 public minDelaySeconds;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public approvals;
    uint256 public proposalCount;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed target,
        uint256 value,
        uint256 canExecuteAfterTimestamp
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalApproved(uint256 indexed proposalId, address indexed signer);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequiredSignaturesUpdated(uint256 newRequiredSignatures);
    event MinDelayUpdated(uint256 newMinDelaySeconds);

    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    function initialize(
        address[] memory _signers,
        uint256 _requiredApproveCount,
        uint256 _minDelaySeconds
    ) public initializer {
        require(_signers.length >= _requiredApproveCount, "Signers < required");
        require(_requiredApproveCount > 0, "Required signatures must be > 0");

        signers = _signers;
        requiredApproveCount = _requiredApproveCount;
        minDelaySeconds = _minDelaySeconds;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlySigner {}

    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        address target,
        bytes memory data
    ) external onlySigner {
        uint256 _canExecuteAfterTimestamp = block.timestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: target,
            data: data,
            value: 0,
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false
        });

        emit ProposalCreated(proposalCount, target, 0, _canExecuteAfterTimestamp);
        approvals[proposalCount][msg.sender] = true;
        emit ProposalApproved(proposalCount, msg.sender);
        proposalCount++;
    }

    function approveProposal(uint256 proposalId) external onlySigner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposals[proposalId].target != address(0), "Invalid proposal");
        require(!approvals[proposalId][msg.sender], "Already approved");

        approvals[proposalId][msg.sender] = true;
        emit ProposalApproved(proposalId, msg.sender);
    }

    function revokeApproveProposal(uint256 proposalId) external onlySigner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposals[proposalId].target != address(0), "Invalid proposal");
        require(approvals[proposalId][msg.sender], "Not approved yet");

        approvals[proposalId][msg.sender] = false;
        emit ProposalApproved(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.canExecuteAfterTimestamp, "Delay not passed");
        require(!proposal.executed, "Proposal already executed");

        uint256 approvalCount = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            if (approvals[proposalId][signers[i]]) {
                approvalCount++;
            }
        }
        require(approvalCount >= requiredApproveCount, "Insufficient approvals");

        proposal.executed = true;

        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);
        require(success, "Execution failed");

        emit ProposalExecuted(proposalId);
    }

    function addSigner(address newSigner) external onlySigner {
        require(newSigner != address(0), "Invalid signer address");
        require(!isSigner(newSigner), "Already a signer");

        signers.push(newSigner);
        emit SignerAdded(newSigner);
    }

    function removeSigner(address signer) external onlySigner {
        require(isSigner(signer), "Not a signer");
        require(signers.length > requiredApproveCount, "Signers < required approve count");

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                emit SignerRemoved(signer);
                return;
            }
        }
    }

    function updateRequiredApproveCount(uint256 newApprovedCount) external onlySigner {
        require(newApprovedCount > 0, "Must have at least one");
        require(newApprovedCount <= signers.length, "Too many required approve count");
        requiredApproveCount = newApprovedCount;
        emit RequiredSignaturesUpdated(newApprovedCount);
    }

    function updateMinDelaySeconds(uint256 newMinDelaySeconds) external onlySigner {
        minDelaySeconds = newMinDelaySeconds;
        emit MinDelayUpdated(newMinDelaySeconds);
    }

    function getProposal(uint256 proposalId)
    external
    view
    returns (
        address target,
        bytes memory data,
        uint256 value,
        uint256 executeAfter,
        bool executed
    )
    {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.target, proposal.data, proposal.value, proposal.canExecuteAfterTimestamp, proposal.executed);
    }

    function getApprovalStatus(uint256 proposalId, address signer) external view returns (bool) {
        return approvals[proposalId][signer];
    }

    function version() external pure returns (int256)  {
        return 1;
    }
}
