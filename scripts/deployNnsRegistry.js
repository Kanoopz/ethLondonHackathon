const hre = require("hardhat");
const {ethers} = require("hardhat");

async function main() 
{
   const scFactory = await ethers.getContractFactory("nnsRegistry");
   //Implementation, Registry
   //"0xFa3024fA8C205a099525b8753A3D1BCeE83c3b75" "0x70d08A1F7AcC45b634046Ee2c14d3c8Ed778A00C"
   const scInstance = await scFactory.deploy("0xFa3024fA8C205a099525b8753A3D1BCeE83c3b75", "0x70d08A1F7AcC45b634046Ee2c14d3c8Ed778A00C");
   await scInstance.waitForDeployment();

   console.log("Contract deploy at address:", await scInstance.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});