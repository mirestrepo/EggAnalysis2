module EggAnalysis2

# package code goes here
# include("eegplots.jl")

export AnalogData, DigitalData, Spectrogram
       
include("eegtypes.jl")


export ad_equals, normalize_data, threshold_01, lowpass, highpass,
       down_sample, toDecibels, debounce_discrete_signal, dd_equals,
       truncate_by_index, truncate_by_value

include("eegutilities.jl")

end # module
