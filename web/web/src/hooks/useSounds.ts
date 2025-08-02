import { useCallback, useRef } from 'react';
import moveSound from '../icons/move.mp3';
import buySound from '../icons/buy.mp3';

type SoundType = 'navigate' | 'select' | 'cancel';

export const useSounds = () => {
  const audioElementsRef = useRef<{ [key: string]: HTMLAudioElement }>({});

  const playSound = useCallback((soundFile: string, volume: number = 0.3) => {
    try {
      // Create or reuse audio element
      if (!audioElementsRef.current[soundFile]) {
        const audio = new Audio(soundFile);
        audio.preload = 'auto';
        audioElementsRef.current[soundFile] = audio;
      }

      const audio = audioElementsRef.current[soundFile];
      audio.volume = Math.min(Math.max(volume, 0), 1);
      audio.currentTime = 0; // Reset to beginning
      audio.play().catch((error) => {
        console.debug('Error playing sound:', error);
      });
      
    } catch (error) {
      console.debug('Error playing sound:', error);
    }
  }, []);

  const playNavigateSound = useCallback(() => playSound(moveSound, 0.2), [playSound]);
  const playSelectSound = useCallback(() => playSound(buySound, 0.35), [playSound]);
  const playCancelSound = useCallback(() => playSound(moveSound, 0.25), [playSound]); // Use move sound for cancel too

  return {
    playNavigateSound,
    playSelectSound,
    playCancelSound
  };
};

export default useSounds;