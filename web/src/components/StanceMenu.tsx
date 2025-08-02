import React, { useState, useEffect, useCallback } from 'react';
import './StanceMenu.css';
import { fetchNui } from '../utils/fetchNui';
import { useControllerInput } from '../hooks/useControllerInput';
import { useSounds } from '../hooks/useSounds';
import { useStance } from '../contexts/StanceContext';

interface StanceValues {
  height: number;
  offsetFront: number;
  offsetRear: number;
  camberFront: number | null;
  camberRear: number | null;
  wheelSize: number | null;
  wheelWidth: number | null;
}

interface StanceDefaults {
  height: number;
  offsetFront: number;
  offsetRear: number;
  camberFront: number | null;
  camberRear: number | null;
  wheelSize: number | null;
  wheelWidth: number | null;
}

interface StanceOption {
  id: string;
  label: string;
  value: number | null;
  defaultValue: number | null;
  range: number;
  invert?: boolean;
  canModify: boolean;
}

const StanceMenu: React.FC = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [lastInputTime, setLastInputTime] = useState(0);
  const [lastHorizontalInput, setLastHorizontalInput] = useState<{ key: string; time: number } | null>(null);
  const [stancePrice, setStancePrice] = useState(0);
  const [originalValues, setOriginalValues] = useState<StanceValues | null>(null);
  const { setStanceOpen } = useStance();
  const [stanceValues, setStanceValues] = useState<StanceValues>({
    height: 0,
    offsetFront: 0,
    offsetRear: 0,
    camberFront: null,
    camberRear: null,
    wheelSize: null,
    wheelWidth: null,
  });
  const [defaultValues, setDefaultValues] = useState<StanceDefaults>({
    height: 0,
    offsetFront: 0,
    offsetRear: 0,
    camberFront: null,
    camberRear: null,
    wheelSize: null,
    wheelWidth: null,
  });

  const { playNavigateSound, playSelectSound, playCancelSound } = useSounds();

  // Calculate stance price based on changes from original values
  const calculateStancePrice = useCallback((current: StanceValues, original: StanceValues | null) => {
    if (!original) return 0;
    
    let totalPrice = 0;
    const basePrice = 500; // Base price per modification
    
    // Check each stance value for changes
    if (Math.abs(current.height - original.height) > 0.01) totalPrice += basePrice;
    if (Math.abs(current.offsetFront - original.offsetFront) > 0.01) totalPrice += basePrice;
    if (Math.abs(current.offsetRear - original.offsetRear) > 0.01) totalPrice += basePrice;
    
    if (current.camberFront !== null && original.camberFront !== null) {
      if (Math.abs(current.camberFront - original.camberFront) > 0.01) totalPrice += basePrice;
    }
    if (current.camberRear !== null && original.camberRear !== null) {
      if (Math.abs(current.camberRear - original.camberRear) > 0.01) totalPrice += basePrice;
    }
    if (current.wheelSize !== null && original.wheelSize !== null) {
      if (Math.abs(current.wheelSize - original.wheelSize) > 0.01) totalPrice += basePrice;
    }
    if (current.wheelWidth !== null && original.wheelWidth !== null) {
      if (Math.abs(current.wheelWidth - original.wheelWidth) > 0.01) totalPrice += basePrice;
    }
    
    return totalPrice;
  }, []);

  const stanceOptions: StanceOption[] = [
    {
      id: 'height',
      label: 'Suspension Height',
      value: stanceValues.height,
      defaultValue: defaultValues.height,
      range: 0.7,
      invert: true,
      canModify: true,
    },
    {
      id: 'offsetFront',
      label: 'Front Track Width',
      value: stanceValues.offsetFront,
      defaultValue: defaultValues.offsetFront,
      range: 0.2,
      canModify: true,
    },
    {
      id: 'offsetRear',
      label: 'Rear Track Width',
      value: stanceValues.offsetRear,
      defaultValue: defaultValues.offsetRear,
      range: 0.2,
      canModify: true,
    },
    {
      id: 'camberFront',
      label: 'Front Camber',
      value: stanceValues.camberFront,
      defaultValue: defaultValues.camberFront,
      range: 1.5,
      canModify: stanceValues.camberFront !== null,
    },
    {
      id: 'camberRear',
      label: 'Rear Camber',
      value: stanceValues.camberRear,
      defaultValue: defaultValues.camberRear,
      range: 1.5,
      canModify: stanceValues.camberRear !== null,
    },
    {
      id: 'wheelSize',
      label: 'Wheel Size',
      value: stanceValues.wheelSize,
      defaultValue: defaultValues.wheelSize,
      range: 0.2,
      canModify: stanceValues.wheelSize !== null,
    },
    {
      id: 'wheelWidth',
      label: 'Wheel Width',
      value: stanceValues.wheelWidth,
      defaultValue: defaultValues.wheelWidth,
      range: 0.5,
      canModify: stanceValues.wheelWidth !== null,
    },
  ];

  // Filter out disabled options for navigation
  const availableOptions = stanceOptions.filter(option => option.canModify);
  const buttonsCount = 1; // Only Apply button
  const totalNavigableItems = availableOptions.length + buttonsCount;
  
  // Debug log
  useEffect(() => {
    if (isVisible) {
      console.log('🎛️ All stance options:');
      stanceOptions.forEach(o => {
        const status = o.canModify ? '✅ AVAILABLE' : '❌ HIDDEN';
        console.log(`  ${o.id}: ${status} (value: ${o.value})`);
      });
      // console.log('✅ Showing only:', availableOptions.map((o, i) => `${i}: ${o.id}`));
      // console.log('📊 Total navigable items:', totalNavigableItems);
      // console.log('🎯 Current selected index:', selectedIndex);
      // console.log('📐 UI Mode:', availableOptions.length > 5 ? 'EXTENDED (height: 520px, top: 45%)' : 'NORMAL (height: 400px, top: 49.5%)');
    }
  }, [isVisible, availableOptions.length, totalNavigableItems, selectedIndex, stanceOptions]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      if (action === 'openStanceMenu') {
        setIsVisible(true);
        setStanceOpen(true); // Notify context
        setSelectedIndex(0); // Start at first option
        
        // Ensure all values are properly set, use fallbacks for null values
        const currentValues = {
          height: data.currentValues?.height ?? 0,
          offsetFront: data.currentValues?.offsetFront ?? 0,
          offsetRear: data.currentValues?.offsetRear ?? 0,
          camberFront: data.currentValues?.camberFront ?? null,
          camberRear: data.currentValues?.camberRear ?? null,
          wheelSize: data.currentValues?.wheelSize ?? null,
          wheelWidth: data.currentValues?.wheelWidth ?? null,
        };
        
        setStanceValues(currentValues);
        setOriginalValues(currentValues); // Store original values for price calculation
        setStancePrice(0); // Start with no changes, no price
        
        setDefaultValues({
          height: data.defaultValues?.height ?? 0,
          offsetFront: data.defaultValues?.offsetFront ?? 0,
          offsetRear: data.defaultValues?.offsetRear ?? 0,
          camberFront: data.defaultValues?.camberFront ?? null,
          camberRear: data.defaultValues?.camberRear ?? null,
          wheelSize: data.defaultValues?.wheelSize ?? null,
          wheelWidth: data.defaultValues?.wheelWidth ?? null,
        });
      } else if (action === 'closeStanceMenu') {
        setIsVisible(false);
        setStanceOpen(false); // Notify context
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const handleSliderChange = useCallback((id: string, value: number) => {
    setStanceValues(prev => {
      const newValues = {
        ...prev,
        [id]: value,
      };
      
      // Calculate and update price based on changes from original values
      const newPrice = calculateStancePrice(newValues, originalValues);
      setStancePrice(newPrice);
      
      return newValues;
    });

    // Send update to game
    fetchNui('updateStanceValue', { type: id, value });
  }, [calculateStancePrice, originalValues]);


  const handleApply = useCallback(() => {
    fetchNui('applyStance', { values: stanceValues, price: stancePrice });
    setIsVisible(false);
    setStanceOpen(false); // Notify context
    playSelectSound();
  }, [stanceValues, stancePrice, playSelectSound, setStanceOpen]);

  const handleCancel = useCallback(() => {
    fetchNui('cancelStance', {});
    setIsVisible(false);
    setStanceOpen(false); // Notify context
    playCancelSound();
  }, [playCancelSound, setStanceOpen]);

  const calculateSliderValue = (current: number | null, defaultVal: number | null, range: number, invert?: boolean) => {
    if (current === null || current === undefined || defaultVal === null || defaultVal === undefined) return 50;
    
    const diff = current - defaultVal;
    const percentage = (diff / range) * 100;
    
    if (invert) {
      return 50 - percentage;
    }
    return 50 + percentage;
  };

  const calculateActualValue = (sliderValue: number, defaultVal: number | null, range: number, invert?: boolean) => {
    if (defaultVal === null || defaultVal === undefined) return 0;
    
    const percentage = (sliderValue - 50) / 100;
    
    if (invert) {
      return defaultVal - (percentage * range);
    }
    return defaultVal + (percentage * range);
  };

  const adjustValue = useCallback((direction: 'left' | 'right', isHolding = false, holdDuration = 0) => {
    if (selectedIndex >= availableOptions.length) return; // We're on buttons, not options
    
    const option = availableOptions[selectedIndex];
    if (!option.canModify || option.defaultValue === null) return;
    
    const currentSliderValue = calculateSliderValue(option.value, option.defaultValue, option.range, option.invert);
    
    // Progressive acceleration based on hold duration
    let step = 0.5; // Base step for single presses
    
    if (isHolding) {
      if (holdDuration < 1000) {
        step = 4.0; // Initial hold speed (8x faster)
      } else if (holdDuration < 2000) {
        step = 6.0; // After 1 second (12x faster)
      } else if (holdDuration < 3000) {
        step = 8.0; // After 2 seconds (16x faster)
      } else {
        step = 12.0; // After 3 seconds (24x faster - maximum speed)
      }
    }
    
    const newSliderValue = direction === 'right' 
      ? Math.min(100, currentSliderValue + step)
      : Math.max(0, currentSliderValue - step);
    
    const newActualValue = calculateActualValue(newSliderValue, option.defaultValue, option.range, option.invert);
    handleSliderChange(option.id, newActualValue);
  }, [selectedIndex, availableOptions, handleSliderChange]);

  // Keyboard/Gamepad navigation with additional debugging
  const pressedKey = useControllerInput(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Enter', 'Backspace'], isVisible);
  
  // Debug hook output
  useEffect(() => {
    if (pressedKey && isVisible) {
      console.log('🔥 [HOOK OUTPUT] pressedKey:', pressedKey, 'at time:', Date.now());
    }
  }, [pressedKey, isVisible]);

  useEffect(() => {
    if (!isVisible || !pressedKey) return;

    // Handle both string and object input formats
    const currentKey = typeof pressedKey === 'object' ? pressedKey.key : pressedKey;
    const holdDuration = typeof pressedKey === 'object' ? pressedKey.holdDuration : 0;

    // Local debouncing to prevent double processing
    const now = Date.now();
    if (now - lastInputTime < 150) {
      console.log('🚫 [DEBOUNCE] Input ignored - too fast:', currentKey);
      return;
    }
    setLastInputTime(now);

    console.log('🎮 [INPUT] Key pressed:', currentKey, 'holdDuration:', holdDuration, 'selectedIndex:', selectedIndex, 'totalItems:', totalNavigableItems);

    if (currentKey === 'ArrowUp') {
      playNavigateSound();
      setSelectedIndex(prev => {
        const newIndex = prev > 0 ? prev - 1 : totalNavigableItems - 1;
        console.log('🔼 Navigation UP: from', prev, 'to', newIndex);
        return newIndex;
      });
    } else if (currentKey === 'ArrowDown') {
      playNavigateSound();
      setSelectedIndex(prev => {
        const newIndex = (prev + 1) % totalNavigableItems;
        console.log('🔽 Navigation DOWN: from', prev, 'to', newIndex);
        return newIndex;
      });
    } else if (currentKey === 'ArrowLeft') {
      if (selectedIndex < availableOptions.length) {
        // Check if this is a hold action (same key within short time or has holdDuration)
        const isHolding = holdDuration > 0 || (lastHorizontalInput?.key === 'ArrowLeft' && (now - lastHorizontalInput.time) < 100);
        console.log('⬅️ Adjusting value LEFT for option index:', selectedIndex, isHolding ? `(HOLDING - ${holdDuration}ms)` : '(SINGLE)');
        playNavigateSound();
        adjustValue('left', isHolding, holdDuration);
        setLastHorizontalInput({ key: 'ArrowLeft', time: now });
      }
    } else if (currentKey === 'ArrowRight') {
      if (selectedIndex < availableOptions.length) {
        // Check if this is a hold action (same key within short time or has holdDuration)  
        const isHolding = holdDuration > 0 || (lastHorizontalInput?.key === 'ArrowRight' && (now - lastHorizontalInput.time) < 100);
        console.log('➡️ Adjusting value RIGHT for option index:', selectedIndex, isHolding ? `(HOLDING - ${holdDuration}ms)` : '(SINGLE)');
        playNavigateSound();
        adjustValue('right', isHolding, holdDuration);
        setLastHorizontalInput({ key: 'ArrowRight', time: now });
      }
    } else if (currentKey === 'Enter') {
      if (selectedIndex === availableOptions.length) {
        console.log('✅ Apply button pressed');
        handleApply();
      }
    } else if (currentKey === 'Backspace') {
      console.log('❌ Cancel pressed');
      handleCancel();
    }
  }, [pressedKey, isVisible, selectedIndex, availableOptions.length, totalNavigableItems, adjustValue, handleApply, handleCancel, playNavigateSound, lastInputTime, lastHorizontalInput]);

  if (!isVisible) return null;

  // Dynamic panel sizing based on number of available options
  const isExtended = availableOptions.length > 5;
  const panelClass = isExtended ? 'stance-panel stance-panel-extended' : 'stance-panel';

  return (
    <div className={panelClass}>
      <div className="stance-header">
        <div className="stance-title">
          <h1>TUNE STANCE</h1>
        </div>
      </div>

      <div className="stance-options">
        {stanceOptions.map((option, index) => {
          // Only show options that can be modified
          if (!option.canModify) return null;
          
          const availableIndex = availableOptions.findIndex(ao => ao.id === option.id);
          const isSelected = availableIndex !== -1 && selectedIndex === availableIndex;
          
          // Calculate bar percentage (0-100%)
          const barPercentage = option.value !== null && option.defaultValue !== null 
            ? calculateSliderValue(option.value, option.defaultValue, option.range, option.invert)
            : 50;
          
          return (
            <div key={option.id} className={`stance-row ${isSelected ? 'selected' : ''}`}>
              <span className="stance-label">{option.label}</span>
              <div className="stance-bar">
                <div className="stance-track">
                  <div className="stance-fill" style={{ left: `${barPercentage}%` }}></div>
                </div>
                <div className="stance-labels">
                  <span className="stance-label-less">LESS</span>
                  <span className="stance-label-more">MORE</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
      
      <div className="stance-apply-button">
        <button className={`stance-apply-btn ${selectedIndex === availableOptions.length ? 'selected' : ''}`}>
          Apply Changes {stancePrice > 0 ? `- $${stancePrice.toLocaleString()}` : '- FREE'}
        </button>
      </div>
    </div>
  );
};

export default StanceMenu;