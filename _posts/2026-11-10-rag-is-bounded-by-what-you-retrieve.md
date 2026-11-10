---
layout: post
title: "RAG is bounded by what you retrieve, not which model you pick"
date: 2026-11-10
categories: [Blog, Analysis]
tags: [ai, analysis, retrieval]
description: "Swapping models is the expensive way to fix a retrieval system whose unit of retrieval is a whole document."
author: matt
image:
  path: https://res.cloudinary.com/de1eajx01/image/upload/f_jpg,q_auto,w_1200,h_630,c_fill/assets/blog/rag-is-bounded-by-what-you-retrieve.jpg
  alt: "RAG is bounded by what you retrieve, not which model you pick"
pin: false
toc: true
comments: false
math: false
mermaid: false
---

If a retrieval-augmented system gives vague answers, the instinct is to reach for a better model. Most of the time the ceiling was set before the model ever saw a token, by the size of the thing you handed it.

## The context is the ceiling

A model can only cite what it receives. Retrieve a 3,000-word document because one paragraph is relevant, and the other 2,800 words do not sit quietly — they compete, dilute attention, and push the answer toward the average of everything in the window. Retrieve the one claim instead, and every token in the context is pulling in the same direction.

That is the whole argument, and it is testable without a benchmark harness: take a question whose answer lives in one section of a long note, then compare retrieving the note against retrieving the section. Same model, same prompt, different unit.

## Retrieval unit is a design decision, not a default

Most vector-search setups index whatever the splitter gives them — chunks of 500 tokens, or whole files because chunking felt fiddly. Both are arbitrary. The interesting question is: what is the smallest unit that is *meaningful on its own*?

In my own vault the answer is a claim. Each note is written so that one section states a single assertion, and that section is extracted as a first-class retrieval unit. The index then holds claims rather than documents, so relevance is sharp by construction: a match is a statement, not "this file is vaguely about networking".

This is the same boundary rule that makes Zettelkasten notes work at all — the knowledge unit and the retrieval unit coincide. If your notes are claims and your retrieval unit is a document, you spent effort on the wrong granularity.

## What this changes in practice

- **Model upgrades are the last lever, not the first.** If context is mostly noise, a better model gets better at ignoring noise; it cannot recover information that was averaged out.
- **Chunk size is a claim about semantics.** Fixed-token windows cut sentences in half and produce units that are not about anything. Structure-aware extraction costs more work up front and pays every query.
- **Hybrid retrieval is orthogonal, not a substitute.** Fusing BM25 with vectors decides *which* units surface; the claim boundary decides what a unit even is. You need both, and they fail differently.

None of this is exotic. It is just the unglamorous part: deciding what a passage means before you ask a model to reason about it.
