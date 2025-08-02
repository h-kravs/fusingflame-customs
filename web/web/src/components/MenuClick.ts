import { fetchNui } from "../utils/fetchNui";
import { MenuProps, CardsContextProps, TargetMenuData } from "./type";

const handleClick = async (
  targetMenuData: TargetMenuData,
  menu: MenuProps,
  setMenuData: CardsContextProps['setMenuData'],
) => {
    const targetMenu = targetMenuData.mod
    const isBackButton = targetMenu === 'back'
    const card = menu.card
    if (isBackButton && card.previous === 'main') {
        if (card.current === 'main') fetchNui('hideFrame')
        else setMenuData({...menu, data: menu.defaultMenu, type: 'menu', card: {current: 'main', previous: 'main'}, currentMenu: 'main'})
        return
    } else {
        // Special handling for back button at main menu
        if (isBackButton && card.current === 'main') {
            // Don't process this in MenuClick, let MainContainer handle it
            return
        }
        const clickedCard = isBackButton ? card.previous : targetMenu
        // For engine sounds, we need to check if it has a price to determine if it's a purchase
        // Add safety checks for targetMenuData properties
        const isEngineSound = (targetMenuData && targetMenuData.price) && typeof targetMenu === 'string';
        const type = menu.mainMenus.includes(clickedCard) ? 'menu' : 
                     (['decals', 'horns', 'paint', 'wheels', 'stance'].includes(clickedCard)) ? 'submenu' :
                     (['decals', 'horns', 'paint', 'wheels'].includes(menu.currentMenu)) ? 'modType' :
                     (typeof targetMenu === 'number' || isEngineSound) ? 'modIndex' : 'modType'
        
        // console.log('🔍 [DEBUG] Navigation Debug:');
        // console.log('  - clickedCard:', clickedCard);
        // console.log('  - menu.currentMenu:', menu.currentMenu);
        // console.log('  - menu.mainMenus:', menu.mainMenus);
        // console.log('  - determined type:', type);
        // console.log('  - isBackButton:', isBackButton);
        if (type === 'modIndex') {
            // Add safety checks for targetMenuData
            if (!targetMenuData) {
                console.error('❌ targetMenuData is undefined for modIndex');
                return;
            }
            
            // // console.log('🎯 Processing modIndex purchase/toggle for:', clickedCard);
            const success = (targetMenuData.toggle) ? 
                fetchNui('toggleMod', { 
                    mod: clickedCard, 
                    price: targetMenuData.price || 0, 
                    toggle: !(targetMenuData.applied) 
                }) : 
                fetchNui('buyMod', { 
                    mod: clickedCard, 
                    price: targetMenuData.price || 0 
                });
                
            success.then(response => {
                // // console.log('📡 Server response for mod purchase:', response);
                if (!response) {
                    // // console.log('❌ Server returned false, not updating UI');
                    return;
                }
                // // console.log('✅ Server returned success, updating UI');
                const updatedData = menu.data.map(obj => ({ ...obj }));
                const targetIndex = updatedData.findIndex(obj => obj.id === targetMenu);

                if (targetIndex === -1) {
                    // // console.log('❌ Target index not found for:', targetMenu);
                    return;
                }

                if (targetMenuData && targetMenuData.toggle) {
                    updatedData[targetIndex].applied = !(targetMenuData.applied);
                } else {
                    updatedData.forEach(obj => { obj.applied = obj.id === targetMenu });
                }

                // // console.log('🔄 Updating menu data with new applied states');
                setMenuData({
                    ...menu,
                    data: updatedData,
                });
            }).catch(error => {
                // console.error('💥 Error in mod purchase:', error);
            });
            return
        }
        // Fixed navigation logic for 3-level navigation system
        let currentMenu, previousMenu;
        
        if (isBackButton) {
            // Going back - need to determine where we're going back to
            if (card.current === 'main') {
                // We're at main menu, going back should exit
                currentMenu = 'main';
                previousMenu = 'main';
            } else if (['decals', 'horns', 'paint', 'wheels'].includes(card.current)) {
                // We're in a submenu (level 3), going back to customization (level 2)
                currentMenu = 'customization';
                previousMenu = 'main';
            } else if (card.current === 'customization') {
                // We're in customization menu (level 2), going back to main (level 1)
                currentMenu = 'main';
                previousMenu = 'main';
            } else if (menu.mainMenus.includes(card.current)) {
                // We're in a main menu, going back to main
                currentMenu = 'main';
                previousMenu = 'main';
            } else {
                // Fallback - go back to previous menu
                currentMenu = card.previous;
                previousMenu = menu.mainMenus.includes(card.previous) ? 'main' : 
                    (['decals', 'horns', 'paint', 'wheels'].includes(card.previous)) ? 'customization' : 
                    card.previous;
            }
        } else {
            // Going forward - normal navigation
            if (type === 'menu' || type === 'submenu') {
                currentMenu = clickedCard;
            } else {
                currentMenu = menu.currentMenu;
            }
            previousMenu = card.current;
        }

        // console.log('📡 [DEBUG] Sending to backend:', { clickedCard: clickedCard, cardType: type, isBack: isBackButton, menuType: targetMenuData?.menuType });
        
        const data = await fetchNui<MenuProps['data']>('setMenu', { clickedCard: clickedCard, cardType: type, isBack: isBackButton, menuType: targetMenuData?.menuType })
        
        // console.log('📥 [DEBUG] Received from backend:', data);
        // console.log('📥 [DEBUG] Data type:', typeof data);
        
        if (typeof data === 'object') {
            // console.log('✅ [DEBUG] Updating menu data');
            // console.log('📊 [DEBUG] Data received:', data);
            // console.log('📊 [DEBUG] Data length:', data ? data.length : 0);
            if (data && data.length > 0) {
                // console.log('📊 [DEBUG] First 3 items:', data.slice(0, 3));
            }
            
            // Fix: When navigating back to main menu, ensure previous is also set to 'main'
            // This ensures the exit confirm dialog works properly after deep navigation
            
            // Check if we received main menu data (has preview, performance, customization, repair)
            const isMainMenuData = data && Array.isArray(data) && 
                data.some(item => item.id === 'preview') &&
                data.some(item => item.id === 'performance') &&
                data.some(item => item.id === 'customization');
            
            // Check if we received color types menu (has metallic, matte, etc.)
            const isColorTypesMenu = data && Array.isArray(data) && 
                data.some(item => ['Metallic', 'Matte', 'Metal', 'Chrome', 'Classic'].includes(item.id));
            
            let finalCurrentMenu, finalPreviousMenu;
            
            if (isMainMenuData) {
                // We're definitely at the main menu
                finalCurrentMenu = 'main';
                finalPreviousMenu = 'main';
            } else if (isColorTypesMenu) {
                // We're at the color types menu, NOT the main menu
                // This should be treated as being in the paint submenu
                finalCurrentMenu = clickedCard || 'paint';
                finalPreviousMenu = 'paint';
            } else {
                // Use the calculated values
                finalCurrentMenu = currentMenu;
                finalPreviousMenu = previousMenu;
            }
            
            setMenuData({...menu, type: type, card: {current: finalCurrentMenu, previous: finalPreviousMenu}, data: data, currentMenu: finalCurrentMenu, icon: targetMenuData?.icon})
        } else {
            // console.log('❌ [DEBUG] Invalid data received, not updating menu');
        }
    }
}

export default handleClick;
