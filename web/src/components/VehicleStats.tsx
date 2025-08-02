import React, { useState, useEffect } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCar, faCog, faFlag, faRoad, faMountain, faCarSide } from '@fortawesome/free-solid-svg-icons';
import { fetchNui } from '../utils/fetchNui';
import { useNuiEvent } from '../hooks/useNuiEvent';

interface VehicleStatsData {
  vehicleModel: string;
  speed: number;
  acceleration: number;
  braking: number;
  handling: number;
}

interface VehicleStatsProps {
  vehicleData?: VehicleStatsData;
}

const VehicleStats: React.FC<VehicleStatsProps> = ({
  vehicleData
}) => {
  const [stats, setStats] = useState<VehicleStatsData>({
    vehicleModel: "Loading...",
    speed: 0,
    acceleration: 0,
    braking: 0,
    handling: 0
  });

  // Get initial vehicle stats when component mounts
  useEffect(() => {
    const getInitialStats = async () => {
      try {
        const vehicleStats = await fetchNui<VehicleStatsData>('getVehicleStats');
        // // console.log('🚗 Initial vehicle stats:', vehicleStats);
        if (vehicleStats) {
          setStats(vehicleStats);
        }
      } catch (error) {
        // console.error('Failed to get initial vehicle stats:', error);
      }
    };

    getInitialStats();
  }, []);

  // Listen for vehicle stats updates
  useNuiEvent<VehicleStatsData>('updateVehicleStats', (data) => {
    // // console.log('🚗 Vehicle stats updated:', data);
    setStats(data);
  });

  // Use provided data if available, otherwise use state
  const currentStats = vehicleData || stats;
  const StatBar: React.FC<{ value: number; max?: number }> = ({ value, max = 5 }) => {
    const percentage = (value / max) * 100;
    return (
      <div className="stat-bar">
        <div className="stat-track">
          <div className="stat-fill" style={{ width: `${percentage}%` }}></div>
        </div>
        <div className="stat-value">
          <span>{value.toFixed(1)}</span>
        </div>
      </div>
    );
  };

  return (
    <div className="vehicle-stats-panel">
      <div className="stats-header">
        <div className="brand-info">
          <h1 className="brand-name">{currentStats.vehicleModel}</h1>
        </div>
      </div>

      <div className="performance-stats">
        <div className="stat-row">
          <span className="stat-label">SPEED</span>
          <StatBar value={currentStats.speed} />
        </div>
        <div className="stat-row">
          <span className="stat-label">ACCELERATION</span>
          <StatBar value={currentStats.acceleration} />
        </div>
        <div className="stat-row">
          <span className="stat-label">BRAKING</span>
          <StatBar value={currentStats.braking} />
        </div>
        <div className="stat-row">
          <span className="stat-label">HANDLING</span>
          <StatBar value={currentStats.handling} />
        </div>
      </div>
    </div>
  );
};

export default VehicleStats;