# STUDENT-QUESTIONS.md — Discussion questions (goes inside your submission zip)

Answer directly under each question. 150–300 words each — **reasoning over length**.

The sections follow the four planks of the bridge. There are no standard answers; these are the
real point of the lab.

---

## A. Custody — where the asset actually is (plank a)

**A1.** In Lab 1, `totalCollateral()` read the vault's own ERC-20 balance, and the chain could
prove the invariant. Here, `MockTBillCustodian.realHoldings()` is just a number that a permissioned
address can move. Write the equivalent of `totalCollateral() == totalSupply()` for *this* system.
What does it actually assert, and what does it no longer prove?

> Your answer:

Before redemptions, the balance-sheet analogue is `vault.reserveBalance() + custodian.realHoldings() == vault.totalClaimValue()`, assuming the custodian number is the portfolio's current net value in six-decimal USDC units. This compares cash plus reported securities with `totalSupply * NAV / 1e20`, rather than equating eighteen-decimal shares directly with six-decimal assets. A conservative solvency condition would require independently verified assets to be at least the liabilities, allowing for fees, haircuts and rounding.

Once tickets exist, liabilities need adjustment. Escrowed pending shares remain in total supply, but their payout is fixed at enqueue. Therefore use `assetsForShares(totalSupply - pendingShares) + pendingAssets + totalClaimable` for liabilities, with the names understood as values read from the token and queue. Assets comprise available vault cash, verified Treasury value and queue cash, counted once each. Adding pending payouts to unadjusted `totalClaimValue()` would count those shares twice; omitting settled claims would forget cash still owed after their shares are burned.

Even an equality of reported figures proves only arithmetic consistency. `recordPurchase()` can increase `realHoldings()` without moving cash, and the NAV is another supplied number. Ex2 demonstrates both gaps. The lab also does not automatically reconcile recorded sales when reserve cash returns. No equality proves that securities exist, are unencumbered, belong to the SPV or can be recovered by investors. Independent custody reconciliation, valuation and enforceable legal rights remain essential.

**A2.** The T-Bills are held by an SPV, a legal entity set up so the fund's assets are bankruptcy-
remote from the issuer. Explain in your own words why a *legal* structure is part of a *technical*
design. If the SPV's custodian goes bankrupt, what does the on-chain token entitle its holder to?

> Your answer:

An on-chain balance is neither a Treasury security nor a court-enforceable ownership title. Tokenholders need a legal counterparty against which their rights can be asserted, especially if the sponsor, investment manager or custody bank fails. An SPV can hold the securities separately from the issuer's operating assets and define beneficial interests, servicing duties and redemption priority. Bankruptcy remoteness reduces the chance that the issuer's general creditors can claim the portfolio. It requires effective documentation, segregation and governance; merely naming a contract “custodian” creates none of these protections.

If the custodian goes bankrupt, the outcome depends on whether the T-Bills are legally segregated client property, how they are registered, whether there are liens, and which insolvency and securities laws apply. A properly segregated position may ultimately be returned or transferred to a replacement custodian, but access can be delayed while administrators reconcile records. If assets are commingled, pledged or missing, investors may face a shortfall and claims in insolvency.

The token entitles its holder only to whatever rights the fund's governing documents and applicable law attach to it, such as a beneficial interest or a redemption claim against the SPV. It does not automatically create a direct claim against the US Treasury or the custody bank. The architecture must identify the legal owner, tokenholder rights, recognized ownership register and insolvency procedures. `MockTBillCustodian.realHoldings()` supplies testimony about value; it cannot establish property rights.

---

## B. Attestation — how the chain learns the truth (plank b)

**B1.** `attest()` is the only function that moves the NAV, and it is gated by `REPORTER_ROLE`.
Everything downstream — subscription pricing, redemption payouts, both invariants — believes that
number. Name the failure modes of a single trusted reporter, and one mechanism (technical,
financial, or legal) that mitigates each.

> Your answer:

`REPORTER_ROLE` authorizes calls to `attest()`; it does not verify truth. A stolen or bribed reporter key can publish invented NAVs, mispricing subscriptions and fixed-price redemption tickets. Independent signing authorities, a quorum, restricted key custody and rapid revocation reduce this concentration of power. Ex7 shows the financial consequence when the privileged reporter lies.

An honest reporter can make an operational mistake, such as submitting the wrong decimals, valuation date or portfolio. Explicit schemas, independent recalculation, change bounds and human review mitigate that failure. An honest report can also become stale after a reporter outage or vendor failure. Consumers should enforce observation timestamps and maximum age, check round completion, and suspend dealing or switch to a documented valuation process when fresh data is unavailable.

A timely, correctly formatted report may still repeat fraudulent custody statements or omit liabilities. Independent custodian reconciliation, external assurance, contractual liability and financial bonding address that source risk, although a bond cannot guarantee recovery if losses exceed its value. Monitoring and limits on cash outflows reduce damage while discrepancies are investigated.

There is also a concrete limitation in this repository: `MockPriceFeed.setPrice()` is public and unrestricted. A caller can bypass the role check by writing directly to the mock feed, so the question's “only function” premise describes the intended reporting route, not an enforced end-to-end boundary. A production feed must authenticate writers as well as validating what consumers read. Fresh timestamps and multiple signatures still cannot prove that the underlying securities exist.

**B2.** A production feed would check whether `updatedAt` is stale; this lab's mock does not. A
**frozen** NAV is a different attack from a **wrong** NAV. Describe how a stale-but-honest NAV can
be exploited by someone who knows the true value has moved.

> Your answer:

A stale NAV need not have been false when published. Suppose yesterday's valid NAV was $1.00 per share, but a market repricing or fund loss makes today's fair value $0.95. If the feed remains at $1.00, an informed investor can enqueue shares at the excessive price and shift the loss to holders who remain. Because this queue locks the payout at enqueue, correcting the NAV before settlement does not correct that ticket. If fair NAV instead rises to $1.05, the investor can subscribe at $1.00 and obtain too many shares, diluting existing holders.

This is adverse selection: the trader acts when the outdated price favors them, without needing to alter the report or compromise a key. Subscription and redemption cut-offs therefore matter as much as the reporting heartbeat.

The base mock returns the current block timestamp from `latestRoundData()` even when its answer has not changed. A freshness check against that timestamp would incorrectly treat an old valuation as fresh. A production feed must preserve the actual observation time, reject missing or future timestamps and incomplete rounds, and document permitted age.

I would queue orders for the next independently reconciled NAV at a published dealing cut-off, with clear cancellation and exceptional-market rules. Divergence checks, circuit breakers and exposure limits can supplement that policy. Treasury trading calendars may require more care than a fixed timeout. None of these measures establishes custody or makes an inaccurate fresh valuation truthful.

---

## C. Redemption — T+1 does not settle on-chain (plank c)

**C1.** The queue locks the payout at the NAV of **enqueue** time, not **settle** time. If the NAV
rises between the two, who gains and who loses — the redeemer, or the holders who stayed? Is that
the right allocation of risk, and how would you change it?

> Your answer:

The queue fixes `assetsLocked` at `enqueue()`. If Alice requests redemption of 100 shares at a $1.00 NAV and genuine NAV reaches $1.10 before settlement, she still receives $100. Relative to pricing those shares at settlement, she forgoes $10 of appreciation and the remaining fund retains it for continuing holders. If NAV falls, the locked amount instead protects Alice and shifts the loss toward continuing investors. The result allocates market risk according to the valuation cut-off.

A fixed price is defensible when the prospectus defines an irrevocable trade date, that day's NAV is independently struck, and liquidity planning covers the commitment. In this lab, however, a reporter can change NAV arbitrarily and a false valuation can become a fixed ticket liability. I would freeze the number of shares when an order arrives, then calculate the payout at a published dealing cut-off using a reconciled NAV. Settlement would still occur later, with transparent fees, exceptional-market rules and investor disclosure.

The apparent invariant `vault.reserveBalance() >= queue.pendingAssets()` cannot hold throughout normal operation. The vault may invest its entire USDC buffer while solvent securities remain at the custodian. Appreciation resides in those securities until a sale and cash transfer realize it; an attestation does not mint USDC. The executable invariants instead check escrowed pending shares and cash already credited to settled claimants. They establish mechanical accounting properties, not immediate liquidity or economic solvency.

**C2.** In a 2008 money-market fund breaking the buck, and in USDC's 2023 depeg, redemptions were
handled very differently. Compare the two. For a tokenized T-Bill fund, what does it mean to "close
the redemption channel", and what should happen to the queue when it does? Then look at the lever
this lab actually ships: `pause()` (`PAUSER_ROLE`) freezes transfers, minting **and** redemption
together — one switch, no partial setting. Why is that the wrong tool for a liquidity squeeze, and
what would you rather have?

> Your answer:

The Reserve Primary Fund fell below $1 in September 2008 after losses on Lehman debt, suspended redemptions and entered liquidation. Investors faced delayed distributions and losses. USDC's March 2023 depeg involved uncertainty about reserves at Silicon Valley Bank and disrupted bank conversion during a weekend. Circle maintained its commitment to redemption at par; deposit protection and restored banking access supported renewed conversion and recovery of the market price. A permanent portfolio impairment and a temporary banking-access shock require different responses.

For a tokenized T-Bill fund, “closing redemption” should specify whether new requests stop, existing orders await valuation, settlement is deferred, or already funded cash cannot be claimed. Existing tickets should remain recorded in FIFO order, with disclosed treatment of valuation, delays and any legally authorized exceptions. A liquidity shortage does not justify silently deleting claims or changing their priority.

The lab's pause lives in `TBillToken._update`. It blocks transfers, minting and burns, so it also blocks enqueue and settlement that must burn escrowed shares. Crucially, `claim()` for an already settled ticket transfers USDC without changing tBILL balances and remains callable. The switch can therefore obstruct settlement even when sufficient reserve cash is available.

I would separate controls for new subscriptions, ordinary transfers, new redemption requests and settlement. Funded cash claims should normally remain payable, subject to applicable legal restrictions. A narrowly governed emergency halt, public events, review deadlines and independent oversight provide more control than one global switch. These policies manage access; they cannot create missing liquidity.

---

## D. Admission — the guest list and the backdoor (plank d)

**D1.** Every balance change in `TBillToken._update` checks **both** endpoints against the
whitelist. That is what stops a sanctioned address from receiving shares — and also what stops a
completely ordinary user who has not finished KYC. Where is the right line for a regulated fund,
and who should be able to move it?

> Your answer:

A regulated Treasury fund may need to verify beneficial ownership, jurisdiction, sanctions status and investor category before issuing a security or recognizing a transfer. The lab places that boundary in `TBillToken._update`: minting checks the recipient, transfers check both endpoints, and burning checks the holder. Ex4 confirms that an unapproved investor cannot acquire shares through subscription or a transfer from an approved holder. This enforces a clear rule consistently across balance changes.

However, an unfinished KYC application and a sanctions prohibition are different conditions. A single boolean hides their legal basis, duration and remedies. I would require verified eligibility before acquisition while recording distinct reasons and procedures for expiry, temporary restriction and sanctions freezes. A public registry should hold only necessary status information or references; personal documents belong in appropriately protected off-chain systems.

Enrollment should be administered by a designated transfer agent or compliance team under published fund rules, with independently approved identity providers and auditable status changes. Policy changes should require slower governance or a multi-party approval process. An incident team may need faster suspension powers, but those should have documented grounds, review deadlines and an appeal route.

Routine identity updates should not become discretionary confiscation powers. Investors need notice where legally permitted and a way to resolve mistakes or recover access. The optional local permission prototype separates verified identity from freeze status, but it does not implement a full ERC-3643 system or establish actual regulatory compliance. Ultimately the token enforces a registry whose off-chain procedures must be trustworthy.

**D2.** A regulated fund asks for two levers: freeze an address (`setWhitelisted(addr, false)`) and
burn a balance (`MINTER_ROLE`) — both censorship tools, both justified by the product. But Ex4.3
shows the two **collide**: once an address is off the list, `burn()` reverts as well, because
`_update` guards both endpoints. So a freeze also blocks a seizure. Argue **both** sides of handing
an issuer these powers, then say what safeguards you would add and who should hold each key.

> Your answer:

Freezing can be justified when an address is sanctioned, a key is stolen or a court order prevents disposal of disputed assets. A regulated register may also need mandatory transfers or cancellations for lost-key recovery, judgments or operational correction. Without a lawful recovery route, investors can remain permanently locked out. These powers should implement defined legal obligations and investor protections.

The opposing concern is that freeze and burn powers permit censorship and destruction of an investor's position. A false blacklist or compromised administrator could harm innocent holders; an issuer could use recovery language to conceal arbitrary seizure. Burning a token also does not automatically settle the corresponding legal claim or pay compensation.

Ex4.3 exposes the collision: `burn(from, amount)` requires `MINTER_ROLE`, but its call to `_update(from, address(0), amount)` also requires the holder to be whitelisted. Delisting therefore blocks an issuer burn as well as a transfer. That protection is real, but it can obstruct a legitimate recovery order.

I would give routine minting to the issuance service, KYC administration to the transfer agent, and time-limited emergency freezing to a separate incident multisig. Forced recovery should require a distinct authority, a recorded legal case, multi-party approval, independent review and transparent events. Where recovery transfers value, the destination should remain eligible. A narrowly defined exception could permit recovery from a frozen address while preserving ordinary checks. Administrator rotation and policy changes need stronger governance because the default administrator can otherwise recreate every operational privilege.

---

## E. Tests (Tier 1 required — this is Ex2, Ex3 and Ex4)

Turn the red tests green in `test/exercises/01_BridgeTasks.t.sol` to cover the scenarios below, and
write your test function names here:

| Plank | Scenario | Your test function name |
|---|---|---|
| a | Shares exist while the custodian holds nothing | `test_Ex2_SharesExistWhileTheCustodianHoldsNothing` |
| a | `realHoldings()` moves with no cash moving | `test_Ex2_RealHoldingsIsJustANumber` |
| b | The claim value floats while the share count stays | `test_Ex3_TheClaimFloats_TheShareCountDoesNot` |
| b | One `attest` re-prices every holder at once | `test_Ex3_OneCallMovesTheWholeBook` |
| d | A non-whitelisted address cannot receive shares, even by paying | `test_Ex4_NoKyc_NoShares_EvenIfYouPay` |
| d | A whitelisted holder cannot send shares to a non-whitelisted address | `test_Ex4_TransferChecksBothEndpoints` |
| d | Removing an address freezes that holder — and blocks a burn | `test_Ex4_FreezeBeatsConfiscation` |

Then write one more scenario you consider **most likely to be exploited** on a tokenized fund, and
say which plank it breaks:

> Your answer:

A likely exploit is a compromised reporter publishing an inflated NAV that becomes a fixed redemption liability, breaking plank (b) and exposing plank (c)'s cash buffer. A KYC-approved investor subscribes 100 USDC at a $1 NAV, receives 100 shares, raises NAV to $5, and enqueues those shares for 500 USDC. If the authorized settler processes the ticket, the investor receives 500 USDC and gains 400 USDC from the pool. Honest investors supply the lost cash. The local `test_falseNav` implements this route; its fixture explicitly grants the player both reporter and settler roles. A real attacker with only reporting authority would depend on normal authorized settlement or further compromise. The unrestricted mock feed setter makes the lab's reporting boundary weaker still.

The queue can retain exact share escrow and fully fund settled claims throughout this theft: those invariants check accounting, not price truth. Independent reporting and custody reconciliation, feed-writer authentication, deviation checks, a valuation cut-off and monitored cash-outflow limits would reduce the exposure. These measures require operational and legal accountability as well as Solidity.
