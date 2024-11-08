% Load the vocal and instrumental waveforms
%[vocal, vocal_fs] = audioread("C:\Users\EDCEL\Downloads\Data Test\Original from YT\Honey My Love So Sweet\Vocali.se_5897_y2mate.com---Honey-my-Love-So-Sweet-Remastered_vocals.mp3");
%[instrumental, instrumental_fs] = audioread("C:\Users\EDCEL\Downloads\Data Test\Original from YT\Honey My Love So Sweet\Vocali.se_5897_y2mate.com---Honey-my-Love-So-Sweet-Remastered_music.mp3");

%[vocal, vocal_fs] = audioread("C:\Users\EDCEL\Desktop\KaraokeScoring\Recording\microphone_output.wav");
%[instrumental, instrumental_fs] = audioread("C:\Users\EDCEL\Desktop\KaraokeScoring\Recording\system_output.wav");

[vocal, vocal_fs] = audioread('Recording\microphone_output_1.wav');
[instrumental, instrumental_fs] = audioread('Recording\system_output_1.wav');

% Ensure both tracks have the same sample rate
if vocal_fs ~= instrumental_fs
    error('Sample rates of the vocal and instrumental tracks must match');
end

% Define parameters
fs = vocal_fs;  % Sampling frequency
frame_size = 0.02;  % 20 ms frame size
frame_length = round(frame_size * fs);  % Frame length in samples

%% Melody Extraction for Dynamic Pitch Reference (from the instrumental)
expected_pitch_instrumental = zeros(floor(length(instrumental) / frame_length), 1);
for i = 1:frame_length:length(instrumental) - frame_length
    frame = instrumental(i:i + frame_length - 1);
    expected_pitch_instrumental(ceil(i / frame_length)) = yin_pitch_detection(frame, fs);
end

%% PITCH ANALYSIS (for the vocal track using YIN)
pitch_vocal = zeros(floor(length(vocal) / frame_length), 1);
for i = 1:frame_length:length(vocal) - frame_length
    frame = vocal(i:i + frame_length - 1);
    pitch_vocal(ceil(i / frame_length)) = yin_pitch_detection(frame, fs);
end

% Calculate pitch accuracy by comparing vocal pitch to the dynamic expected pitch
tolerance = 100; % Increased Hz tolerance for pitch matching
pitch_differences = abs(pitch_vocal - expected_pitch_instrumental);

% Ignore NaN values in pitch calculations
valid_pitch_differences = pitch_differences(~isnan(pitch_differences));

% Handle case where pitch detection returns mostly NaNs
if ~isempty(valid_pitch_differences)
    pitch_errors = valid_pitch_differences > tolerance;
    pitch_accuracy = 1 - mean(pitch_errors, 'omitnan');  % Ratio of correct pitches
else
    pitch_accuracy = 0.5;  % Default to 50% accuracy if pitch detection fails often
end
disp(['Pitch Accuracy: ', num2str(pitch_accuracy * 100), '%']);

%% TIMING ANALYSIS (remains the same)
vocal_beats = custom_findpeaks(vocal, fs * 0.5);  % Custom peak detection
instrumental_beats = custom_findpeaks(instrumental, fs * 0.5);  % Custom peak detection

% Calculate timing accuracy by matching closest beats
beat_tolerance = 0.1 * fs;  % Increased allowable difference to 100 ms
timing_errors = 0;
for i = 1:length(vocal_beats)
    [min_diff, idx] = min(abs(instrumental_beats - vocal_beats(i)));
    if min_diff > beat_tolerance
        timing_errors = timing_errors + 1;  % Count as timing error
    end
end

timing_accuracy = 1 - (timing_errors / length(vocal_beats));
disp(['Timing Accuracy: ', num2str(timing_accuracy * 100), '%']);

%% FINAL SCORE
% We adjust the weight to reduce harshness
final_score = (0.7 * pitch_accuracy) + (0.3 * timing_accuracy);
disp(['Final Karaoke Score: ', num2str(final_score * 100), '/100']);

%% Helper Function: YIN Pitch Detection
function pitch = yin_pitch_detection(frame, fs)
    % Implement a more robust pitch detection algorithm
    % Placeholder for real YIN algorithm or use a pitch detection library
    threshold = 0.1; % Lowered threshold for valid pitch
    r = yin_autocorrelation(frame); % perform autocorrelation
    pitch = yin_extract_pitch(r, fs, threshold);
end

function r = yin_autocorrelation(frame)
    % YIN-like autocorrelation placeholder
    [r, lags] = xcorr(frame);  
    r = r(lags >= 0);  
end

function pitch = yin_extract_pitch(r, fs, threshold)
    % YIN thresholding to extract pitch from autocorrelation
    [peaks, locs] = findpeaks(r);
    if ~isempty(peaks)
        [max_val, idx] = max(peaks);  % Find the maximum peak
        if max_val > threshold && locs(idx) > 1
            period = locs(idx);
            pitch = fs / period;
        else
            pitch = NaN;  % No valid pitch detected
        end
    else
        pitch = NaN;  % No peaks found, return NaN
    end
end

%% Helper Function: Custom Peak Detection (same as before)
function locs = custom_findpeaks(signal, min_distance)
    if nargin < 2
        min_distance = 1;
    end
    locs = [];
    len_signal = length(signal);
    for i = 2:len_signal-1
        if signal(i) > signal(i-1) && signal(i) > signal(i+1)
            if isempty(locs) || (i - locs(end)) >= min_distance
                locs = [locs, i];
            end
        end
    end
end



% Get the current date (no time included)
current_date = datestr(now, 'yyyy-mm-dd');

% Define the file paths
current_score_filename = 'Recording/KaraokeScore.txt';
score_history_filename = 'RecordingHistory/ScoreHistory.txt';

% Save the current score (overwrite mode)
fileID = fopen(current_score_filename, 'w');
if fileID == -1
    error('Unable to open file for writing. Check the file path.');
end
fprintf(fileID, '%.2f', final_score * 100);
fclose(fileID);
disp(['Current score saved to ', current_score_filename]);

% Save the score to the history file with date (append mode)
fileID = fopen(score_history_filename, 'a');
if fileID == -1
    error('Unable to open file for appending. Check the file path.');
end
fprintf(fileID, '%s: %.2f\n', current_date, final_score * 100);
fclose(fileID);
disp(['Score appended to history in ', score_history_filename]);
