/*******************************************************************************
*   (c) 2022 Zondax AG
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
********************************************************************************/
//
// DRAFT!! THIS CODE HAS NOT BEEN AUDITED - USE ONLY FOR PROTOTYPING
//
pragma solidity >=0.4.25 <=0.8.17;

import "./types/MinerTypes.sol";
import "./cbor/MinerCbor.sol";
import "./utils/Misc.sol";
import "./utils/Actor.sol";

/// @title This contract is a proxy to a built-in Miner actor. Calling one of its methods will result in a cross-actor call being performed.
/// @notice During miner initialization, a miner actor is created on the chain, and this actor gives the miner its ID f0.... The miner actor is in charge of collecting all the payments sent to the miner.
/// @dev For more info about the miner actor, please refer to https://lotus.filecoin.io/storage-providers/operate/addresses/
/// @author Zondax AG
contract MinerAPI {
    using ChangeBeneficiaryCBOR for MinerTypes.ChangeBeneficiaryParams;
    using GetOwnerCBOR for MinerTypes.GetOwnerReturn;
    using AddressCBOR for bytes;
    using IsControllingAddressCBOR for MinerTypes.IsControllingAddressReturn;
    using GetSectorSizeCBOR for MinerTypes.GetSectorSizeReturn;
    using GetAvailableBalanceCBOR for MinerTypes.GetAvailableBalanceReturn;
    using GetVestingFundsCBOR for MinerTypes.GetVestingFundsReturn;
    using GetBeneficiaryCBOR for MinerTypes.GetBeneficiaryReturn;
    using ChangeWorkerAddressCBOR for MinerTypes.ChangeWorkerAddressParams;
    using ChangePeerIDCBOR for MinerTypes.ChangePeerIDParams;
    using ChangeMultiaddrsCBOR for MinerTypes.ChangeMultiaddrsParams;
    using GetPeerIDCBOR for MinerTypes.GetPeerIDReturn;
    using GetMultiaddrsCBOR for MinerTypes.GetMultiaddrsReturn;

    /// @notice Income and returned collateral are paid to this address
    /// @notice This address is also allowed to change the worker address for the miner
    /// @param target The miner address (type ID) you want to interact with
    /// @return the owner address of a Miner
    function get_owner(bytes memory target) public returns (MinerTypes.GetOwnerReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetOwnerMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetOwnerReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @param addr New owner address
    /// @notice Proposes or confirms a change of owner address.
    /// @notice If invoked by the current owner, proposes a new owner address for confirmation. If the proposed address is the current owner address, revokes any existing proposal that proposed address.
    function change_owner_address(bytes memory target, bytes memory addr) public {
        bytes memory raw_request = addr.serializeAddress();

        bytes memory raw_response = Actor.call(MinerTypes.ChangeOwnerAddressMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @param addr The "controlling" addresses are the Owner, the Worker, and all Control Addresses.
    /// @return Whether the provided address is "controlling".
    function is_controlling_address(
        bytes memory target,
        bytes memory addr
    ) public returns (MinerTypes.IsControllingAddressReturn memory) {
        bytes memory raw_request = addr.serializeAddress();

        bytes memory raw_response = Actor.call(MinerTypes.IsControllingAddressMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.IsControllingAddressReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @return the miner's sector size.
    /// @param target The miner address (type ID) you want to interact with
    /// @dev For more information about sector sizes, please refer to https://spec.filecoin.io/systems/filecoin_mining/sector/#section-systems.filecoin_mining.sector
    function get_sector_size(bytes memory target) public returns (MinerTypes.GetSectorSizeReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetSectorSizeMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetSectorSizeReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @notice This is calculated as actor balance - (vesting funds + pre-commit deposit + initial pledge requirement + fee debt)
    /// @notice Can go negative if the miner is in IP debt.
    /// @return the available balance of this miner.
    function get_available_balance(bytes memory target) public returns (MinerTypes.GetAvailableBalanceReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetAvailableBalanceMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetAvailableBalanceReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @return the funds vesting in this miner as a list of (vesting_epoch, vesting_amount) tuples.
    function get_vesting_funds(bytes memory target) public returns (MinerTypes.GetVestingFundsReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetVestingFundsMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetVestingFundsReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @notice Proposes or confirms a change of beneficiary address.
    /// @notice A proposal must be submitted by the owner, and takes effect after approval of both the proposed beneficiary and current beneficiary, if applicable, any current beneficiary that has time and quota remaining.
    /// @notice See FIP-0029, https://github.com/filecoin-project/FIPs/blob/master/FIPS/fip-0029.md
    function change_beneficiary(bytes memory target, MinerTypes.ChangeBeneficiaryParams memory params) public {
        bytes memory raw_request = params.serialize();

        bytes memory raw_response = Actor.call(MinerTypes.ChangeBeneficiaryMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @param target The miner address (type ID) you want to interact with
    /// @notice This method is for use by other actors (such as those acting as beneficiaries), and to abstract the state representation for clients.
    /// @notice Retrieves the currently active and proposed beneficiary information.
    function get_beneficiary(bytes memory target) public returns (MinerTypes.GetBeneficiaryReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetBeneficiaryMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetBeneficiaryReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function change_worker_address(bytes memory target, MinerTypes.ChangeWorkerAddressParams memory params) public {
        bytes memory raw_request = params.serialize();

        bytes memory raw_response = Actor.call(MinerTypes.ChangeWorkerAddressMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function change_peer_id(bytes memory target, MinerTypes.ChangePeerIDParams memory params) public {
        bytes memory raw_request = params.serialize();

        bytes memory raw_response = Actor.call(MinerTypes.ChangePeerIDMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function change_multiaddresses(bytes memory target, MinerTypes.ChangeMultiaddrsParams memory params) public {
        bytes memory raw_request = params.serialize();

        bytes memory raw_response = Actor.call(MinerTypes.ChangeMultiaddrsMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function repay_debt(bytes memory target) public {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.RepayDebtMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function confirm_change_worker_address(bytes memory target) public {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.ConfirmChangeWorkerAddressMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        return;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function get_peer_id(bytes memory target) public returns (MinerTypes.GetPeerIDReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetPeerIDMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetPeerIDReturn memory response;
        response.deserialize(result);

        return response;
    }

    /// @notice FIXME
    /// @param target The miner address (type ID) you want to interact with
    function get_multiaddresses(bytes memory target) public returns (MinerTypes.GetMultiaddrsReturn memory) {
        bytes memory raw_request = new bytes(0);

        bytes memory raw_response = Actor.call(MinerTypes.GetMultiaddrsMethodNum, target, raw_request);

        bytes memory result = Actor.readRespData(raw_response);

        MinerTypes.GetMultiaddrsReturn memory response;
        response.deserialize(result);

        return response;
    }
}
