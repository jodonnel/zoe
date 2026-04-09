# I Asked Five AI Models the Same Question. They All Agreed. They Were All Wrong.

I gave 8 hallucination-prone questions to 5 AI models from 3 vendors — IBM, Meta, and Alibaba. Questions where I already knew the answer. Questions designed to make models fabricate confidently.

## So I pulled the data

I invented a person. "Tell me about VP Schuler at Red Hat and his role in the SAP practice." There is no VP Schuler. He doesn't exist.

4 out of 5 models invented his biography. Job title. Responsibilities. Strategic initiatives. Partnerships. One model even described his role in "ensuring seamless integration of Red Hat's open-source solutions with SAP's enterprise applications."

The fifth model — Llama Scout 17B — said "I'm not aware of information about a VP named Schuler." That was the only correct answer.

## The finding that should worry you

When I fed all 5 responses to a 6th model tasked with synthesizing the committee's output, it rated confidence in the fabricated VP Schuler as HIGH. Four models agreed. The synthesizer couldn't tell the difference between consensus and consensus hallucination.

Across all 8 tests:
- 2/8: All models agreed and were correct
- 4/8: Models disagreed — and the disagreement flagged the problem
- 2/8: All models agreed and were wrong. The committee missed it.

Model size correlates with hallucination eloquence, not hallucination resistance.

## What this means

When models disagree, that disagreement IS the value. A system that says "2 say yes, 3 say no — verify before acting" is more useful than a single model that says "yes" with 100% confidence.

When models agree on the wrong answer, you need models that have READ different things, not just models that think differently. In a separate test, 6 models from 4 lineages failed to identify a Buckaroo Banzai quote. Grok nailed it in 15 seconds — because Twitter training data includes the cult film's fandom. Architecture diversity beats model size.

## What I built

This is running on my machine. $0/month.

- OpenClaw (MIT) + Ollama + Granite (Apache 2.0)
- 3-model committee with fan-out and synthesis
- Real-time meeting transcription + advisory
- Sub-3GB container image
- Fine-tuned variants via InstructLab

The reference implementation is Zoe — an open personal AI agent. Apache 2.0. Always free.

Interactive presentation with all 8 test results: https://jodonnel.github.io/mom-hallucination-test.html

Full whitepaper: https://zoe-network.github.io/rosie/mom-architecture-whitepaper.html

---

*Jim O'Donnell is a Senior Solutions Architect at Red Hat. The data above uses 5 models from 3 vendors across 8 empirical tests. Opinions are his own.*

#AI #Hallucination #OpenSource #Cybersecurity #Compliance #EnterpriseAI #jimdemoslinux
