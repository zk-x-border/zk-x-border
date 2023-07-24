# ZK X Border (By Team Eastern Union)
Trustless and 0 fee international remittance using ZK proofs, Uniswap V3, Revolut and Venmo

![vince_zk_x_border](https://github.com/zk-x-border/zk-x-border/assets/73331595/400b4229-9b84-4526-92df-a0422e642da3)

## Demo 

https://zk-x-border-ui.vercel.app

## ETHGlobal Submission

https://ethglobal.com/showcase/zk-x-border-15qvk

## Problem
- Cross border remittance fees are too high (e.g. Paypal) or slow (TransferWise)
- DeFi already offers better rates than TradFi cross border payment solutions for certain forex pairs (e.g. USDC/agEUR on Uniswap/Curve price is up to 1% better for up to $10k swaps)
- Despite these better rates, there's a huge UX barrier to using crypto wallets (e.g. installing Metamask) and on / offramping stablecoins such as USDC or EUROC on Centralized Exchanges (e.g. KYCing for Coinbase)
- Therefore, **non crypto native users** (who are Venmo and Revolut users) **aren't able to take advantage of better rates**
<img width="500" alt="Screenshot 2023-07-20 at 11 10 35 PM" src="https://github.com/zk-x-border/.github/assets/6797244/350b0130-c206-4f1a-ba21-25288058f9db">
<img width="500" alt="Screenshot 2023-07-20 at 11 10 52 PM" src="https://github.com/zk-x-border/.github/assets/6797244/2bccf3c4-6d84-43e7-ac23-b259bff3176f">

## Solution
- We have built a trustless, 0 fee and globally accessible cross platform payment system that utilizes ZK proofs of email DKIM signatures. Venmo and Revolut both send proof of payment emails that can be verified using [ZK Email](https://github.com/zkemail/zk-email-verify). 
- The solution is cross platform (Venmo to Revolut) which allows much better rates than using TradFi
- Use ZK proofs to prove emails from Venmo for free domestic USD payments and from Revolut for free domestic EUR payments
- The system uses coincidence-of-wants to match all user intents in the system and keep net currency flow 0 across countries. This means USD stays in US, and EUR stays in Europe
- Take advantage of superior and permissionless forex liquidity in DeFi using USDC EUR stablecoins in Uniswap or Curve
- The sender and receiver don’t need to be on-chain to complete the flow, similar to your favorite Web2 apps
- No need to install crypto wallets (e.g. Metamask)

## Flow
There are 4 actors in the system:
- USD payer who wants to send a x border payment to EUR receiver
- EUR receiver who receives a payment from USD payer
- USD offramper who wants to offramp USDC into USD in Venmo and matches with USD payer
- EUR onramper who wants to onramp EUR in Revolut into agEUR and matches and send funds to EUR receiver to complete x-border payment

There are 2 ZKPs that need to be generated in order to complete 1 x-border transfer:
- Proof of Venmo payment from USD payer to USD offramper
- Proof of Revolut payment from EUR onramper to EUR receiver


![zkp2p X-border (3)](https://github.com/zk-x-border/.github/assets/73331595/5f9bc293-28d5-461d-9b5f-59af9bab23c5)

### Deployed contracts

- USDC
Network: Polygon  
Address: [0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174](https://polygonscan.com/address/0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)  

- EuroToken
Network: Polygon  
Address: [0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4](https://polygonscan.com/address/0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4)  

- Uniswap Router
Network: Polygon  
Address: [0xE592427A0AEce92De3Edee1F18E0157C05861564](https://polygonscan.com/address/0xE592427A0AEce92De3Edee1F18E0157C05861564)  

- EuroPool
Network: Polygon  
Address: [0xfbb2ae302a460730685f74f262d1e3256033d625](https://polygonscan.com/address/0xfbb2ae302a460730685f74f262d1e3256033d625)  

- USDCPool
Network: Polygon  
Address: [0x18c54cfb3bc9480e9dab7feb5d319e6460d40627](https://polygonscan.com/address/0x18c54cfb3bc9480e9dab7feb5d319e6460d40627)  





