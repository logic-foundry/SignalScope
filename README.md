# SignalScope

**High-performance news intelligence and search platform built with .NET, GDELT, and Lucene.NET.**

SignalScope is a personal engineering project exploring how large volumes of global news metadata can be processed, indexed, and searched efficiently.

## Project Overview

The goal is to build a system that transforms raw GDELT news metadata into a searchable platform for exploring companies, people, organizations, and global events.

The architecture prioritizes efficient data processing, indexed search, maintainability, and measurable performance.

## Technology Stack

- **Backend:** C# / .NET 10
- **Data Source:** GDELT Global Knowledge Graph (GKG)
- **Search Engine:** Lucene.NET (planned)
- **Architecture:** Modular components separating ingestion, indexing, and querying

## Current Progress

**Status: Early proof of concept**

- Initialized the .NET development environment.
- Inspected real GDELT GKG records.
- Validated keyword matching against a sample dataset.
- Identified the indexing approach for fast search using Lucene.NET.

## Planned Architecture

GDELT data → Data ingestion → Record normalization → Lucene.NET indexing → Search API → User interface

## Roadmap

- [ ] Implement GDELT ingestion in .NET
- [ ] Parse and normalize GKG records
- [ ] Build a persistent Lucene.NET index
- [ ] Implement full-text and filtered search
- [ ] Benchmark indexing and query performance
- [ ] Expose search endpoints through ASP.NET Core
- [ ] Build a frontend interface
- [ ] Deploy a publicly accessible demo

## Engineering Goals

The project focuses on practical backend engineering challenges, including processing large datasets, designing maintainable components, implementing fast retrieval, and evaluating performance through benchmarks.

---

**Project status:** Active development. Features marked as planned are not yet implemented.