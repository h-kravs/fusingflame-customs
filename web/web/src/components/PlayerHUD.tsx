import React, { useState, useEffect } from 'react';
import { useNuiEvent } from '../hooks/useNuiEvent';
import DollarHexagon from './DollarHexagon';

interface PlayerHUDProps {
  money?: number;
}

const PlayerHUD: React.FC<PlayerHUDProps> = ({
  money: initialMoney = 0
}) => {
  const [currentMoney, setCurrentMoney] = useState(initialMoney);

  // Listen for money updates from server
  useNuiEvent('updatePlayerMoney', (data: { money: number }) => {
    // console.log('💰 PlayerHUD received money update:', data.money);
    setCurrentMoney(data.money);
  });

  // Update money when prop changes (initial load)
  useEffect(() => {
    setCurrentMoney(initialMoney);
  }, [initialMoney]);

  return (
    <div className="player-hud">
      <div className="hud-block">
        <div className="money-rect">
          <DollarHexagon />
          <span>{currentMoney.toLocaleString()}</span>
        </div>
      </div>
    </div>
  );
};

export default PlayerHUD;