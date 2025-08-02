import React, { useState, useEffect } from 'react';
import MainContainer from "./MainContainer";
import { CardsProvider } from "./CardsContext";
import { StanceProvider } from "../contexts/StanceContext";
import CameraHandle from "./CameraHandle";
import VehicleStats from "./VehicleStats";
import PlayerHUD from "./PlayerHUD";
import Footbar from "./Footbar";
import StanceMenu from "./StanceMenu";
import { fetchNui } from "../utils/fetchNui";

const Customs: React.FC = () => {
  const [playerMoney, setPlayerMoney] = useState(0);

  // Get initial player money when component mounts
  useEffect(() => {
    const getInitialMoney = async () => {
      try {
        const money = await fetchNui<number>('getPlayerMoney');
        // // console.log('💰 Initial player money:', money);
        setPlayerMoney(money || 0);
      } catch (error) {
        // console.error('Failed to get initial player money:', error);
      }
    };

    getInitialMoney();
  }, []);

  return (
    <StanceProvider>
      <CameraHandle />
      <PlayerHUD money={playerMoney} />
      <VehicleStats />
      <CardsProvider>
        <MainContainer />
      </CardsProvider>
      <Footbar />
      <StanceMenu />
    </StanceProvider>
  );
}

export default Customs;
