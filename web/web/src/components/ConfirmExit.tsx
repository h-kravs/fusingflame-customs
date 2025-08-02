import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faSignOutAlt } from '@fortawesome/free-solid-svg-icons';
import useSounds from '../hooks/useSounds';
// REMOVED: import useControllerInput from '../hooks/useControllerInput';

interface ConfirmExitProps {
  isVisible: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmExit: React.FC<ConfirmExitProps> = ({
  isVisible,
  onConfirm,
  onCancel
}) => {
  const [selectedOption, setSelectedOption] = useState<'yes' | 'no'>('no'); // Default to NO for exit
  const [animationState, setAnimationState] = useState<'entering' | 'visible' | 'exiting' | 'hidden'>('hidden');
  const { playNavigateSound, playSelectSound, playCancelSound } = useSounds();
  
  // REMOVED: Multiple useControllerInput instances causing conflicts
  // const inputPress = useControllerInput(["ArrowUp", "ArrowDown", "Enter"], 
  //   isVisible && animationState === 'visible');

  // Handle animation states based on visibility - separate effects to avoid cleanup conflicts
  useEffect(() => {
    if (isVisible) {
      // // console.log('🚪 [ENTRY] ConfirmExit isVisible=true, setting entering');
      setAnimationState('entering');
      
      const timer = setTimeout(() => {
        setAnimationState('visible');
      }, 200);
      
      return () => clearTimeout(timer);
    }
  }, [isVisible]);

  useEffect(() => {
    if (!isVisible) {
      if (animationState === 'visible' || animationState === 'entering') {
        // console.log('🚪 [EXIT] ConfirmExit isVisible=false, setting exiting');
        setAnimationState('exiting');
        
        const timer = setTimeout(() => {
          setAnimationState('hidden');
        }, 150);
        
        return () => clearTimeout(timer);
      }
    }
  }, [isVisible, animationState]);

  // Handle controller input using the hook
  useEffect(() => {
    if (!isVisible || animationState !== 'visible') return;
    
    setSelectedOption('no'); // Reset to NO when opening (safer default for exit)
  }, [isVisible, animationState]);

  // Handle keyboard/gamepad input with direct event listeners to avoid conflicts
  useEffect(() => {
    if (!isVisible || animationState !== 'visible') return;

    const handleKeyInput = (event: KeyboardEvent) => {
      // console.log('🚪 [ConfirmExit] Direct keyboard input detected:', event.key);
      
      if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
        // console.log('🚪 [ConfirmExit] Navigation input - changing selection');
        event.preventDefault();
        playNavigateSound();
        setSelectedOption(prev => {
          const newSelection = prev === 'yes' ? 'no' : 'yes';
          // console.log('🚪 [ConfirmExit] Selection changed from', prev, 'to', newSelection);
          return newSelection;
        });
      } else if (event.key === 'Enter') {
        // console.log('🚪 [ConfirmExit] Enter pressed - current selection:', selectedOption);
        event.preventDefault();
        if (selectedOption === 'yes') {
          // console.log('🚪 [ConfirmExit] Confirming exit');
          playSelectSound();
          onConfirm();
        } else {
          // console.log('🚪 [ConfirmExit] Canceling exit');
          playCancelSound();
          onCancel();
        }
      }
    };

    // Gamepad polling for dialog
    let lastGamepadState: Record<number, boolean> = {};
    let lastAxisState: Record<string, number> = {};
    
    const pollGamepadForDialog = () => {
      const gamepads = navigator.getGamepads();
      const gamepad = gamepads[0];
      if (!gamepad) return;

      // D-pad up (button 12)
      const upPressed = gamepad.buttons[12]?.pressed;
      const wasUpPressed = lastGamepadState[12];
      
      // D-pad down (button 13) 
      const downPressed = gamepad.buttons[13]?.pressed;
      const wasDownPressed = lastGamepadState[13];
      
      // A button (button 0)
      const aPressed = gamepad.buttons[0]?.pressed;
      const wasAPressed = lastGamepadState[0];

      // Analog stick vertical axis (axis 1)
      const axisValue = gamepad.axes[1] || 0;
      const threshold = 0.5;
      const axisUpPressed = axisValue < -threshold; // Up
      const axisDownPressed = axisValue > threshold; // Down
      const wasAxisUpPressed = lastAxisState['1_up'] < -threshold;
      const wasAxisDownPressed = lastAxisState['1_down'] > threshold;

      // Check for navigation input (D-pad or analog stick)
      const navigationDetected = (upPressed && !wasUpPressed) || 
                                (downPressed && !wasDownPressed) ||
                                (axisUpPressed && !wasAxisUpPressed) ||
                                (axisDownPressed && !wasAxisDownPressed);

      if (navigationDetected) {
        // console.log('🚪 [ConfirmExit] Gamepad navigation - changing selection');
        playNavigateSound();
        setSelectedOption(prev => {
          const newSelection = prev === 'yes' ? 'no' : 'yes';
          // console.log('🚪 [ConfirmExit] Selection changed from', prev, 'to', newSelection);
          return newSelection;
        });
      } else if (aPressed && !wasAPressed) {
        // console.log('🚪 [ConfirmExit] Gamepad A pressed - current selection:', selectedOption);
        if (selectedOption === 'yes') {
          // console.log('🚪 [ConfirmExit] Confirming exit');
          playSelectSound();
          onConfirm();
        } else {
          // console.log('🚪 [ConfirmExit] Canceling exit');
          playCancelSound();
          onCancel();
        }
      }

      // Update last state
      lastGamepadState = {
        12: upPressed,
        13: downPressed,
        0: aPressed
      };
      
      lastAxisState = {
        '1_up': axisValue,
        '1_down': axisValue
      };
    };

    // Add event listener with high priority
    window.addEventListener('keydown', handleKeyInput, true);
    
    // Start gamepad polling
    const gamepadInterval = setInterval(pollGamepadForDialog, 100);
    
    return () => {
      window.removeEventListener('keydown', handleKeyInput, true);
      clearInterval(gamepadInterval);
    };
  }, [isVisible, animationState, selectedOption, onConfirm, onCancel, playNavigateSound, playSelectSound, playCancelSound]);


  // Debug logs for ConfirmExit
  useEffect(() => {
    // console.log('🚪 [ConfirmExit] Visibility changed:', isVisible, 'animationState:', animationState);
  }, [isVisible, animationState]);

  useEffect(() => {
    // console.log('🚪 [ConfirmExit] Selected option changed to:', selectedOption);
  }, [selectedOption]);

  if (animationState === 'hidden') {
    return null;
  }

  return (
    <div className="confirm-center-wrapper">
      <div className={`confirm-purchase-container ${animationState}`}>
        <h1 className="confirm-title">EXIT CUSTOMS</h1>
        
        <div className="confirm-cost">
          <span className="cost-label">ARE YOU SURE?</span>
          <div className="cost-amount">
            <FontAwesomeIcon icon={faSignOutAlt} className="cost-icon" />
            <span className="cost-value">All unsaved changes will be lost</span>
          </div>
        </div>

        <div className="confirm-buttons">
          <button 
            className={`confirm-button ${selectedOption === 'yes' ? 'selected' : ''}`}
            onClick={() => setSelectedOption('yes')}
          >
            YES
          </button>
          <button 
            className={`confirm-button ${selectedOption === 'no' ? 'selected' : ''}`}
            onClick={() => setSelectedOption('no')}
          >
            NO
          </button>
        </div>
      </div>
    </div>
  );
};

export default ConfirmExit;