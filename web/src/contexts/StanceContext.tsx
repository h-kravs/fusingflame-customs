import React, { createContext, useContext, useState, ReactNode } from 'react';

interface StanceContextType {
  isStanceOpen: boolean;
  setStanceOpen: (open: boolean) => void;
}

const StanceContext = createContext<StanceContextType | undefined>(undefined);

export const StanceProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isStanceOpen, setIsStanceOpen] = useState(false);

  const setStanceOpen = (open: boolean) => {
    console.log('🎛️ [STANCE CONTEXT] Setting stance open:', open);
    setIsStanceOpen(open);
  };

  return (
    <StanceContext.Provider value={{ isStanceOpen, setStanceOpen }}>
      {children}
    </StanceContext.Provider>
  );
};

export const useStance = () => {
  const context = useContext(StanceContext);
  if (context === undefined) {
    throw new Error('useStance must be used within a StanceProvider');
  }
  return context;
};