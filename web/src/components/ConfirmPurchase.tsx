import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faDollarSign } from '@fortawesome/free-solid-svg-icons';
import useSounds from '../hooks/useSounds';
// REMOVED: import useControllerInput from '../hooks/useControllerInput';

interface ConfirmPurchaseProps {
  isVisible: boolean;
  price: number;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmPurchase: React.FC<ConfirmPurchaseProps> = ({
  isVisible,
  price,
  onConfirm,
  onCancel
}) => {
  const [selectedOption, setSelectedOption] = useState<'yes' | 'no'>('yes');
  const [animationState, setAnimationState] = useState<'entering' | 'visible' | 'exiting' | 'hidden'>('hidden');
  const { playNavigateSound, playSelectSound, playCancelSound } = useSounds();
  
  // REMOVED: Multiple useControllerInput instances causing conflicts
  // const inputPress = useControllerInput(["ArrowRight", "ArrowLeft", "Enter", "Escape", "Backspace"], 
  //   isVisible && animationState === 'visible');

  // Handle animation states based on visibility - separate effects to avoid cleanup conflicts
  useEffect(() => {
    if (isVisible) {
      setAnimationState('entering');
      
      const timer = setTimeout(() => {
        setAnimationState('visible');
      }, 200); // Reduced from 400ms to 200ms
      
      return () => clearTimeout(timer);
    }
  }, [isVisible]);

  useEffect(() => {
    if (!isVisible) {
      if (animationState === 'visible' || animationState === 'entering') {
        setAnimationState('exiting');
        
        const timer = setTimeout(() => {
          setAnimationState('hidden');
        }, 150); // Reduced from 300ms to 150ms
        
        return () => clearTimeout(timer);
      }
    }
  }, [isVisible, animationState]);

  // Handle controller input using the hook
  useEffect(() => {
    if (!isVisible || animationState !== 'visible') return;
    
    setSelectedOption('yes'); // Reset to YES when opening
  }, [isVisible, animationState]);

  // Handle keyboard/gamepad input with direct event listeners to avoid conflicts
  useEffect(() => {
    if (!isVisible || animationState !== 'visible') return;

    const handleKeyInput = (event: KeyboardEvent) => {
      // console.log('💰 [ConfirmPurchase] Direct keyboard input detected:', event.key);
      
      if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
        // console.log('💰 [ConfirmPurchase] Navigation input - changing selection');
        event.preventDefault();
        playNavigateSound();
        setSelectedOption(prev => {
          const newSelection = prev === 'yes' ? 'no' : 'yes';
          // console.log('💰 [ConfirmPurchase] Selection changed from', prev, 'to', newSelection);
          return newSelection;
        });
      } else if (event.key === 'Enter') {
        // console.log('💰 [ConfirmPurchase] Enter pressed - current selection:', selectedOption);
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        // console.log('🛑 [ConfirmPurchase] Enter event fully prevented and stopped');
        
        if (selectedOption === 'yes') {
          // console.log('💰 [ConfirmPurchase] Confirming purchase');
          playSelectSound();
          onConfirm();
        } else {
          // console.log('💰 [ConfirmPurchase] Canceling purchase');
          playCancelSound();
          onCancel();
        }
      } else if (event.key === 'Escape' || event.key === 'Backspace') {
        // console.log('💰 [ConfirmPurchase] Escape/Backspace pressed - canceling');
        event.preventDefault();
        playCancelSound();
        onCancel();
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

      // B button (button 1) - for cancel
      const bPressed = gamepad.buttons[1]?.pressed;
      const wasBPressed = lastGamepadState[1];

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
        // console.log('💰 [ConfirmPurchase] Gamepad navigation - changing selection');
        playNavigateSound();
        setSelectedOption(prev => {
          const newSelection = prev === 'yes' ? 'no' : 'yes';
          // console.log('💰 [ConfirmPurchase] Selection changed from', prev, 'to', newSelection);
          return newSelection;
        });
      } else if (aPressed && !wasAPressed) {
        // console.log('💰 [ConfirmPurchase] Gamepad A pressed - current selection:', selectedOption);
        if (selectedOption === 'yes') {
          // console.log('💰 [ConfirmPurchase] Confirming purchase');
          playSelectSound();
          onConfirm();
        } else {
          // console.log('💰 [ConfirmPurchase] Canceling purchase');
          playCancelSound();
          onCancel();
        }
      } else if (bPressed && !wasBPressed) {
        // console.log('💰 [ConfirmPurchase] Gamepad B pressed - canceling');
        playCancelSound();
        onCancel();
      }

      // Update last state
      lastGamepadState = {
        12: upPressed,
        13: downPressed,
        0: aPressed,
        1: bPressed
      };
      
      lastAxisState = {
        '1_up': axisValue,
        '1_down': axisValue
      };
    };

    // Add event listener with highest priority to capture before MainContainer
    window.addEventListener('keydown', handleKeyInput, { capture: true, passive: false });
    
    // Start gamepad polling
    const gamepadInterval = setInterval(pollGamepadForDialog, 100);
    
    return () => {
      window.removeEventListener('keydown', handleKeyInput, { capture: true });
      clearInterval(gamepadInterval);
    };
  }, [isVisible, animationState, selectedOption, onConfirm, onCancel, playNavigateSound, playSelectSound, playCancelSound]);

  // Debug logs for ConfirmPurchase
  useEffect(() => {
    // console.log('💰 [ConfirmPurchase] Visibility changed:', isVisible, 'price:', price, 'animationState:', animationState);
  }, [isVisible, price, animationState]);

  useEffect(() => {
    // console.log('💰 [ConfirmPurchase] Selected option changed to:', selectedOption);
  }, [selectedOption]);

  if (animationState === 'hidden') {
    // // console.log('💬 ConfirmPurchase returning null - hidden');
    return null;
  }
  
  // // console.log('💬 ConfirmPurchase rendering UI with price:', price);

  return (
    <div className="confirm-center-wrapper">
      <div className={`confirm-purchase-container ${animationState}`}>
        <h1 className="confirm-title">BUY AND EQUIP</h1>
        
        <div className="confirm-cost">
          <span className="cost-label">COST:</span>
          <div className="cost-amount">
            <FontAwesomeIcon icon={faDollarSign} className="cost-icon" />
            <span className="cost-value">{price.toLocaleString()}</span>
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

export default ConfirmPurchase;