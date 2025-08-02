import React, { useContext, useMemo, useEffect, useState } from "react";
import CardsContext from "./CardsContext";
import handleClick from "./MenuClick";
import Card from "./Card";
import useControllerInput from "../hooks/useControllerInput";
import useSounds from "../hooks/useSounds";
import { fetchNui } from "../utils/fetchNui";
import { TargetMenuData } from "./type";
import ConfirmPurchase from "./ConfirmPurchase";
import ConfirmExit from "./ConfirmExit";
import { useVisibility } from "../providers/VisibilityProvider";
import { useStance } from "../contexts/StanceContext";

const upperCase = (text: string | undefined | null) => {
  if (!text || typeof text !== 'string' || text.length === 0) return 'Unknown';
  return text[0].toUpperCase() + text.slice(1);
};

const MainContainer: React.FC = () => {
  const { setMenuData, menu } = useContext(CardsContext);
  const { playNavigateSound, playSelectSound, playCancelSound } = useSounds();
  const { isStanceOpen } = useStance();
  const { visible } = useVisibility();

  const [selected, setSelected] = useState<TargetMenuData>({ mod: "" });
  const [cardsCount, setCardsCount] = useState<{
    total: number;
    current: number;
  }>({ total: 0, current: 0 });
  const [showConfirm, setShowConfirm] = useState(false);
  const [pendingPurchase, setPendingPurchase] = useState<TargetMenuData | null>(null);
  const [showExitConfirm, setShowExitConfirm] = useState(false);
  const [dialogJustClosed, setDialogJustClosed] = useState(false);
  
  // Only enable input when UI is visible and confirmation dialogs are NOT open and no dialog just closed and stance is NOT open
  const inputPress = useControllerInput(["ArrowRight", "ArrowLeft", "Enter", "Backspace"], 
    visible && !showConfirm && !showExitConfirm && !dialogJustClosed && !isStanceOpen);

  // Debug effect to monitor showConfirm changes
  useEffect(() => {
    // // console.log('🔄 showConfirm state changed to:', showConfirm);
  }, [showConfirm]);

  useEffect(() => {
    // // console.log('📦 pendingPurchase state changed to:', pendingPurchase);
  }, [pendingPurchase]);

  const handleConfirmPurchase = () => {
    if (pendingPurchase) {
      // console.log('🛒 [PURCHASE] handleConfirmPurchase called, preventing Enter re-detection');
      playSelectSound(); // Play success sound on purchase
      
      // Directly make the purchase without navigating
      const success = (pendingPurchase.toggle) ? 
        fetchNui('toggleMod', { 
          mod: pendingPurchase.mod, 
          price: pendingPurchase.price || 0, 
          toggle: !(pendingPurchase.applied) 
        }) : 
        fetchNui('buyMod', { 
          mod: pendingPurchase.mod, 
          price: pendingPurchase.price || 0 
        });
        
      success.then(response => {
        if (!response) {
          // console.log('❌ Server returned false, not updating UI');
          return;
        }
        
        // Update UI to reflect the purchase
        const updatedData = menu.data.map(obj => ({ ...obj }));
        const targetIndex = updatedData.findIndex(obj => obj.id === pendingPurchase.mod);

        if (targetIndex !== -1) {
          if (pendingPurchase.toggle) {
            updatedData[targetIndex].applied = !(pendingPurchase.applied);
          } else {
            updatedData.forEach(obj => { obj.applied = obj.id === pendingPurchase.mod });
          }

          setMenuData({
            ...menu,
            data: updatedData,
          });
        }
      }).catch(error => {
        console.error('💥 Error in purchase confirmation:', error);
      });
      
      setShowConfirm(false);
      setPendingPurchase(null);
      
      // Prevent Enter key re-detection after purchase for extra time
      setDialogJustClosed(true);
      setTimeout(() => {
        // console.log('🕒 [TIMER] Purchase confirmation cooldown expired');
        setDialogJustClosed(false);
      }, 500);
    }
  };

  const handleCancelPurchase = () => {
    playCancelSound(); // Play cancel sound on purchase cancel
    setShowConfirm(false);
    setPendingPurchase(null);
    
    // Prevent immediate re-detection of input for 500ms (increased)
    setDialogJustClosed(true);
    setTimeout(() => {
      // console.log('🕒 [TIMER] Purchase dialog cooldown expired, re-enabling input');
      setDialogJustClosed(false);
    }, 500);
  };

  const handleConfirmExit = () => {
    // console.log('🔥 [FUNC] handleConfirmExit called - YES selected');
    playSelectSound();
    setShowExitConfirm(false);
    fetchNui('hideFrame');
  };

  const handleCancelExit = () => {
    // console.log('🔥 [FUNC] handleCancelExit called - NO selected');
    playCancelSound();
    setShowExitConfirm(false);
    
    // Prevent immediate re-detection of input for 500ms (increased)
    setDialogJustClosed(true);
    setTimeout(() => {
      // console.log('🕒 [TIMER] Dialog cooldown expired, re-enabling input');
      setDialogJustClosed(false);
    }, 500);
  };

  // Separate ESC key handler with full event control
  useEffect(() => {
    const handleEscapeKey = (event: KeyboardEvent) => {
      // Only handle ESC when UI is visible and no dialogs are open
      if (!visible || showConfirm || showExitConfirm) {
        return;
      }
      
      if (event.key === 'Escape') {
        // // console.log('🔥 ESC intercepted by dedicated handler');
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        
        if (!showExitConfirm) {
          // console.log('🔥 [INPUT] ESC pressed, opening exit dialog');
          playNavigateSound();
          setShowExitConfirm(true);
        }
      }
    };

    // Add event listener with capture=true to intercept before other handlers
    window.addEventListener('keydown', handleEscapeKey, true);
    
    return () => {
      window.removeEventListener('keydown', handleEscapeKey, true);
    };
  }, [visible, showConfirm, showExitConfirm, playNavigateSound]);

  // Debug state changes
  useEffect(() => {
    // console.log('🔥 [STATE] showExitConfirm changed to:', showExitConfirm);
  }, [showExitConfirm]);

  useEffect(() => {
    // console.log('🚫 [STATE] dialogJustClosed changed to:', dialogJustClosed);
  }, [dialogJustClosed]);


  useEffect(() => {
    // console.log('👻 [PHANTOM CHECK] Input detected:', inputPress, 'Type:', typeof inputPress, 'Boolean value:', !!inputPress);
    // console.log('📊 Current selected:', selected);
    // console.log('👀 ShowConfirm state:', showConfirm);
    
    // Don't process any inputs if confirmation dialogs are open or just closed
    if (showConfirm || showExitConfirm || dialogJustClosed) {
      // console.log('🚫 [IGNORE] Input ignored - showConfirm:', showConfirm, 'showExitConfirm:', showExitConfirm, 'dialogJustClosed:', dialogJustClosed);
      return;
    }
    
    // Check for phantom input - if inputPress is truthy but not a real input
    if (!inputPress) {
      // console.log('⚪ [NO INPUT] inputPress is falsy, returning');
      return;
    }
    
    // console.log('🔍 [PROCESSING] About to process input:', inputPress);
    
    if (inputPress == "Backspace") {
      // // console.log('⬅️ Processing BACKSPACE');
      
      // Check if we're in the main menu - if so, show exit confirmation
      if (menu.card.current === 'main' && !showExitConfirm && !dialogJustClosed) {
        // console.log('🔥 [INPUT] Backspace pressed in main menu, opening exit dialog');
        playNavigateSound();
        setShowExitConfirm(true);
        return;
      }
      
      playCancelSound(); // Play back/cancel sound
      handleClick({ mod: "back" }, menu, setMenuData);
    }
    else if (inputPress == "Enter" && selected.mod !== "") {
      // // console.log('⚡ ENTER pressed with conditions met');
      
      // Check if this is a purchasable item (has price, not applied, and is a mod)
      // Exclude repair from purchasable items as it should be handled as direct action
      const hasPrice = selected.price && selected.price > 0;
      const notApplied = !selected.applied;
      const isModNumber = typeof selected.mod === 'number';
      const isModString = typeof selected.mod === 'string'; // Engine sounds use strings
      const isRepair = selected.mod === 'repair';
      const isPreview = selected.mod === 'preview';
      
      // // console.log('💰 Has price:', hasPrice, '(price:', selected.price, ')');
      // // console.log('❌ Not applied:', notApplied, '(applied:', selected.applied, ')');
      // // console.log('🔢 Is mod number:', isModNumber, '(mod:', selected.mod, ')');
      // // console.log('🔤 Is mod string:', isModString, '(mod:', selected.mod, ')');
      // // console.log('🔧 Is repair:', isRepair);
      // // console.log('👁️ Is preview:', isPreview);
      
      const isPurchasableItem = hasPrice && notApplied && (isModNumber || isModString) && !isRepair && !isPreview;
      // // console.log('🛒 Is purchasable item:', isPurchasableItem);
      
      if (isPurchasableItem) {
        // // console.log('🚨 SHOWING CONFIRMATION DIALOG');
        // // console.log('🚨 Setting pendingPurchase to:', selected);
        playNavigateSound(); // Play navigation sound for confirmation dialog
        setPendingPurchase(selected);
        // // console.log('🚨 Setting showConfirm to true');
        setShowConfirm(true);
        // // console.log('🚨 Confirmation setup complete, returning');
        return; // Prevent further execution
      } else {
        // // console.log('✅ Processing normally (free/applied/navigation)');
        playSelectSound(); // Play select sound for normal actions
        handleClick(selected, menu, setMenuData);
      }
    }
    else if (inputPress == "ArrowRight" || inputPress == "ArrowLeft") {
      playNavigateSound(); // Play navigation sound for left/right movement
      const updatedData = [...menu.data];
      const foundSelected = menu.data.find((obj) => obj.selected === true);
      const selectedIndex = foundSelected ? menu.data.indexOf(foundSelected) : 0;
      let nextIndex = inputPress === "ArrowRight" ? (selectedIndex + 1) % menu.data.length : (selectedIndex - 1 + menu.data.length) % menu.data.length;
      while (updatedData[nextIndex]?.hide) {
          nextIndex = (nextIndex + (inputPress === "ArrowRight" ? 1 : -1) + menu.data.length) % menu.data.length;
      }
      let nextObject = updatedData[nextIndex];
      const isToggle = nextObject.toggle;

      updatedData[selectedIndex].selected = false;
      nextObject.selected = true;

      if (typeof nextObject.id === "number" && !isToggle)
        fetchNui("applyMod", nextObject.id);
      setMenuData({ ...menu, data: updatedData });
    }
  }, [inputPress, playNavigateSound, playSelectSound, playCancelSound, showConfirm, showExitConfirm, dialogJustClosed]);

  useEffect(() => {
    if (menu.data.length <= 0) return;
    const updatedData = [...menu.data];
    const selectedData = updatedData.find((obj) => obj.selected === true);
  
    if (!selectedData || selectedData.hide) {
      const index = updatedData.findIndex(obj => !obj.hide);
      if (index !== -1) {
        updatedData.forEach((obj, index) => {
          updatedData[index] = { ...obj, selected: false };
        });
        updatedData[index] = { ...updatedData[index], selected: true };
        setMenuData(prevMenu => ({ ...prevMenu, data: updatedData }));
        return;
      }
    }
  
    if (selectedData) {
      setSelected({
        mod: selectedData.id,
        price: selectedData.price,
        toggle: selectedData.toggle,
        applied: selectedData.applied,
        icon: selectedData.icon,
        menuType: selectedData.menuType,
      });
    }
  }, [menu, setMenuData, setSelected]);

  const RenderCards = useMemo(() => {
    const hiddenItemsCount = menu.data.filter(value => value.hide).length;

    return menu.data.map((value, index) => {
      if (!value.hide) {
        // Better validation for label - ensure it's always a string
        let label = '';
        if (value.label && typeof value.label === 'string') {
          label = value.label;
        } else if (value.id !== undefined && value.id !== null) {
          label = String(value.id);
        } else {
          label = 'Unknown';
        }

        if (value.selected) {
          setCardsCount({ total: menu.data.length - hiddenItemsCount, current: (index - hiddenItemsCount) + 1 });
        }

        return (
          <Card
            key={index}
            icon={value.icon || menu.icon || "car"}
            text={upperCase(label)}
            selected={value.selected}
            price={value.price || undefined}
            applied={value.applied || undefined}
          />
        );
      }
    });
  }, [menu]);

  return (
    <>
      <div className="customs-wrapper">
        <div className="cards-swapper">
          {upperCase(menu.card.current || 'main')}
          <p className="cards-count">
            {cardsCount.current}/{cardsCount.total}
          </p>
        </div>
        <div className="cards-wrapper">
          <div className="flexbox">{RenderCards}</div>
        </div>
      </div>
      <ConfirmPurchase 
        isVisible={showConfirm}
        price={pendingPurchase?.price || 0}
        onConfirm={handleConfirmPurchase}
        onCancel={handleCancelPurchase}
      />
      <ConfirmExit 
        isVisible={showExitConfirm}
        onConfirm={handleConfirmExit}
        onCancel={handleCancelExit}
      />
    </>
  );
};

export default MainContainer;
