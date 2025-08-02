import React, { useState, useEffect } from 'react';

interface ActionItem {
  key: string;
  gamepadButton?: string;
  action: string;
}

const Footbar: React.FC = () => {
  const [hasGamepad, setHasGamepad] = useState(false);

  // Check for gamepad connection
  useEffect(() => {
    const checkGamepad = () => {
      const gamepads = navigator.getGamepads();
      const connectedGamepad = Array.from(gamepads).some(gamepad => gamepad !== null);
      setHasGamepad(connectedGamepad);
    };

    checkGamepad();
    const interval = setInterval(checkGamepad, 1000);

    return () => clearInterval(interval);
  }, []);

  const actions: ActionItem[] = [
    { key: '←→', gamepadButton: 'D-PAD', action: 'NAVIGATE' },
    { key: 'ENTER', gamepadButton: 'A', action: 'SELECT' },
    { key: 'BACKSPACE', gamepadButton: 'B', action: 'BACK' },
    { key: 'ESC', gamepadButton: 'B', action: 'EXIT' }
  ];

  return (
    <div className="footbar">
      <div className="footbar-content">
        {actions.map((item, index) => (
          <div key={index} className="action-pair">
            <span className="keycap">
              {hasGamepad && item.gamepadButton ? item.gamepadButton : item.key}
            </span>
            <span className="action-text">{item.action}</span>
          </div>
        ))}
        {hasGamepad && (
          <div className="action-pair">
            <span className="keycap">🎮</span>
            <span className="action-text">CONTROLLER</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default Footbar;