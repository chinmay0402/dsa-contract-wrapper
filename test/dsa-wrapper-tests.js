const { expect, should } = require("chai");
require('hardhat');
const DSA = require('dsa-connect');
const { parseEther, parseUnits } = require("ethers/lib/utils");
require("@nomiclabs/hardhat-web3");
const dsaContractAbi = require("./ABIs/dsaContractAbi.js");
const daiAbi = require("./ABIs/daiAbi.js");

describe("DSA Wrapper Contract", function () {
  let owner, addr1, addr2;
  let dsaWrapper, dai;
  let dsa, dsaId, dsaAddress;
  const address = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
  const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';

  dsa = new DSA({
    web3: web3,
    mode: "node",
    privateKey: process.env.PRIVATE_KEY
  });

  before(async () => {
    await dsa.build({
      gasPrice: web3.utils.toWei('1000000', 'gwei'), // gas estimate, necessary when using NodeJs for calls
      authority: address, // the address to be added as authority for the account
      version: 2
    });

    const accounts = await dsa.getAccounts(address);
    console.log(accounts)
    dsaAddress = accounts[0].address;

    dsaContract = new ethers.Contract(dsaAddress, dsaContractAbi, ethers.provider);

    dsaId = accounts[0].id;

    const dsaWrapperFactory = await ethers.getContractFactory("DsaWrapper");
    [owner, addr1, addr2] = await ethers.getSigners();
    dsaWrapper = await dsaWrapperFactory.deploy();

    await dsa.setInstance(dsaId);

    let spells = dsa.Spell();
    spells.add({
      connector: "AUTHORITY-A",
      method: "add",
      args: [dsaWrapper.address]
    });
    const transactionHash = await spells.cast({
      gasPrice: web3.utils.toWei('1000000', 'gwei'), // in gwei, used in node implementation.
    });

    // instantiate Dai Token
    dai = new ethers.Contract(daiAddress, daiAbi, ethers.provider);
    await dai.connect(owner).approve(dsaWrapper.address, parseUnits('1', 18));
  });

  describe('Deployment', async () => {
    it('Sets the correct owner', async () => {
      await expect(await dsaWrapper.getOwner()).to.equal(owner.address);
    });
  });

  describe('Authority', async () => {
    it('should return correct account authority', async () => {
      await expect(await dsaWrapper.getAuthority(dsaId)).to.have.all.members([owner.address, dsaWrapper.address]);
    });
  });

  describe('Deposit Ether', async () => {
    it('Should deposit Ether to DSA and update balances', async () => {
      await expect(await dsaWrapper.depositEther(dsaId, {
        value: parseEther('1')
      }))
        .to.changeEtherBalances([owner, dsaContract], [parseEther('-1'), parseEther('1')]);
    });
  });

  describe('Withdraw Ether', async () => {
    it('Should withdraw Ether from DSA and update balances (1)', async () => {
      await expect(await dsaWrapper.withdrawEther(dsaId, parseEther('0.6')))
        .to.changeEtherBalances([owner, dsaContract], [parseEther('0.6'), parseEther('-0.6')]);
    });

    it('Should fail on trying to borrow more Ether than balance', async () => {
      await expect(dsaWrapper.withdrawEther(dsaId, parseEther('0.5')))
        .to.be.revertedWith("INSUFFICIENT FUNDS");
    });

    it('Should withdraw Ether from DSA and update balances (2)', async () => {
      await expect(await dsaWrapper.withdrawEther(dsaId, parseEther('0.4')))
        .to.changeEtherBalances([owner, dsaContract], [parseEther('0.4'), parseEther('-0.4')]);
    });
  });

  describe('Deposit ERC20', async () => {
    it('Should deposit ERC20 to DSA and update balances', async () => {
      await expect(() => dsaWrapper.depositErc20(dsaId, parseUnits('1', 18), daiAddress))
        .to.changeTokenBalances(dai, [owner, dsaContract], [parseUnits('-1', 18), parseUnits('1', 18)]);
    });
  });

  describe('Withdraw ERC20', async () => {
    it('Should withdraw ERC20 from DSA and update balances', async () => {
      await expect(() => dsaWrapper.withdrawErc20(dsaId, parseUnits('0.4', 18), daiAddress))
        .to.changeTokenBalances(dai, [owner, dsaContract], [parseUnits('0.4', 18), parseUnits('-0.4', 18)]);
    });
    it('Should fail on trying to withdraw more than token balance', async () => {
      await expect(dsaWrapper.withdrawErc20(dsaId, parseUnits('0.9', 18), daiAddress))
        .to.be.revertedWith("INSUFFICIENT TOKEN BALANCE");
    });
  });

  describe('Authority', async () => {
    it('Should add authority', async () => {
      await dsaWrapper.addAuthority(dsaId, addr1.address);
      await expect(await dsaWrapper.getAuthority(dsaId)).to.have.all.members([owner.address, dsaWrapper.address, addr1.address]);
    });

    it('Should remove authority', async () => {
      // to confirm if addr1 is still auth
      await expect(await dsaWrapper.getAuthority(dsaId)).to.have.all.members([owner.address, dsaWrapper.address, addr1.address]);

      // remove addr1 from auth
      await dsaWrapper.removeAuthority(dsaId, addr1.address);

      // check if remove was successful
      await expect(await dsaWrapper.getAuthority(dsaId)).to.have.all.members([owner.address, dsaWrapper.address]);
    });

    it('Should fail on attempting to modify authority with non-authority account', async () => {
      await expect(dsaWrapper.connect(addr2).addAuthority(dsaId, addr1.address))
        .to.be.revertedWith("PERMISSION DENIED: NO AUTHORITY");
    })
  });
});
