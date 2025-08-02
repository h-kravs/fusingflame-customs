import { MenuProps} from "./type";

const default_data = { type: 'menu', card: {current: 'main', previous: 'main'}, data: [
    {id: 'preview', selected: true, label: 'Preview', icon: 'car-side'},
    {id: 'customization', label: 'Customization', icon: 'paint-brush'},
    {id: 'performance', label: 'Performance', icon: 'screwdriver-wrench'},
], currentMenu: 'main', mainMenus: [], submenuMenus: [], colorMenus: [], defaultMenu: []} as MenuProps

export default default_data