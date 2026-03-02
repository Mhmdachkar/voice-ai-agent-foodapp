export const Audio = {
  requestPermissionsAsync: jest.fn().mockResolvedValue({ granted: true }),
  setAudioModeAsync: jest.fn().mockResolvedValue(undefined),
  Recording: {
    createAsync: jest.fn().mockResolvedValue({
      recording: {
        stopAndUnloadAsync: jest.fn(),
        getURI: jest.fn().mockReturnValue('file://test.wav'),
        getStatusAsync: jest.fn().mockResolvedValue({ isRecording: true, metering: -50 }),
      },
    }),
  },
  Sound: {
    createAsync: jest.fn().mockResolvedValue({
      sound: {
        setOnPlaybackStatusUpdate: jest.fn(),
        unloadAsync: jest.fn(),
        stopAsync: jest.fn(),
      },
    }),
  },
  AndroidOutputFormat: { DEFAULT: 0 },
  AndroidAudioEncoder: { DEFAULT: 0 },
  IOSOutputFormat: { LINEARPCM: 0 },
  IOSAudioQuality: { HIGH: 0 },
};
