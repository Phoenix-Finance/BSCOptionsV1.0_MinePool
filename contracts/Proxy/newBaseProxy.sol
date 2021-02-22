pragma solidity =0.5.16;
/**
 * @title  newBaseProxy Contract

 */
contract newBaseProxy {
    bytes32 private constant implementPositon = keccak256("org.Finnexus.implementation.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Finnexus.Owner.storage");
    constructor(address implementation_) public {
        // Creator of the contract is admin during initialization
        _setProxyOwner(msg.sender);
        _setImplementation(implementation_);
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function getImplementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    function setImplementation(address _newImplementation)public onlyProxyOwner{
        address currentImplementation = getImplementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = getImplementation().delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), sub(returndatasize, 0x40)) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = getImplementation().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
        /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner());
        _;
    }
}
