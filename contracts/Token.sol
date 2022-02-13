//
// ███████╗ ██████╗███╗   ███╗
// ██╔════╝██╔════╝████╗ ████║
// ███████╗██║     ██╔████╔██║
// ╚════██║██║     ██║╚██╔╝██║
// ███████║╚██████╗██║ ╚═╝ ██║
// ╚══════╝ ╚═════╝╚═╝     ╚═╝

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SCM is ERC20("ShibaScam", "SCM"), Ownable {
    address private vestingAddress;

    function setVestingAddress(address _vestingAddress) public onlyOwner {
        vestingAddress = _vestingAddress;
    }

    //Distribution scenarios can vary, so I'm picking simplest way
    function preMint(uint256 amount) public onlyOwner {
        require(vestingAddress != address(0x0), "Vesting address must be set");
        _mint(vestingAddress, amount);
    }

    //let's keep mint function so we can mint more scam tokent for ourselves :D
    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
}
