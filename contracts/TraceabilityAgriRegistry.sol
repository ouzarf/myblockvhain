// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Registre de traçabilité agricole - MVP SaaS
/// @notice Les données sensibles restent hors chaîne. La blockchain conserve les preuves,
/// les identifiants de lots et les responsabilités entre organisations.
contract TraceabilityAgriRegistry {
    enum Role { NONE, PRODUCER, PACKER, CARRIER, DISTRIBUTOR, AUDITOR, ADMIN }

    struct Participant {
        string organisation;
        string displayName;
        Role role;
        bool active;
    }

    struct Lot {
        string product;
        string origin;
        string metadataURI;
        address creator;
        address currentCustodian;
        uint64 createdAt;
        bool exists;
    }

    struct Operation {
        string operationType;
        string location;
        string evidenceURI;
        bytes32 evidenceHash;
        address actor;
        uint64 timestamp;
    }

    address public immutable owner;
    uint256 public lotCount;
    mapping(address => Participant) private participants;
    mapping(bytes32 => Lot) private lots;
    mapping(bytes32 => Operation[]) private operations;

    event ParticipantRegistered(address indexed account, string organisation, Role role);
    event ParticipantStatusChanged(address indexed account, bool active);
    event LotCreated(bytes32 indexed lotId, string product, string origin, address indexed creator);
    event OperationRecorded(bytes32 indexed lotId, string operationType, string location, address indexed actor, bytes32 evidenceHash);
    event ResponsibilityTransferred(bytes32 indexed lotId, address indexed from, address indexed to);

    modifier onlyOwner() { require(msg.sender == owner, "ONLY_OWNER"); _; }
    modifier activeParticipant() { require(participants[msg.sender].active, "NOT_ACTIVE_PARTICIPANT"); _; }

    constructor() {
        owner = msg.sender;
        participants[msg.sender] = Participant("Platform", "Administrator", Role.ADMIN, true);
        emit ParticipantRegistered(msg.sender, "Platform", Role.ADMIN);
    }

    function registerParticipant(address account, string calldata organisation, string calldata displayName, Role role) external onlyOwner {
        require(account != address(0), "ZERO_ACCOUNT");
        require(role != Role.NONE, "INVALID_ROLE");
        participants[account] = Participant(organisation, displayName, role, true);
        emit ParticipantRegistered(account, organisation, role);
    }

    function setParticipantStatus(address account, bool active) external onlyOwner {
        require(participants[account].role != Role.NONE, "UNKNOWN_PARTICIPANT");
        participants[account].active = active;
        emit ParticipantStatusChanged(account, active);
    }

    function getParticipant(address account) external view returns (Participant memory) {
        return participants[account];
    }

    function createLot(bytes32 lotId, string calldata product, string calldata origin, string calldata metadataURI) external activeParticipant {
        require(!lots[lotId].exists, "LOT_EXISTS");
        lots[lotId] = Lot(product, origin, metadataURI, msg.sender, msg.sender, uint64(block.timestamp), true);
        lotCount++;
        emit LotCreated(lotId, product, origin, msg.sender);
    }

    function recordOperation(bytes32 lotId, string calldata operationType, string calldata location, string calldata evidenceURI, bytes32 evidenceHash) external activeParticipant {
        require(lots[lotId].exists, "LOT_NOT_FOUND");
        require(msg.sender == lots[lotId].currentCustodian || participants[msg.sender].role == Role.ADMIN || participants[msg.sender].role == Role.AUDITOR, "NOT_RESPONSIBLE_ACTOR");
        operations[lotId].push(Operation(operationType, location, evidenceURI, evidenceHash, msg.sender, uint64(block.timestamp)));
        emit OperationRecorded(lotId, operationType, location, msg.sender, evidenceHash);
    }

    function transferResponsibility(bytes32 lotId, address nextCustodian) external activeParticipant {
        require(lots[lotId].exists, "LOT_NOT_FOUND");
        require(msg.sender == lots[lotId].currentCustodian || participants[msg.sender].role == Role.ADMIN, "NOT_CUSTODIAN");
        require(participants[nextCustodian].active, "NEXT_ACTOR_NOT_ACTIVE");
        address previous = lots[lotId].currentCustodian;
        lots[lotId].currentCustodian = nextCustodian;
        emit ResponsibilityTransferred(lotId, previous, nextCustodian);
    }

    function getLot(bytes32 lotId) external view returns (Lot memory) {
        require(lots[lotId].exists, "LOT_NOT_FOUND");
        return lots[lotId];
    }

    function getOperationCount(bytes32 lotId) external view returns (uint256) { return operations[lotId].length; }

    function getOperation(bytes32 lotId, uint256 index) external view returns (Operation memory) { return operations[lotId][index]; }
}
