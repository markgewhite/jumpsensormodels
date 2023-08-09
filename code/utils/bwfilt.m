function dataFiltered = bwfilt(data, bworder, fs, fc, type)
    % BWFILT Zero-lag low-pass Butterworth filter
    % 
    % INPUT     data: data to be filtered (Nf-by-M)
    %           bworder: order of the Butterworth filter (1-by-1)
    %           fs: sampling frequency (1-by-1)
    %           fc: cut-off frequency (1-by-1)
    %           type: type of filter, "high" for a highpass filter 
    %                                 "low" for a lowpass filter
    % 
    % OUTPUT    data_filt: filtered data (Nf-by-M)
    % 
    % Author: Elena Bergamini - University of Rome "Foto Italico"
    % Date: January 30th 2013
    arguments
        data            double
        bworder         double {mustBeInteger, mustBePositive}
        fs              double {mustBePositive}
        fc              double {mustBePositive}
        type            char {mustBeMember(type, {'low', 'high'})} = 'low'
    end
    
    [b,a] = butter( bworder, 2*fc/fs, type );

    dataFiltered = filtfilt( b, a, data );

end