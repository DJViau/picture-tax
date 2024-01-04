// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Child {
    address addr;
    uint256 balance;
}

contract PictureTax {
    enum Children {
        Eldest,
        Middle,
        Youngest
    }

    Child public eldest;
    Child public middle;
    Child public youngest;

    address public admin;

    uint256 public incrementSize = 0.001 ether;

    constructor() {
        eldest.addr = address(0x011);
        middle.addr = address(0x022);
        youngest.addr = address(0x033);

        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function!");
        _;
    }

    function topUp() public payable {}

    function setIncrementSize(uint256 _incrementSize) public onlyAdmin {
        incrementSize = _incrementSize;
    }

    function changeChildAddress(Children child, address newAddress) public onlyAdmin {
        if (child == Children.Eldest) {
            eldest.addr = newAddress;
        } else if (child == Children.Middle) {
            middle.addr = newAddress;
        } else if (child == Children.Youngest) {
            youngest.addr = newAddress;
        }
    }

    function allocateBalance(Children child) public {
        // Revert if the contract doesn't have enough balance.
        require(getFreeBalance() >= incrementSize, "Not enough balance!");

        // Allocate the balance to the child.
        if (child == Children.Eldest) {
            eldest.balance += incrementSize;
        } else if (child == Children.Middle) {
            middle.balance += incrementSize;
        } else if (child == Children.Youngest) {
            youngest.balance += incrementSize;
        }
    }

    function getFreeBalance() public view returns (uint256) {
        // Get the contract's balance, minus the balance already allocated.
        return address(this).balance - (eldest.balance + middle.balance + youngest.balance);
    }

    function withdrawBalance() public {
        // Withdraw the balance allocated to the child.
        if (msg.sender == eldest.addr) {
            require(eldest.balance > 0, "No balance to withdraw!");
            payable(msg.sender).transfer(eldest.balance);
            eldest.balance = 0;
        } else if (msg.sender == middle.addr) {
            require(middle.balance > 0, "No balance to withdraw!");
            payable(msg.sender).transfer(middle.balance);
            middle.balance = 0;
        } else if (msg.sender == youngest.addr) {
            require(youngest.balance > 0, "No balance to withdraw!");
            payable(msg.sender).transfer(youngest.balance);
            youngest.balance = 0;
        } else {
            revert("You're not one of the children!");
        }

        // Only permit withdrawal if it's later than 2040.
        require(block.timestamp > 2208988800, "Not yet!");
    }

    function adminWithdrawBalance() public onlyAdmin {
        // Withdraw the balance.
        payable(msg.sender).transfer(address(this).balance);
    }
}
