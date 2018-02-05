using PyPlot, DSP
# include("eegtypes.jl")

"""
    plot_spectrogram(axes, spect::Spectrogram, channel_num::Int64,
    plot_title::String="")
Display spectrogram of a chosen channel of a Spectrogram Object
"""
function plot_spectrogram(axes, spect::Spectrogram, channel_num::Int64,
  plot_title::String="")
  p = spect.power_all[channel_num]
  t = spect.time_bins
  t_first = spect.time[Int(first(t))]
  t_last = spect.time[Int(last(t))]
  f = spect.freq_bins
  fs = spect.analog_data.fs
  img = axes[:imshow](flipdim(p,1), extent=[t_first, t_last,
  fs*first(f), fs*last(f)], aspect="auto")
  xlabel("Time (s)")
  ylabel("Frequency (Hz)")
  cb = colorbar(img, orientation="horizontal", pad=0.35, fraction=0.06)
  if plot_title == ""
    title("Ch $(spect.analog_data.channel_nums[channel_num])")
  else
    title(plot_title)
  end
end

"""
    plot_spectrogram(axes, session::Session, channel_num::Int64, plot_title::String="")
Plot the spectrogram of a chosen channel of the spectrogram of a session object.
"""
function plot_spectrogram(axes, session::Session, channel_num::Int64, plot_title::String="")
  if !isnull(session.spectrum)
    if plot_title == ""
      plot_title = "Ch $(get(session.eeg_data).channel_nums[channel_num]): $(session.name)"
    end
    plot_spectrogram(axes, get(session.spectrum), channel_num, plot_title)
  else
    error("plot_spectrogram: no spectrogram in given session")
  end
end

"""
    function plot_cropped_spectrogram(axes, session::Session, channel_num::Int64, t_start::Float64,
      t_end::Float64, f_low::Float64, f_high::Float64, t_close::Array{Float64,1}=[], t_open::Array{Float64,1}=[], legend_title::String=
      "", plot_title::String="")
Plot the spectrogram of a chosen channel of the spectrogram of a session object, cropped to the times and amplitude limits specified.
Put bar below areas of the graph where eyes are closed (or other types of time periods put into t_close and t_open).
"""
function plot_cropped_spectrogram(axes, session::Session, channel_num::Int64, t_start::Float64,
  t_end::Float64, f_low::Float64, f_high::Float64, t_close::Array{Float64,1}=[], t_open::Array{Float64,1}=[], legend_title::String=
  "", plot_title::String="")
  if !isnull(session.spectrum)
    plot_title = "Ch $(get(session.eeg_data).channel_nums[channel_num]): $(session.name)"
    spect = get(session.spectrum)
    p = spect.power_all[channel_num]
    t = spect.time_bins
    t_first = spect.time[Int(first(t))]
    t_last = spect.time[Int(last(t))]
    f = spect.freq_bins
    fs = spect.analog_data.fs
    img = axes[:imshow](flipdim(p,1), extent=[t_first, t_last,
    fs*first(f), fs*last(f)], aspect="auto")
    xlabel("Time (s)")
    ylabel("Frequency (Hz)")
    xlim(t_start,t_end)
    ylim(f_low-7, f_high)
    cb = colorbar(img, orientation="horizontal", pad=0.4, fraction=0.046, shrink=1.0)
    title(plot_title)
    if length(t_close) == length(t_open) && length(t_close) != 0
      for i = 1:length(t_close)
        PyPlot.plot([t_close[i], t_open[i]], [f_low - 5, f_low - 5], color="red", lw =  4, label=legend_title)
        if i == 1
          legend(bbox_to_anchor=(1.01, 1), loc=2, borderaxespad=0)
        end
      end
    elseif length(t_close) != length(t_open)
      error("t_close and t_open lengths differ")
    end
  else
    error("plot_cropped_spectrogram: no spectrogram in given session")
  end
end


"""
    plot_time(axes, eeg_data::AnalogData, channel_num::Int64,
    plot_title::String="")
Plot a channel of an analog data object vs time
"""
function plot_time(axes, eeg_data::AnalogData, channel_num::Int64,
  plot_title::String="")
  xall = eeg_data.x_all
  x = xall[channel_num, :]
  ti = eeg_data.t
  axes[:plot](ti,x)
  title(plot_title)
  xlabel("Time (s)")
  ylabel("Amplitude (uV)")
end

"""
    plot_time(axes, session::Session, channel_num::Int64, plot_title::String="")
Plot a channel of an analog data object of a session object vs time.
"""
function plot_time(axes, session::Session, channel_num::Int64, plot_title::String="")
  if !isnull(session.eeg_data)
    plot_time(axes, get(session.eeg_data), channel_num, plot_title)
    if plot_title==""
      plot_title = "Ch $(get(session.eeg_data).channel_nums[channel_num]): $(session.name)"
    end
  else
    error("plot_time: no eeg_data in given session")
  end
end


"""
    function plot_cropped_time(axes, session::Session, channel_num::Int64, t_start::Float64,
      t_end::Float64, a_low::Float64, a_high::Float64, t_close::Array{Float64,1}=[], t_open::Array{Float64,1}=[], legend_title::String="",
      plot_title::String="")
Plot a channel of an analog data object of a session vs time, cropped to the times and amplitude limits specified.
Shade areas of the graph where eyes are closed (or other types of time periods put into t_close and t_open).
"""
function plot_cropped_time(axes, session::Session, channel_num::Int64, t_start::Float64,
  t_end::Float64, a_low::Float64, a_high::Float64, t_close::Array{Float64,1}=[], t_open::Array{Float64,1}=[], legend_title::String="",
  plot_title::String="")
  if !isnull(session.eeg_data)
    plot_title = "Ch $(get(session.eeg_data).channel_nums[channel_num]): $(session.name)"
    plot_time(axes, get(session.eeg_data), channel_num, plot_title)
    xlim(t_start,t_end)
    ylim(a_low-7, a_high)
    if length(t_close) == length(t_open) && length(t_close) != 0
      for i = 1:length(t_close)
        axvspan(t_close[i], t_open[i], color="pink", label=legend_title)
        if i == 1
          legend(bbox_to_anchor=(1.01, 1), loc=2, borderaxespad=0)
        end
      end
    elseif length(t_close) != length(t_open)
      error("t_close and t_open lengths differ")
    end
  else
    error("plot_cropped_time: no eeg_data in given session")
  end
end
