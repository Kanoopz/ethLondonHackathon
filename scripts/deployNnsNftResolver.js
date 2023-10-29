const hre = require("hardhat");
const {ethers} = require("hardhat");

async function main() 
{
   const scFactory = await ethers.getContractFactory("nnsNftResolver");
   const scInstance = await scFactory.deploy("something", "0xCF4F4f6e33638481C3Ae9537a7A919d6B7925c13");
   await scInstance.waitForDeployment();

   console.log("Contract deploy at address:", await scInstance.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});