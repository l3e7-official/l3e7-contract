// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Utils {

    function getKey(address _value1, address _value2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_value1, _value2));
    }

    function getKey(uint _value1, uint _value2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_value1, _value2));
    }

    function getKey(address _value1, uint _value2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_value1, _value2));
    }

    function getKey(bytes32 _value1, bytes32 _value2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_value1, _value2));
    }

    function getToday(uint _timestamp) internal pure returns (uint) {
        return (_timestamp + 8 hours) / 24 hours * 24 hours - 8 hours;
    }

    function getToday(uint _timestamp, uint _timeDiff) internal pure returns (uint) {
        return (_timestamp + _timeDiff * 1 hours) / 24 hours * 24 hours - _timeDiff * 1 hours;
    }

    function getMonday(uint _timestamp) internal pure returns (uint) {
        return (_timestamp + 3 days + 8 hours) / 7 days * 7 days - 3 days - 8 hours;
    }

    function isContain(uint _value, uint[] memory _values) internal pure returns (bool) {
        for (uint i = 0; i < _values.length; i++) {
            if (_value == _values[i]) return true;
        }
        return false;
    }

    function contains(uint[] memory _values, uint _value) internal pure returns (bool) {
        for (uint i = 0; i < _values.length; i++) {
            if (_value == _values[i]) return true;
        }
        return false;
    }

    function getValueById(uint _id, uint[][] memory _values) internal pure returns (uint) {
        for (uint i = 0; i < _values.length; i++) {
            if (_id == _values[i][0]) {
                return _values[i][1];
            }
        }
        revert("_id missmatch _values");
    }

}