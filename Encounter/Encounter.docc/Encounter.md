# ``Encounter``

Daggerheart encounter prep and run app for iOS and macOS.

## Overview

Encounter helps game masters set up and track Daggerheart encounters at the table.
Load adversaries and environments from the built-in SRD compendium, build an encounter
roster, then run it live — tracking HP, stress, conditions, and turn order as the scene
unfolds.

The app is built with SwiftUI and targets iOS 26, macOS 26, and visionOS 26.

### Content packs

Encounter supports community and homebrew content through the `.dhpack` format — a
plain JSON file containing adversaries, environments, or both. Packs can be imported
from Files or AirDrop, or added as a live URL source that the app keeps up to date.

See the [DaggerheartModels](https://swiftpackageindex.com/gwillish/DHModels/documentation/daggerheartmodels) documentation for the complete `.dhpack` format reference, authoring guide, and sharing options.

### Getting started

- <doc:GettingStarted>

## Topics

### App Usage

- <doc:GettingStarted>

### Catalog Models

- ``Adversary``
- ``AdversaryType``
- ``AttackRange``
- ``AdversaryFeature``
- ``FeatureType``
- ``DaggerheartEnvironment``

### Data Store

- ``Compendium``
- ``CompendiumError``

### Content Sources

- ``ContentSource``
- ``ContentStore``
- ``ContentFetcher``
- ``ContentStoreError``
- ``DHPackContent``
- ``ContentFingerprint``

### Encounter Session

- ``EncounterSession``
- ``EncounterDefinition``
- ``AdversarySlot``
- ``EnvironmentSlot``
- ``PlayerSlot``
- ``Condition``

### Difficulty

- ``DifficultyBudget``
- ``EncounterStore``
- ``SessionRegistry``
