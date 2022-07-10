Auth = exports.plouffe_lib:Get("Auth")
Callback = exports.plouffe_lib:Get("Callback")

Server = {
	Init = false,
	Callbacks = {},
	CoolDownPlayers = {},
	VignePlayer = {},
	livraison = {},
	deliveryInterval = {min = 1000 * 60 * 30, max = 1000 * 60 * 60},
	deliveryDelay = 1 * 60 * 30,
	nextId = 1
}

Vine = {}
VineFnc = {} 

HarvestedZone = {}
TempHarvestZone = {}

Vine.Player = {}
Vine.Barrels = {}
Vine.barrelHash = GetHashKey("prop_wooden_barrel")

Vine.BarrelTypes = {
	purple_grape = {
		fermentationTime = 60 * 60 * 48,
		type = "champagne",
		maxSugar = 2,
		maxYeast = 3,
		itemName = "wine_champagne"
	},
	blue_grape = {
		fermentationTime = 60 * 60 * 36,
		type = "vin rouge",
		maxSugar = 5,
		maxYeast = 2,
		itemName = "wine_red"
	},
	green_grape = {
		fermentationTime = 60 * 60 * 24,
		type = "vin blanc",
		maxSugar = 4,
		maxYeast = 1,
		itemName = "wine_white"
	}
}

Vine.GrapePerBranch = {
	blue_grapes = {name = "blue_grape", minAmount = math.random(10,20), maxAmount = math.random(21,30)},
	green_grapes = {name = "green_grape", minAmount = math.random(10,20), maxAmount = math.random(21,30)},
	purple_grapes = {name = "purple_grape", minAmount = math.random(10,15), maxAmount = math.random(16,22)}
}

Vine.StompItems = {
	minimum = {
		green_grape = 1000,
		blue_grape = 1000,
		purple_grape = 1000
	}
}

Vine.BarilInfo = {
	literPerMinimum = 10,
	desc = {
		green_grape = "raisins de Thompson",
		blue_grape = "raisins Corinthe",
		purple_grape = "raisins Pinot Noir"
	}
}

Vine.Menu = {
	selectStomp = {
        {
            id = 1,
            header = "Raisin Corinthe",
            txt = "Fouler des raisin Corinthe",
            params = {
                event = "",
                args = {
                    item = "blue_grape"
                }
            }
        },

        {
            id = 2,
            header = "Raisin de Thompson",
            txt = "Fouler des raisin de Thompson",
            params = {
                event = "",
                args = {
                    item = "green_grape"
                }
            }
        },

		{
            id = 3,
            header = "Raisin Pinot Noir",
            txt = "Fouler des raisin Pinot Noir",
            params = {
                event = "",
                args = {
                    item = "purple_grape"
                }
            }
        }
    },

	barrelInteract = {
        {
            id = 1,
            header = "Verifier la fermentation",
            txt = "Verifier si la fermentation du baril est terminer",
            params = {
                event = "",
                args = {
                    fnc = "InspectBarrel"
                }
            }
        },

		{
            id = 2,
            header = "Ajouter du sucre",
            txt = "Ajouter du sucre au baril",
            params = {
                event = "",
                args = {
                    fnc = "AddSugar"
                }
            }
        },

		{
            id = 3,
            header = "Ajouter de la levure",
            txt = "Ajouter de la levure au baril",
            params = {
                event = "",
                args = {
                    fnc = "AddYeast"
                }
            }
        },

		{
            id = 4,
            header = "Voir le status du baril",
            txt = "Voir le status du baril",
            params = {
                event = "",
                args = {
                    fnc = "OpenBarrelStatus"
                }
            }
        },

		{
            id = 5,
            header = "Jeter le baril",
            txt = "Jeter le baril",
            params = {
                event = "",
                args = {
                    fnc = "DestroyBarrel"
                }
            }
        },

		{
            id = 6,
            header = "Récolter le baril",
            txt = "Récolter le baril",
            params = {
                event = "",
                args = {
                    fnc = "HarvestBarrel"
                }
            }
        }
    }
}

Vine.Utils = {
	ped = 0,
	pedCoords = vector3(0,0,0),
	harvesting = false,
	inVineyard = false,
	inVineyardThread = false,
	shownNotifs = {},
	keysRegistered = false
}

Vine.Growth = {
	active = false,
	interval = 1000 * 60 * 30,
	rate = 60 * 15
}

Vine.StartJobCoords = {
	vineyard = {
		name = "vineyard",
		coords = vector3(-1885.0672607422, 2059.3781738281, 140.98402404785),
		maxDst = 500.0,
		isZone = true,
		zoneMap = {
			inEvent = "plouffe_vineyard:enteredVineyard",
			outEvent = "plouffe_vineyard:leftVineyard",
		 	shouldTriggerEvent = true
		}
	},

	vineyard_water = {
		name = "vineyard_water",
		coords = vector3(-1876.6265869141, 2081.6672363281, 141.24537658691),
		maxDst = 3.0,
		box = {
			vector2(-1876.8205566406, 2076.0412597656),
			vector2(-1880.236328125, 2077.2766113281),
			vector2(-1876.6569824219, 2086.9345703125),
			vector2(-1873.2652587891, 2085.67578125)
		}
	},

	vineyard_get_barrel = {
		name = "vineyard_get_barrel",
		coords = vector3(-1874.595703125, 2060.9177246094, 135.91513061523),
		maxDst = 1.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Prendre un baril",
		aditionalParams = {zone = "vineyard_get_barrel", fnc = "GetBarrel"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_1 = {
		name = "vineyard_yard_1",
		coords = vector3(-1826.8337402344, 2173.8645019531, 107.1605758667),
		maxDst = 104.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_1", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "blue_grapes", minAmount = math.random(1,5), maxAmount = math.random(5, 10)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_2 = {
		name = "vineyard_yard_2",
		coords = vector3(-1722.2186279297, 2335.3081054688, 63.232402801514),
		maxDst = 50.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_2", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "blue_grapes", minAmount = math.random(1,5), maxAmount = math.random(5, 10)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_3 = {
		name = "vineyard_yard_3",
		coords = vector3(-1630.4189453125, 2272.1003417969, 73.939895629883),
		maxDst = 40.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_3", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "blue_grapes", minAmount = math.random(1,5), maxAmount = math.random(5, 10)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_4 = {
		name = "vineyard_yard_4",
		coords = vector3(-1597.1376953125, 2220.494140625, 77.430541992188),
		maxDst = 30.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_4", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "blue_grapes", minAmount = math.random(1,5), maxAmount = math.random(5, 10)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_5 = {
		name = "vineyard_yard_5",
		coords = vector3(-1706.0046386719, 2015.8588867188, 117.08276367188),
		maxDst = 30.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_5", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "purple_grapes",	minAmount = math.random(1,2),	maxAmount = math.random(2, 3)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_6 = {
		name = "vineyard_yard_6",
		coords = vector3(-1703.2607421875, 1960.7835693359, 130.12413024902),
		maxDst = 30.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_6", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "purple_grapes",	minAmount = math.random(1,2),	maxAmount = math.random(2, 3)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_7 = {
		name = "vineyard_yard_7",
		coords = vector3(-1746.9787597656, 1915.7286376953, 144.408203125),
		maxDst = 40.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_7", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "purple_grapes",	minAmount = math.random(1,2),	maxAmount = math.random(2, 3)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_yard_8 = {
		name = "vineyard_yard_8",
		coords = vector3(-1903.9819335938, 1921.6712646484, 163.40502929688),
		maxDst = 50.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Recolter",
		aditionalParams = {zone = "vineyard_yard_8", fnc = "Harvest"},
		jobs = {"vineyard"},
		itemsList = {{name = "green_grapes",	minAmount = math.random(1,3),	maxAmount = math.random(3, 6)}},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_1 = {
		name = "vineyard_stomp_1",
		coords = vector3(-1881.4936523438, 2079.8542480469, 141.06266784668),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_1", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_2 = {
		name = "vineyard_stomp_2",
		coords = vector3(-1884.3902587891, 2080.8415527344, 141.0565032959),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_2", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_3 = {
		name = "vineyard_stomp_3",
		coords = vector3(-1886.8337402344, 2081.7883300781, 141.05790710449),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_3", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_4 = {
		name = "vineyard_stomp_4",
		coords = vector3(-1880.2072753906, 2083.6311035156, 141.05990600586),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_4", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_5 = {
		name = "vineyard_stomp_5",
		coords = vector3(-1883.0576171875, 2084.7180175781, 141.06062316895),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_5", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_6 = {
		name = "vineyard_stomp_6",
		coords = vector3(-1885.4857177734, 2085.5144042969, 141.06117248535),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_6", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_7 = {
		name = "vineyard_stomp_7",
		coords = vector3(-1884.1804199219, 2089.1462402344, 141.06150817871),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_7", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_8 = {
		name = "vineyard_stomp_8",
		coords = vector3(-1881.7547607422, 2088.1525878906, 141.06198120117),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_8", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},

	vineyard_stomp_9 = {
		name = "vineyard_stomp_9",
		coords = vector3(-1878.9406738281, 2087.2194824219, 141.06214904785),
		maxDst = 0.5,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Fouler des raisins",
		aditionalParams = {zone = "vineyard_stomp_9", fnc = "StompGrape"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
	},
}

Vine.DeliveryItems = {
	{
		label = "Champagne",
		name = "wine_champagne",
		price = {min = 60, max = 80},
		amount = {min = 30, max = 60}
	},

	{
		label = "Vin rouge",
		name = "wine_red",
		price = {min = 45, max = 65},
		amount = {min = 30, max = 60}
	},

	{
		label = "Vin blanc",
		name = "wine_white",
		price = {min = 35, max = 55},
		amount = {min = 30, max = 60}
	}
}

Vine.DeliveryCoords = {
	grooveStreet_vineyard_delivery = {
		name = "grooveStreet_vineyard_delivery",
		coords = vector3(-41.057022094727, -1748.0808105469, 29.406959533691),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "grooveStreet_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	lowenstein_vineyard_delivery = {
		name = "lowenstein_vineyard_delivery",
		coords = vector3(379.58871459961, -1781.2626953125, 29.461231231689),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "lowenstein_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	strawberry_vineyard_delivery = {
		name = "strawberry_vineyard_delivery",
		coords = vector3(53.086353302002, -1478.876953125, 29.285976409912),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "strawberry_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	strawberry_unicorn_vineyard_delivery = {
		name = "strawberry_unicorn_vineyard_delivery",
		coords = vector3(170.54507446289, -1336.8575439453, 29.294065475464),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "strawberry_unicorn_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	xero_strawberry_vineyard_delivery = {
		name = "xero_strawberry_vineyard_delivery",
		coords = vector3(294.53079223633, -1251.5815429688, 29.399385452271),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "xero_strawberry_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	palomino_vineyard_delivery = {
		name = "palomino_vineyard_delivery",
		coords = vector3(-894.15551757813, -1161.9743652344, 5.1519589424133),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "palomino_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	chinese_vineyard_delivery = {
		name = "chinese_vineyard_delivery",
		coords = vector3(-702.82690429688, -916.93035888672, 19.213998794556),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "chinese_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	palomino_liquor_vineyard_delivery = {
		name = "palomino_liquor_vineyard_delivery",
		coords = vector3(-1106.0789794922, -1288.2697753906, 5.4187135696411),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "palomino_liquor_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	north_rockford_vineyard_delivery = {
		name = "north_rockford_vineyard_delivery",
		coords = vector3(-1432.3134765625, -253.0012512207, 46.359771728516),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "north_rockford_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	mirror_park_vineyard_delivery = {
		name = "mirror_park_vineyard_delivery",
		coords = vector3(1160.7990722656, -311.88372802734, 69.277366638184),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "mirror_park_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	clinton_ave_vineyard_delivery = {
		name = "clinton_ave_vineyard_delivery",
		coords = vector3(649.90283203125, 246.33683776855, 103.42394256592),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "clinton_ave_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	palominofreeway_vineyard_delivery = {
		name = "palominofreeway_vineyard_delivery",
		coords = vector3(2546.4235839844, 385.54568481445, 108.61808776855),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "palominofreeway_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	top_northrockford_vineyard_delivery = {
		name = "top_northrockford_vineyard_delivery",
		coords = vector3(-1829.1872558594, 801.15155029297, 138.4108581543),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "top_northrockford_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	harmony_1_vineyard_delivery = {
		name = "harmony_1_vineyard_delivery",
		coords = vector3(263.06909179688, 2592.2133789063, 44.93921661377),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "harmony_1_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	harmony_2_vineyard_delivery = {
		name = "harmony_2_vineyard_delivery",
		coords = vector3(542.19506835938, 2663.7314453125, 42.367778778076),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "harmony_2_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	harmony_3_vineyard_delivery = {
		name = "harmony_3_vineyard_delivery",
		coords = vector3(1041.2608642578, 2652.2385253906, 39.550941467285),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "harmony_3_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	harmony_4_vineyard_delivery = {
		name = "harmony_4_vineyard_delivery",
		coords = vector3(1189.91015625, 2651.3134765625, 37.835052490234),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "harmony_4_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	sandy_1_vineyard_delivery = {
		name = "sandy_1_vineyard_delivery",
		coords = vector3(1764.5612792969, 3320.4704589844, 41.423511505127),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "sandy_1_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	sandy_2_vineyard_delivery = {
		name = "sandy_2_vineyard_delivery",
		coords = vector3(1963.6153564453, 3749.6115722656, 32.262149810791),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "sandy_2_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	sandy_3_vineyard_delivery = {
		name = "sandy_3_vineyard_delivery",
		coords = vector3(1395.3552246094, 3623.7082519531, 35.012195587158),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "sandy_3_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	sandy_4_vineyard_delivery = {
		name = "sandy_4_vineyard_delivery",
		coords = vector3(1395.3552246094, 3623.7082519531, 35.012195587158),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "sandy_4_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	grapeseed_1_vineyard_delivery = {
		name = "grapeseed_1_vineyard_delivery",
		coords = vector3(1702.7541503906, 4917.2280273438, 42.223030090332),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "grapeseed_1_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	paleto_1_vineyard_delivery = {
		name = "paleto_1_vineyard_delivery",
		coords = vector3(1741.435546875, 6419.5766601563, 35.042556762695),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "paleto_1_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	paleto_2_vineyard_delivery = {
		name = "paleto_2_vineyard_delivery",
		coords = vector3(174.72999572754, 6642.8745117188, 31.573123931885),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "paleto_2_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	paleto_3_vineyard_delivery = {
		name = "paleto_3_vineyard_delivery",
		coords = vector3(-87.68376159668, 6494.541015625, 32.100730895996),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "paleto_3_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	paleto_4_vineyard_delivery = {
		name = "paleto_4_vineyard_delivery",
		coords = vector3(-79.89966583252, 6415.1787109375, 31.64040184021),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "paleto_4_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	paleto_5_vineyard_delivery = {
		name = "paleto_5_vineyard_delivery",
		coords = vector3(-358.72366333008, 6061.6459960938, 31.500133514404),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "paleto_5_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	route_68_vineyard_delivery = {
		name = "route_68_vineyard_delivery",
		coords = vector3(-2565.787109375, 2307.3818359375, 33.215488433838),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "route_68_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	route_68_vineyard_delivery_2 = {
		name = "route_68_vineyard_delivery_2",
		coords = vector3(-2565.787109375, 2307.3818359375, 33.215488433838),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "route_68_vineyard_delivery_2", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},

	great_ocean_vineyard_delivery = {
		name = "great_ocean_vineyard_delivery",
		coords = vector3(-3161.0737304688, 1113.3623046875, 20.857597351074),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "great_ocean_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},	

	great_ocean_2_vineyard_delivery = {
		name = "great_ocean_2_vineyard_delivery",
		coords = vector3(-3047.6140136719, 590.05303955078, 7.7777457237244),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "great_ocean_2_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	},	

	great_ocean_xero_vineyard_delivery = {
		name = "great_ocean_xero_vineyard_delivery",
		coords = vector3(-2066.35546875, -312.75970458984, 13.289811134338),
		maxDst = 2.0,
		protectEvents = true,
		isKey = true,
		isZone = true,
		nuiLabel = "Deposer le vin",
		aditionalParams = {zone = "great_ocean_xero_vineyard_delivery", fnc = "Deliver"},
		jobs = {"vineyard"},
		keyMap = {
			checkCoordsBeforeTrigger = true,
			onRelease = true,
			releaseEvent = "on_vineyard",
			key = "E"
		},
		active = false,
		itemsNeeded = {}
	}
}