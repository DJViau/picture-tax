// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {PictureTax, Child} from "../src/PictureTax.sol";

contract PictureTaxTest is Test {
    PictureTax public pictureTax;

    function setUp() public {
        pictureTax = new PictureTax();
    }

    function test_constructor() public {
        (address eldestAddr,) = pictureTax.eldest();
        assertEq(eldestAddr, address(0x011));

        (address middleAddr,) = pictureTax.middle();
        assertEq(middleAddr, address(0x022));

        (address youngestAddr,) = pictureTax.youngest();
        assertEq(youngestAddr, address(0x033));

        assertEq(pictureTax.admin(), address(this));
        assertEq(pictureTax.incrementSize(), 0.001 ether);
    }

    function test_topUp() public {
        pictureTax.topUp{value: 1 ether}();
        assertEq(address(pictureTax).balance, 1 ether);
    }

    function test_setIncrementSize() public {
        pictureTax.setIncrementSize(0.002 ether);
        assertEq(pictureTax.incrementSize(), 0.002 ether);
    }

    function test_changeChildAddress() public {
        pictureTax.changeChildAddress(PictureTax.Children.Eldest, address(0x04));
        (address eldestAddr,) = pictureTax.eldest();
        assertEq(eldestAddr, address(0x04));
    }

    function test_allocateBalance() public {
        pictureTax.topUp{value: 1 ether}();
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        (, uint256 eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0.001 ether);
        assertEq(address(pictureTax).balance, 1 ether);
        assertEq(pictureTax.getFreeBalance(), 0.999 ether);

        pictureTax.allocateBalance(PictureTax.Children.Middle);
        (, uint256 middleBalance) = pictureTax.middle();
        assertEq(middleBalance, 0.001 ether);
        assertEq(address(pictureTax).balance, 1 ether);
        assertEq(pictureTax.getFreeBalance(), 0.998 ether);

        pictureTax.allocateBalance(PictureTax.Children.Youngest);
        (, uint256 youngestBalance) = pictureTax.youngest();
        assertEq(youngestBalance, 0.001 ether);
        assertEq(address(pictureTax).balance, 1 ether);
        assertEq(pictureTax.getFreeBalance(), 0.997 ether);
    }

    function test_allocateBalance_notEnoughBalance() public {
        vm.expectRevert("Not enough balance!");
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        (, uint256 eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
    }

    function test_allocateBalance_notEnoughBalance2() public {
        pictureTax.topUp{value: 0.0005 ether}();
        vm.expectRevert("Not enough balance!");
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        (, uint256 eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
    }

    function test_unauthorizedWithdrawal() public {
        vm.expectRevert("You're not one of the children!");
        pictureTax.withdrawBalance();
    }

    function test_unauthorizedWithdrawalAdmin() public {
        vm.prank(address(0x011));
        vm.expectRevert("Only the admin can call this function!");
        pictureTax.adminWithdrawBalance();
    }

    function test_unauthorizedSetIncrementSize() public {
        vm.prank(address(0x011));
        vm.expectRevert("Only the admin can call this function!");
        pictureTax.setIncrementSize(0.002 ether);
    }

    function test_unauthorizedChangeChildAddress() public {
        vm.prank(address(0x011));
        vm.expectRevert("Only the admin can call this function!");
        pictureTax.changeChildAddress(PictureTax.Children.Eldest, address(0x04));
    }

    function test_withdrawBalanceTooEarly() public {
        pictureTax.topUp{value: 1 ether}();
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        pictureTax.allocateBalance(PictureTax.Children.Middle);
        pictureTax.allocateBalance(PictureTax.Children.Youngest);

        vm.prank(address(0x011));
        vm.expectRevert("Not yet!");
        pictureTax.withdrawBalance();
        assertEq(address(pictureTax).balance, 1 ether);

        vm.warp(2208988800);

        vm.prank(address(0x011));
        vm.expectRevert("Not yet!");
        pictureTax.withdrawBalance();
        assertEq(address(pictureTax).balance, 1 ether);
    }

    function test_withdrawBalance() public {
        pictureTax.topUp{value: 1 ether}();
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        pictureTax.allocateBalance(PictureTax.Children.Middle);
        pictureTax.allocateBalance(PictureTax.Children.Youngest);

        vm.warp(2208988801);

        vm.prank(address(0x011));
        pictureTax.withdrawBalance();
        assertEq(address(pictureTax).balance, 1 ether - pictureTax.incrementSize());
        (address eldestAddr, uint256 eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
        assertEq(address(0x011).balance, pictureTax.incrementSize());
        (address middleAddr, uint256 middleBalance) = pictureTax.middle();
        assertEq(middleBalance, pictureTax.incrementSize());
        (address youngestAddr, uint256 youngestBalance) = pictureTax.youngest();
        assertEq(youngestBalance, pictureTax.incrementSize());

        vm.prank(address(0x022));
        pictureTax.withdrawBalance();
        assertEq(address(pictureTax).balance, 1 ether - pictureTax.incrementSize() * 2);
        (eldestAddr, eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
        (middleAddr, middleBalance) = pictureTax.middle();
        assertEq(middleBalance, 0);
        assertEq(address(0x022).balance, pictureTax.incrementSize());
        (youngestAddr, youngestBalance) = pictureTax.youngest();
        assertEq(youngestBalance, pictureTax.incrementSize());

        vm.prank(address(0x033));
        pictureTax.withdrawBalance();
        assertEq(address(pictureTax).balance, 1 ether - pictureTax.incrementSize() * 3);
        (eldestAddr, eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
        (middleAddr, middleBalance) = pictureTax.middle();
        assertEq(middleBalance, 0);
        (youngestAddr, youngestBalance) = pictureTax.youngest();
        assertEq(youngestBalance, 0);
        assertEq(address(0x033).balance, pictureTax.incrementSize());

        vm.prank(address(0x033));
        vm.expectRevert("No balance to withdraw!");
        pictureTax.withdrawBalance();

        vm.prank(address(0x022));
        vm.expectRevert("No balance to withdraw!");
        pictureTax.withdrawBalance();

        vm.prank(address(0x011));
        vm.expectRevert("No balance to withdraw!");
        pictureTax.withdrawBalance();

        // Test that it still works after the first withdrawal.
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        pictureTax.allocateBalance(PictureTax.Children.Middle);
        pictureTax.allocateBalance(PictureTax.Children.Youngest);

        vm.prank(address(0x011));
        pictureTax.withdrawBalance();
        (eldestAddr, eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
        assertEq(address(0x011).balance, pictureTax.incrementSize() * 2);

        vm.prank(address(0x022));
        pictureTax.withdrawBalance();
        (middleAddr, middleBalance) = pictureTax.middle();
        assertEq(middleBalance, 0);
        assertEq(address(0x022).balance, pictureTax.incrementSize() * 2);

        vm.prank(address(0x033));
        pictureTax.withdrawBalance();
        assertEq(youngestBalance, 0);
        assertEq(address(0x033).balance, pictureTax.incrementSize() * 2);

        // Test that it works after changing addresses.
        pictureTax.changeChildAddress(PictureTax.Children.Eldest, address(0x044));
        pictureTax.changeChildAddress(PictureTax.Children.Middle, address(0x055));
        pictureTax.changeChildAddress(PictureTax.Children.Youngest, address(0x066));

        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        pictureTax.allocateBalance(PictureTax.Children.Middle);
        pictureTax.allocateBalance(PictureTax.Children.Youngest);

        vm.prank(address(0x044));
        pictureTax.withdrawBalance();
        (eldestAddr, eldestBalance) = pictureTax.eldest();
        assertEq(eldestBalance, 0);
        assertEq(address(0x044).balance, pictureTax.incrementSize());

        vm.prank(address(0x055));
        pictureTax.withdrawBalance();
        (middleAddr, middleBalance) = pictureTax.middle();
        assertEq(middleBalance, 0);
        assertEq(address(0x055).balance, pictureTax.incrementSize());

        vm.prank(address(0x066));
        pictureTax.withdrawBalance();
        assertEq(youngestBalance, 0);
        assertEq(address(0x066).balance, pictureTax.incrementSize());
    }

    function test_adminWithdrawBalance() public {
        pictureTax.topUp{value: 1 ether}();
        pictureTax.allocateBalance(PictureTax.Children.Eldest);
        pictureTax.allocateBalance(PictureTax.Children.Middle);
        pictureTax.allocateBalance(PictureTax.Children.Youngest);

        uint256 thisBalance = address(this).balance;

        pictureTax.adminWithdrawBalance();

        assertEq(address(this).balance, thisBalance + 1 ether);
        assertEq(address(pictureTax).balance, 0);
    }

    // Create a payable fallback function so that we can send ether to the contract.
    receive() external payable {}
}
