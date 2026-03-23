# The $634 Ghost

*Opinions my own, not my employer's.*

Here's what happened. I asked my AI to scan two weeks of email. Routine. "Anything I need to pay attention to?"

Buried in the noise — between Amazon shipping confirmations and LinkedIn connection requests — she found seven PayPal charges from a company called Koflimin Limited. Trading as wisey.app. An ADHD productivity app.

I don't have the app installed on any device.

**$634.93.** Eighteen months of quarterly charges for an app I don't use.

The business model: charge $100 per quarter via PayPal auto-pay. Use the company name "Koflimin Limited" — not the app name — so it doesn't show up when you search your statements for "wisey." Target people with ADHD, a condition literally defined by difficulty tracking recurring obligations.

Monetize the symptom you claim to treat. That's not a bug. It's the product.

---

## This is not an isolated incident

The tech industry has a word for it: **enshittification.** Coined by Cory Doctorow. A platform starts by being good to its users. Then it abuses its users to be good to its business customers. Then it abuses its business customers to claw back all the value for itself. Then it dies.

Some products skip straight to step three. They're born enshittified.

---

## Your printer hates you

The same week I found the ghost charges, my printer told me it was low on ink. I know because my AI queried the printer directly over the network via SNMP. Cyan, magenta, yellow — all at 10%. Black at 80%.

It's an HP OfficeJet Pro — an "HP+" printer. That plus sign means HP can remotely disable third-party ink cartridges via firmware updates. The printer requires an internet connection and an HP account. HP pushes subscription plans where you pay monthly for permission to use ink you already bought. If you cancel, HP can remotely disable cartridges you've already paid for.

You don't own the printer. You own a box that HP lets you use under terms that can change at any time.

So I went looking for replacement cartridges. My AI price-compared across six retailers in about 30 seconds. The cheapest third-party option? $51. But HP+ printers actively block non-OEM cartridges through firmware. The cheaper option isn't actually available to you. That's by design.

The alternative exists: ink tank printers. You pour ink from bottles into a reservoir. No chips, no DRM, no subscriptions. About $5 per year in ink. They've existed for years. You've probably never heard of them.

---

## The pattern is everywhere

Once you start looking, you can't stop.

Your password manager sends a security alert from an unfamiliar city. Was it you? You don't know. You'll check later. You won't.

Your credit card sends seven "card not present" alerts in two weeks. Are they fraud? Probably not. Maybe. You'll look into it.

Your ride-share membership is about to lapse because the card on file expired. You'll update it. Eventually.

A friend emailed three days ago about weekend plans. You haven't replied.

None of these are hard problems. Every single one persists because there's no system watching out for you. The companies involved are either actively hostile or passively indifferent. None of them will tap you on the shoulder and say "hey, you're bleeding money."

---

## What happened next

In one hour, my AI:

1. Scanned two weeks of email and surfaced seven action items
2. Found $634.93 in ghost charges I didn't know about
3. Queried my printer's ink levels directly over the network
4. Price-compared cartridges across six retailers
5. Identified a security concern with my password manager
6. Created a personal issue tracker with every open thread prioritized

No app. No subscription. No account. No data leaving my machine. Just an AI that can read my email, talk to my devices, and tell me the truth.

The ADHD app charged me $100 per quarter to help me stay organized. My AI caught the charge, identified the pattern, calculated the total damage, and told me how to cancel it — in 30 seconds. The tool that was supposed to help me was the problem. The tool that actually helped me wasn't even trying to be an ADHD app.

---

The styled version with all the visuals is here: https://jodonnel.github.io/zoe/enshittification.html

The open source project behind it: https://github.com/jodonnel/zoe

*Opinions my own, not my employer's.*
