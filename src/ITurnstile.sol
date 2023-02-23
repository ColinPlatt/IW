// turnstile address: 0xEcf044C5B4b867CFda001101c617eCd347095B44

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITurnstile {

    function register(address) external returns(uint256);

    function assign(uint256) external returns(uint256);

}