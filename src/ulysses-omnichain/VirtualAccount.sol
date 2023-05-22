// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {IVirtualAccount, Call} from "./interfaces/IVirtualAccount.sol";

import {IRootPort} from "./interfaces/IRootPort.sol";

/// @title `VirtualAccount`
contract VirtualAccount is IVirtualAccount {
    using SafeTransferLib for address;

    /// @inheritdoc IVirtualAccount
    address public immutable userAddress;

    /// @inheritdoc IVirtualAccount
    address public localPortAddress;

    constructor(address _userAddress, address _localPortAddress) {
        userAddress = _userAddress;
        localPortAddress = _localPortAddress;
    }

    /// @inheritdoc IVirtualAccount
    function withdrawERC20(address _token, uint256 _amount) external requiresApprovedCaller {
        _token.safeTransfer(msg.sender, _amount);
    }

    /// @inheritdoc IVirtualAccount
    function withdrawERC721(address _token, uint256 _tokenId) external requiresApprovedCaller {
        ERC721(_token).transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @inheritdoc IVirtualAccount
    function call(Call[] calldata calls)
        external
        requiresApprovedCaller
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory data) = calls[i].target.call(calls[i].callData);
            if (!success) revert CallFailed();
            returnData[i] = data;
        }
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Modifier that verifies msg sender is the RootInterface Contract from Root Chain.
    modifier requiresApprovedCaller() {
        if ((!IRootPort(localPortAddress).isRouterApproved(this, msg.sender)) && (msg.sender != userAddress)) {
            revert UnauthorizedCaller();
        }
        _;
    }
}