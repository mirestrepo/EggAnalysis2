# EggAnalysis2
Library for analyzing EEG and ECoG data.
Work in progress, not to be used/trusted yet.

## Installation

```julia
Pkg.clone("")
```

## General Functionality

* Create a session with desired name and directory
* Use load_eeg function to load data into the session from specific channels
* Use lowpass_session or highpass_session to filter the session
* Create plot using the appropriate plotting function

## Index

```@index
Modules = [EggAnalysis2]
```

## Functions

```@autodocs
Modules = [EggAnalysis2]
Order   = [:function, :type]
```