import soundcard as sc
import soundfile as sf
import numpy as np
import warnings

# Suppress specific warnings related to data discontinuity
warnings.filterwarnings("ignore", category=sc.SoundcardRuntimeWarning)

class AudioRecorder:
    def __init__(self, mic_output_file="microphone_output.wav", sys_output_file="system_output.wav", 
                 sample_rate=48000, chunk_size=4096):
        """
        Initializes the audio recorder for microphone and system audio recording.
        """
        self.mic_output_file = mic_output_file
        self.sys_output_file = sys_output_file
        self.sample_rate = sample_rate
        self.chunk_size = chunk_size

        self.mic_frames = []
        self.sys_frames = []
        self.is_recording = False

        # Get the default microphone and default speaker (loopback for system audio)
        self.microphone = sc.default_microphone()
        self.speaker = sc.get_microphone(id=str(sc.default_speaker().name), include_loopback=True)

    def start_recording(self):
        """Starts recording both microphone and system audio."""
        self.is_recording = True
        print("Recording started...")

        # Open both the microphone and system audio streams
        self.mic_recorder = self.microphone.recorder(samplerate=self.sample_rate, blocksize=self.chunk_size)
        self.sys_recorder = self.speaker.recorder(samplerate=self.sample_rate, blocksize=self.chunk_size)

        self.mic_recorder.__enter__()
        self.sys_recorder.__enter__()

    def record_chunk(self):
        """Records a chunk of audio from both microphone and system audio."""
        if self.is_recording:
            try:
                # Record a chunk of data from both microphone and system audio
                mic_data = self.mic_recorder.record(numframes=self.chunk_size)
                sys_data = self.sys_recorder.record(numframes=self.chunk_size)

                # Append the recorded chunks to their respective buffers
                self.mic_frames.append(mic_data)
                self.sys_frames.append(sys_data)
            except sc.SoundcardRuntimeWarning as e:
                print(f"Warning caught: {e}")

    def stop_recording(self):
        """Stops the recording and saves the recorded data."""
        if self.is_recording:
            self.is_recording = False
            print("Recording stopped...")

            # Close the microphone and system audio recorders
            self.mic_recorder.__exit__(None, None, None)
            self.sys_recorder.__exit__(None, None, None)

            # Convert the recorded frames to a NumPy array
            mic_recorded_data = np.concatenate(self.mic_frames, axis=0)
            sys_recorded_data = np.concatenate(self.sys_frames, axis=0)

            # Save the recorded data to output files
            sf.write(file=self.mic_output_file, data=mic_recorded_data[:, 0], samplerate=self.sample_rate)
            sf.write(file=self.sys_output_file, data=sys_recorded_data[:, 0], samplerate=self.sample_rate)

            print(f"Microphone recording saved to {self.mic_output_file}")
            print(f"System audio recording saved to {self.sys_output_file}")

            # Clear the buffers
            self.mic_frames = []
            self.sys_frames = []

import time

def main():
    # Initialize the AudioRecorder
    recorder = AudioRecorder()

    # Start recording
    recorder.start_recording()

    # Simulate recording for 10 seconds
    for _ in range(10 * int(recorder.sample_rate / recorder.chunk_size)):
        recorder.record_chunk()
        time.sleep(recorder.chunk_size / recorder.sample_rate)  # Control the loop timing

    # Stop recording and save the files
    recorder.stop_recording()

if __name__ == "__main__":
    main()