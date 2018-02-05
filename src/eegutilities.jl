using PyPlot, DSP, MultivariateStats
include("eegtypes.jl")

"""
    normalize_data(x)
Normalize data
"""
function normalize_data(x::Vector{})
  xmax::Float64 = maximum(x)
  xnorm = x/xmax
end

"""
    normalize_data(ad::AnalogData)
Normalize every channel of x_all of an AnalogData object.
"""
function normalize_data(ad::AnalogData)
  x_all = ad.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = normalize_data(x_all[row,:])
  end
  return AnalogData(new_x_all, ad.t, ad.original_fs, ad.fs, ad.channel_nums)
end


"""
    threshold_01(x, threshold)
Turn all values above a threshold into ones and all values below into zeros
"""
function threshold_01(x::Vector{Float64}, threshold::Float64)
  hi_indices = x.>=threshold
  x_new = falses(size(x))
  x_new[hi_indices] = true
  return x_new
end

"""
    threshold_01(ad::AnalogData, threshold)
Turn all values above a threshold into ones and all values below into zeros for
each channel in x_all of an AnalogData object.
"""
function threshold_01(ad::AnalogData, threshold::Float64)
  x_all = ad.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = threshold_01(x_all[row,:], threshold)
  end
  return AnalogData(new_x_all, ad.t, ad.original_fs, ad.fs, ad.channel_nums)
end


"""
    lowpass(data, cutoff, fs, order=5)
Lowpass filter data
"""
function lowpass(data::Vector{}, cutoff::Float64, fs::Int64, order::Int64=5)
  responsetype = Lowpass(cutoff, fs=fs)
  designmethod = Butterworth(order)
  filtered_data = filt(digitalfilter(responsetype, designmethod), data)
end

"""
    lowpass(ad::AnalogData, cutoff, fs, order=5)
Lowpass filter every channel in x_all of an AnalogData object.
"""
function lowpass(ad::AnalogData, cutoff::Float64, order::Int64=5)
  x_all = ad.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = lowpass(x_all[row,:], cutoff, ad.fs, order)
  end
  return AnalogData(new_x_all, ad.t, ad.original_fs, ad.fs, ad.channel_nums)
end

"""
    highpass(data, cutoff, fs, order=5)
Highpass filter data
"""
function highpass(data::Vector{}, cutoff::Float64, fs::Int64, order::Int64=5)
  responsetype = Highpass(cutoff, fs=fs)
  designmethod = Butterworth(order)
  filtered_data = filt(digitalfilter(responsetype, designmethod), data)
end

"""
    highpass(ad::AnalogData, cutoff, fs, order=5)
Highpass filter every channel in x_all of an AnalogData object.
"""
function highpass(ad::AnalogData, cutoff::Float64, order::Int64=5)
  x_all = ad.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = highpass(x_all[row,:], cutoff, ad.fs, order)
  end
  return AnalogData(new_x_all, ad.t, ad.original_fs, ad.fs, ad.channel_nums)
end

"""
    down_sample(x::Vector{Float64}, factor::Int64)
Downsample a vector x by a given factor. (If factor is 3, keep one value out of every three)
"""
function down_sample(x::Vector{Float64}, factor::Int64)
  new_x = []
  for n in 1:factor:length(x)
    append!(new_x, x[n])
  end
  return new_x
end

"""
    down_sample(ad::AnalogData, factor::Int64)
Downsample every channel in x_all of an analogdata object by a given factor.
"""
function down_sample(ad::AnalogData, factor::Int64)
  x_all = ad.x_all
  new_x_all = zeros(Float64, size(x_all)[1], length(down_sample(x_all[1,:],
  factor)))
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = down_sample(x_all[row,:], factor)
  end
  new_t = down_sample(ad.t, factor)
  new_fs = ad.fs/factor
  return AnalogData(new_x_all, new_t, ad.original_fs, new_fs, ad.channel_nums)
end

"""
    format_full_array(x::Array{Float64, 1})
Return string will full-precision respresentation of floats in the array.
For getting exact values in test cases.
"""
function format_full_array(x::Array{Float64, 1})
  string = "["
  for value in x
    # 30 decimal places should be more than enough
    string *= @sprintf("%0.30f, ", value)
  end
  string *= "]"
  return string
end

"""
    toDecibels(x, x_ref)
Covert x to decibels with reference x_ref.
"""
function toDecibels(x::Vector{Float64}, x_ref::Float64)
  return 10.*log10(clamp!((x./x_ref), .00000001 , 100000000))
end

"""
    toDecibels(ad::AnalogData, x_ref)
Covert each channel of x_all of the AnalogData object to decibels with reference
x_ref.
"""
function toDecibels(ad::AnalogData, x_ref::Float64)
  x_all = ad.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = toDecibels(x_all[1,:], x_ref)
  end
  return AnalogData(new_x_all, ad.t, ad.original_fs, ad.fs, ad.channel_nums)
end

"""
    debounce_discrete_signal(x, min_samples_per_chunk)
For use after threshold_01. Remove any bounces shorter than
min_samples_per_chunk, with the exception of a short leading bounce at the
beginning of the array.
"""
function debounce_discrete_signal(x::Vector{Bool}, min_samples_per_chunk::Int64)
  start_index = 0
  x_new = copy(x)
  num_bounces_removed = 0
  for i in collect(2:length(x_new))
    if x_new[i] != x_new[i-1]
      if (start_index > 0) && (i - start_index < min_samples_per_chunk)
        x_new[start_index:i] = x_new[i]
        num_bounces_removed += 1
      else
        start_index = i
      end
    end
  end
  if num_bounces_removed > 0
    println("debounce_discrete_signal: removed $(num_bounces_removed) bounces")
  end
  return x_new
end

"""
    debounce_discrete_signal(dd::DigitalData, min_samples_per_chunk::Int64)
For use after threshold_01. Remove any bounces shorter than
min_samples_per_chunk in every channel of x_all of the DigitalData object,
with the exception of a short leading bounce at the beginning of the array.
"""
function debounce_discrete_signal(dd::DigitalData, min_samples_per_chunk::Int64)
  x_all = dd.x_all
  new_x_all = copy(x_all)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = debounce_discrete_signal(x_all[row,:], min_samples_per_chunk)
  end
  return DigitalData(new_x_all, dd.t, dd.original_fs, dd.fs, dd.channel_nums)
end

"""
    truncate_by_index(x::Vector{}, t::Vector{}, index_range::Vector{})
Return copies of x and t truncated to the given range of samples. index_range
is a list containing the start index (inclusive)and end index (exclusive).
If index_range contains floats, they will be rounded down to ints.
t must be a 1d array with the same length as dimension dim of x.
"""
function truncate_by_index(x::Vector{Float64}, t::Vector{Float64},
  index_range::Vector{Int64})
  if index_range == nothing
    return(x,t)
  index_range = [index_range[1], index_range[2]]
  elseif (index_range[1] < 0 || index_range[2] > length(t) ||
    index_range[1] > index_range[2])
    error("truncate_by_index: Invalid range indices")
  end
  new_x = x[index_range[1]:index_range[2]]
  new_t = t[index_range[1]:index_range[2]]
  return(new_x, new_t)
end

"""
    truncate_by_index(analogdata::AnalogData, index_range::Vector{})
Truncate t and every channel of x_all in the AnalogData object to the given
range of sample.
"""
function truncate_by_index(analogdata::AnalogData, index_range::Vector{Int64})
  if index_range == nothing
    return analogdata
  end
  x_all = analogdata.x_all
  t = analogdata.t
  new_x_all = zeros(Float64, size(x_all)[1], index_range[2]-index_range[1]+1)
  for row in collect(1:size(x_all)[1])
    new_x_all[row,:] = truncate_by_index(x_all[row,:], t, index_range)[1]
  end
  new_t = t[index_range[1]:index_range[2]]
  return(AnalogData(new_x_all, new_t, analogdata.original_fs, analogdata.fs,
  analogdata.channel_nums))
end

"""
    truncate_by_value(x::Vector{}, t::Vector{}, t_range::Vector{})
Return copies of x and t truncated to approximately the given time range.
t_range is a list containing the start and end times in seconds. t must be a 1d
array with the same length as dimension dim of x.
"""
function truncate_by_value(x::Vector{Float64}, t::Vector{Float64},
  t_range::Vector{Float64})
  if t_range == nothing
    return (x,t)
  elseif t_range[2] <= t_range[1] || t_range[2] > t[end]
    error("truncate_by_index: Invalid time range")
  end
  index_range = [1, length(t)]
  if t_range[1] > t[1]
    index_range[1] = indmax(t.>t_range[1])
  end
  if t_range[2] < t[end]
    index_range[2] = indmax(t.>t_range[2])
  end
  return truncate_by_index(x, t, index_range)
end

"""
    truncate_by_value(analogdata::AnalogData, t_range::Vector{})
Truncate t and every channel of x_all in the AnalogData object to approximately
the given time range.
"""
function truncate_by_value(analogdata::AnalogData, t_range::Vector{Float64})
  t = analogdata.t
  x_all = analogdata.x_all
  if t_range == nothing
    return (x_all,t)
  elseif t_range[2] <= t_range[1] || t_range[2] > t[end]
    error("truncate_by_index: Invalid time range")
  end
  index_range = [1, length(t)]
  if t_range[1] > t[1]
    index_range[1] = indmax(t.>t_range[1])
  end
  if t_range[2] < t[end]
    index_range[2] = indmax(t.>t_range[2])
  end
  return truncate_by_index(analogdata, index_range)
end

"""
    ica(ad::AnalogData)
Perform ICA over x_all of an AnalogData object and return the updated AnalogData.
Number of components assumed to be number of channels.
"""
function ica(ad::AnalogData)
  x = ad.x_all
  k = size(ad.x_all)[1]
  i  = fit(ICA, x, k)
  new_x =  transform(i,x)
  AnalogData(new_x, ad.t, original_fs=ad.fs, channel_nums=ad.channel_nums)
end
