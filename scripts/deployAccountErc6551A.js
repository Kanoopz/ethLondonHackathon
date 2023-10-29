const hre = require("hardhat");
const {ethers} = require("hardhat");

async function main() 
{
   const scFactory = await ethers.getContractFactory("AccountERC6551");
   const scInstance = await scFactory.deploy();
   await scInstance.waitForDeployment();

   console.log("Contract deploy at address:", await scInstance.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});