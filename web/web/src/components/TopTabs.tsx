import React, { useState } from 'react';

interface TabItem {
  key: string;
  label: string;
  hotkey: string;
}

const TopTabs: React.FC = () => {
  const [activeTab, setActiveTab] = useState('MY RIDE');
  
  const tabs: TabItem[] = [
    { key: 'SHOWCASE', label: 'SHOWCASE', hotkey: '1' },
    { key: 'MY RIDE', label: 'MY RIDE', hotkey: '2' },
    { key: 'CHARACTER', label: 'CHARACTER', hotkey: '3' },
    { key: 'RACER CHALLENGES', label: 'RACER CHALLENGES', hotkey: '4' }
  ];

  return (
    <div className="top-tabs">
      {tabs.map((tab) => (
        <div 
          key={tab.key}
          className={`tab-item ${activeTab === tab.key ? 'active' : ''}`}
          onClick={() => setActiveTab(tab.key)}
        >
          <span className="tab-hotkey">{tab.hotkey}</span>
          <span className="tab-label">{tab.label}</span>
        </div>
      ))}
    </div>
  );
};

export default TopTabs;