// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {KipuBank} from "../../src/KipuBank.sol";

contract KipuBankTest is Test {
    //Instances
    KipuBank bank;

    //Variables ~ Users
    address Barba = makeAddr("Barba");
    address student1 = makeAddr("student1");
    address student2 = makeAddr("student2");

    //Variables ~ Utils
    uint256 constant BANK_CAP = 10 ether;
    uint256 constant INITIAL_BALANCE = 100 ether;

    function setUp() public {
        bank = new KipuBank(BANK_CAP);

        vm.deal(Barba, INITIAL_BALANCE);
        vm.deal(student1, INITIAL_BALANCE);
        vm.deal(student2, INITIAL_BALANCE);
    }

    modifier processDeposit(){
        vm.prank(Barba);
        bank.deposit{value: 1 ether}();
        _;
    }

    error BankCapIsFull();
    function test_depositFailsBecauseOfCap() public {
        vm.prank(Barba);
        vm.expectRevert(abi.encodeWithSelector(BankCapIsFull.selector));
        bank.deposit{value: 11 ether}();
    }

    event Deposit(address indexed account, uint256 amount);
    function test_depositSucced() public {
        vm.prank(student1);
        vm.expectEmit();
        emit Deposit(student1, 1 ether);
        bank.deposit{value: 1 ether}();
    }

    event Withdraw(address indexed account, uint256 amount);
    function test_withdrawSucced() public processDeposit {
        vm.prank(Barba);
        vm.expectEmit();
        emit Withdraw(Barba, 1 ether);
        bank.withdraw(1 ether);
        assertEq(bank.getContractBalance(), 0);
        assertEq(Barba.balance, 100 ether);
    }
    
    error InsufficientFunds();
    function test_withdrawFailsBecauseOfInsufficientFunds() public processDeposit {
        vm.prank(Barba);
        vm.expectRevert(abi.encodeWithSelector(InsufficientFunds.selector));
        bank.withdraw(1 ether + 1 wei);
        assertEq(bank.getContractBalance(), 1 ether);
        assertEq(Barba.balance, 99 ether);
    }


}