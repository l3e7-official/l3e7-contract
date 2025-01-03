// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract BaseUUPSUpgradeable is UUPSUpgradeable {
    bool public isPaused;
    bool private locked;
    address public admin;
    // auth account
    mapping(address => bool) public auth;

    event SetAdmin(address newAdmin);
    event SetAuth(address account, bool authState);
    event SetIsPaused(bool isPaused);

    function __Base_init() internal initializer {
        admin = msg.sender;

        emit SetAdmin(admin);
    }

    modifier lock() {
        require(!locked, 'lock: !locked');
        locked = true;
        _;
        locked = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "onlyAdmin");
        _;
    }

    modifier onlyAuth() {
        require(auth[msg.sender], "onlyAuth");
        _;
    }

    modifier onlyExternal() {
        address account = msg.sender;
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        require((0 == size && tx.origin == msg.sender) || auth[msg.sender], "onlyExternal");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "notPaused");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;

        emit SetAdmin(_admin);
    }

    function setAuth(address _account, bool _authState) external onlyAdmin {
        require(auth[_account] != _authState, "setAuth: auth[_account] != _authState");
        auth[_account] = _authState;

        emit SetAuth(_account, _authState);
    }

    function setIsPaused(bool _isPaused) external onlyAdmin {
        require(isPaused != _isPaused, "setIsPaused: isPaused != _isPaused");
        isPaused = _isPaused;

        emit SetIsPaused(_isPaused);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyAdmin {
        require(newImplementation != address(0), "Invalid implementation address");
    }
}
