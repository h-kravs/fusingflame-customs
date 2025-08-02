import { useEffect, useCallback, useState } from 'react';

interface InputMapping {
  key: string;
  gamepadButton?: number;
  gamepadAxis?: { axis: number; direction: 'positive' | 'negative' };
}

const INPUT_MAPPINGS: Record<string, InputMapping> = {
  'ArrowLeft': { 
    key: 'ArrowLeft', 
    gamepadButton: 14, // D-pad left
    gamepadAxis: { axis: 0, direction: 'negative' } // Left stick left
  },
  'ArrowRight': { 
    key: 'ArrowRight', 
    gamepadButton: 15, // D-pad right
    gamepadAxis: { axis: 0, direction: 'positive' } // Left stick right
  },
  'ArrowUp': { 
    key: 'ArrowUp', 
    gamepadButton: 12, // D-pad up
    gamepadAxis: { axis: 1, direction: 'negative' } // Left stick up
  },
  'ArrowDown': { 
    key: 'ArrowDown', 
    gamepadButton: 13, // D-pad down
    gamepadAxis: { axis: 1, direction: 'positive' } // Left stick down
  },
  'Enter': { 
    key: 'Enter', 
    gamepadButton: 0 // A button (Xbox) / X button (PS)
  },
  'Escape': { 
    key: 'Escape', 
    gamepadButton: 1 // B button (Xbox) / Circle button (PS)
  },
  'Backspace': { 
    key: 'Backspace', 
    gamepadButton: 1 // B button (Xbox) / Circle button (PS)
  }
};

export const useControllerInput = (
  targetInputs: string | Array<string>, 
  enabled: boolean = true
) => {
  const [inputPressed, setInputPressed] = useState<boolean | string | { key: string; holdDuration: number }>(false);
  const [lastGamepadState, setLastGamepadState] = useState<Record<number, boolean>>({});
  const [lastAxisState, setLastAxisState] = useState<Record<string, number>>({});
  const [lastInputTime, setLastInputTime] = useState<number>(0);
  const [holdStartTime, setHoldStartTime] = useState<number>(0);
  const [currentHoldKey, setCurrentHoldKey] = useState<string | null>(null);

  // Keyboard handler with hold detection
  const keyDownHandler = useCallback(
    (event: KeyboardEvent) => {
      if (!enabled) return; // Don't process if disabled
      
      const inputs = Array.isArray(targetInputs) ? targetInputs : [targetInputs];
      const pressedInput = inputs.find(input => INPUT_MAPPINGS[input]?.key === event.key);
      
      if (pressedInput) {
        const now = Date.now();
        
        // Check if this is a new key press or continuing hold
        if (currentHoldKey !== pressedInput) {
          // New key press
          setCurrentHoldKey(pressedInput);
          setHoldStartTime(now);
          setInputPressed(pressedInput);
          setLastInputTime(now);
          event.preventDefault();
        } else {
          // Key is being held - check if enough time has passed for rapid adjustment
          const holdDuration = now - holdStartTime;
          const timeSinceLastInput = now - lastInputTime;
          
          // Start rapid adjustment after 300ms hold, then fire every 30ms
          if (holdDuration > 300 && timeSinceLastInput > 30) {
            setInputPressed({ key: pressedInput, holdDuration });
            setLastInputTime(now);
            event.preventDefault();
          }
        }
      }
    },
    [targetInputs, enabled, lastInputTime, currentHoldKey, holdStartTime]
  );

  const keyUpHandler = useCallback(
    (event: KeyboardEvent) => {
      if (!enabled) return; // Don't process if disabled
      
      const inputs = Array.isArray(targetInputs) ? targetInputs : [targetInputs];
      const releasedInput = inputs.find(input => INPUT_MAPPINGS[input]?.key === event.key);
      
      if (releasedInput && currentHoldKey === releasedInput) {
        setInputPressed(false);
        setCurrentHoldKey(null);
        setHoldStartTime(0);
      }
    },
    [targetInputs, enabled, currentHoldKey]
  );

  // Gamepad polling with hold detection
  const pollGamepad = useCallback(() => {
    if (!enabled) return; // Don't process if disabled
    
    const gamepads = navigator.getGamepads();
    const gamepad = gamepads[0]; // Use first connected gamepad
    
    if (!gamepad) return;

    const now = Date.now();
    const inputs = Array.isArray(targetInputs) ? targetInputs : [targetInputs];
    
    for (const input of inputs) {
      const mapping = INPUT_MAPPINGS[input];
      if (!mapping) continue;

      // Check buttons
      if (mapping.gamepadButton !== undefined) {
        const button = gamepad.buttons[mapping.gamepadButton];
        const isPressed = button && button.pressed;
        const wasPressed = lastGamepadState[mapping.gamepadButton];
        
        if (isPressed) {
          if (!wasPressed) {
            // New button press
            setCurrentHoldKey(input);
            setHoldStartTime(now);
            setInputPressed(input);
            setLastInputTime(now);
            setLastGamepadState(prev => ({ ...prev, [mapping.gamepadButton!]: true }));
            return;
          } else if (currentHoldKey === input) {
            // Button is being held
            const holdDuration = now - holdStartTime;
            const timeSinceLastInput = now - lastInputTime;
            
            // Start rapid adjustment after 300ms hold, then fire every 50ms
            if (holdDuration > 300 && timeSinceLastInput > 50) {
              setInputPressed({ key: input, holdDuration });
              setLastInputTime(now);
              return;
            }
          }
        } else if (!isPressed && wasPressed) {
          // Button released
          if (currentHoldKey === input) {
            setInputPressed(false);
            setCurrentHoldKey(null);
            setHoldStartTime(0);
          }
          setLastGamepadState(prev => ({ ...prev, [mapping.gamepadButton!]: false }));
        }
      }

      // Check axes (for analog sticks)
      if (mapping.gamepadAxis) {
        const { axis, direction } = mapping.gamepadAxis;
        const axisValue = gamepad.axes[axis];
        const threshold = 0.5;
        const axisKey = `${axis}_${direction}`;
        
        const isPressed = direction === 'positive' ? axisValue > threshold : axisValue < -threshold;
        const wasPressed = lastAxisState[axisKey] > threshold || lastAxisState[axisKey] < -threshold;
        
        if (isPressed) {
          if (!wasPressed) {
            // New axis press
            setCurrentHoldKey(input);
            setHoldStartTime(now);
            setInputPressed(input);
            setLastInputTime(now);
            setLastAxisState(prev => ({ ...prev, [axisKey]: axisValue }));
            return;
          } else if (currentHoldKey === input) {
            // Axis is being held
            const holdDuration = now - holdStartTime;
            const timeSinceLastInput = now - lastInputTime;
            
            // Start rapid adjustment after 300ms hold, then fire every 50ms
            if (holdDuration > 300 && timeSinceLastInput > 50) {
              setInputPressed({ key: input, holdDuration });
              setLastInputTime(now);
              return;
            }
          }
        } else if (!isPressed && wasPressed) {
          // Axis released
          if (currentHoldKey === input) {
            setInputPressed(false);
            setCurrentHoldKey(null);
            setHoldStartTime(0);
          }
          setLastAxisState(prev => ({ ...prev, [axisKey]: axisValue }));
        }
      }
    }
  }, [targetInputs, lastGamepadState, lastAxisState, enabled, lastInputTime, currentHoldKey, holdStartTime]);

  // Set up event listeners and gamepad polling
  useEffect(() => {
    // Keyboard events
    window.addEventListener('keydown', keyDownHandler);
    window.addEventListener('keyup', keyUpHandler);

    // Gamepad polling - increased from 50ms to 100ms to reduce rapid polling
    const gamepadInterval = setInterval(pollGamepad, 100); // Poll every 100ms

    return () => {
      window.removeEventListener('keydown', keyDownHandler);
      window.removeEventListener('keyup', keyUpHandler);
      clearInterval(gamepadInterval);
    };
  }, [keyDownHandler, keyUpHandler, pollGamepad]);

  // Debug log every time inputPressed changes
  useEffect(() => {
    if (inputPressed) {
      // console.log('🔥 [INPUT STATE] inputPressed changed to:', inputPressed, 'enabled:', enabled);
    }
  }, [inputPressed, enabled]);

  // Clear inputPressed and hold state when disabled to prevent phantom inputs
  useEffect(() => {
    if (!enabled && (inputPressed || currentHoldKey)) {
      // console.log('🧹 [CLEANUP] Clearing inputPressed and hold state because disabled');
      setInputPressed(false);
      setCurrentHoldKey(null);
      setHoldStartTime(0);
    }
  }, [enabled, inputPressed, currentHoldKey]);

  return inputPressed;
};

export default useControllerInput;