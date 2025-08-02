-- Stance modification data
-- Based on az-stancekit functionality

return {
    ['Height'] = {
        label = 'Suspension Height',
        modType = 'stance_height',
        icon = 'performance.png',
        isStance = true,
        stanceType = 'height',
        range = 0.7, -- Range for adjustment
        invert = true, -- Lower values = lower suspension
        camera = {
            coords = vector3(2.0, 3.0, 0.0),
            rotation = vector3(-10.0, 0.0, 50.0),
            fov = 60.0
        }
    },
    ['Offset Front'] = {
        label = 'Front Track Width',
        modType = 'stance_offset_front',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'offsetFront',
        range = 0.2,
        camera = {
            coords = vector3(2.5, 2.0, -0.3),
            rotation = vector3(-15.0, 0.0, 45.0),
            fov = 50.0
        }
    },
    ['Offset Rear'] = {
        label = 'Rear Track Width',
        modType = 'stance_offset_rear',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'offsetRear',
        range = 0.2,
        camera = {
            coords = vector3(2.5, -2.0, -0.3),
            rotation = vector3(-15.0, 0.0, 135.0),
            fov = 50.0
        }
    },
    ['Camber Front'] = {
        label = 'Front Camber',
        modType = 'stance_camber_front',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'camberFront',
        range = 1.5,
        camera = {
            coords = vector3(2.5, 2.0, -0.3),
            rotation = vector3(-15.0, 0.0, 45.0),
            fov = 50.0
        }
    },
    ['Camber Rear'] = {
        label = 'Rear Camber',
        modType = 'stance_camber_rear',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'camberRear',
        range = 1.5,
        camera = {
            coords = vector3(2.5, -2.0, -0.3),
            rotation = vector3(-15.0, 0.0, 135.0),
            fov = 50.0
        }
    },
    ['Wheel Size'] = {
        label = 'Wheel Size',
        modType = 'stance_wheel_size',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'wheelSize',
        range = 1.5,
        camera = {
            coords = vector3(2.5, 1.5, -0.3),
            rotation = vector3(-15.0, 0.0, 45.0),
            fov = 50.0
        }
    },
    ['Wheel Width'] = {
        label = 'Wheel Width',
        modType = 'stance_wheel_width',
        icon = 'wheels.png',
        isStance = true,
        stanceType = 'wheelWidth',
        range = 1.5,
        camera = {
            coords = vector3(2.5, 1.5, -0.3),
            rotation = vector3(-15.0, 0.0, 45.0),
            fov = 50.0
        }
    }
}