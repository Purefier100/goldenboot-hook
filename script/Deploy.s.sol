// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {GoldenBootHook} from "../src/GoldenBootHook.sol";

contract DeployGoldenBootHook is Script {
    // Uniswap V4 PoolManager on X Layer Mainnet
    // TODO: replace with official X Layer V4 PoolManager address once confirmed
    address constant POOL_MANAGER = 0x0000000000000000000000000000000000000000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying GoldenBootHook...");
        console.log("Deployer:", deployer);
        console.log("PoolManager:", POOL_MANAGER);

        vm.startBroadcast(deployerPrivateKey);

        GoldenBootHook hook = new GoldenBootHook(
            IPoolManager(POOL_MANAGER)
        );

        console.log("GoldenBootHook deployed at:", address(hook));

        // Set up World Cup teams
        bytes32 brazil  = keccak256("Brazil");
        bytes32 england = keccak256("England");
        bytes32 france  = keccak256("France");
        bytes32 germany = keccak256("Germany");
        bytes32 spain   = keccak256("Spain");

        // Set all teams to Pending initially
        hook.setMatchResult(brazil,  GoldenBootHook.MatchResult.Pending);
        hook.setMatchResult(england, GoldenBootHook.MatchResult.Pending);
        hook.setMatchResult(france,  GoldenBootHook.MatchResult.Pending);
        hook.setMatchResult(germany, GoldenBootHook.MatchResult.Pending);
        hook.setMatchResult(spain,   GoldenBootHook.MatchResult.Pending);

        console.log("Teams initialized:");
        console.log("  Brazil  :", vm.toString(brazil));
        console.log("  England :", vm.toString(england));
        console.log("  France  :", vm.toString(france));
        console.log("  Germany :", vm.toString(germany));
        console.log("  Spain   :", vm.toString(spain));

        vm.stopBroadcast();

        console.log("Deployment complete!");
        console.log("Next steps:");
        console.log("  1. Call setPoolTeam(poolId, teamId) to link pools to teams");
        console.log("  2. Call setMatchResult(teamId, result) after each match");
    }
}
