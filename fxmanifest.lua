fx_version 'cerulean'
game 'gta5'

name "TC-RussianRoulette"
description "Ticker's Russian Roulette Script"
author "Ticker"
version "1.0.0"
lua54 "yes"

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}

dependencies {
	"ox_lib",
	"interact-sound"
}
