// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  event Stake(address indexed addr, uint256 amount);


  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
      require(msg.value > 0, "Insufficient Ether provided");

      balances[msg.sender] = balances[msg.sender] + msg.value;
      emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() external {
      require(block.timestamp > deadline, "Deadline not yet met");
      if (block.timestamp > deadline) {
          uint256 contractBalance = address(this).balance;
          if (contractBalance >= threshold) {
            // if the `threshold` is met, send the balance to the externalContract
            exampleExternalContract.complete{value: contractBalance}();
          } else {
            // if the `threshold` was not met, allow everyone to call a `withdraw()` function
            openForWithdraw = true;
          }
      }

      
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() external {
      require(openForWithdraw, "withdraw not yet opened");
      require(balances[msg.sender] > 0, "Your Balance is 0, nothing to withdraw");
      balances[msg.sender] = 0;

      // transfer sender's balance to the `_to` address
      (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");

      // check transfer was successful
      require(sent, "Withdrawal Operation failed");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
      if (block.timestamp >= deadline) {
          return 0;
      } else {
          return deadline - block.timestamp;
      }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
      stake();
  }

}
