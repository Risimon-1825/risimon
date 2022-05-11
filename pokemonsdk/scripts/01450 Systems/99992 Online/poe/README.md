# PSDK_Online_Engine

Script responsive of making PSDK Online Engine work

## What feature it will implement

1. Online battle
2. Online trades
3. Mystery Gifting
4. Wonder Trades
5. Map Communication (Players on map)
6. GTS

## Communication specification

Some services might need to be implemented on server side (eg. mystery gift, wonder trades, gts). Some services might allow both direct communication and indirect communication (listing).

Since this system relies on [NuriGame::Online::Proxy](https://gitlab.com/NuriYuri/nuri_game-online-proxy) we will base all listing services over the name of the user:
- `ListedBattle` => User is listed on OnlineBattles
- `ListedTrade` => User is listed on OnlineTrades
- `ListedMap` => User is listed on online map
- `ListedMap:{MapId}` => User is listed on specific online map
- `Battle:{Name}` => User is not listed but uses Online Battle
- `Trade:{Name}` => User is not listed but uses Online Trade
- `Map:{MapId}:{Name}` => User is not listed on map but uses Map Communication

When a user changes service/mode, he might disconnect first before picking another service.

User will use their name, DO ID and the time they loggued in (in UTC+0) as `secret`.

User don't have to register for services involving sub servers so it has no name nor secret, communication will only be handled using its own id on the proxy.

Server will implement the services like GTS using sub servers that will act as client to it but that are actually server. Sub server must use the secret `"\x00"` and the name that correspond to their service.

## OnlineHandler specification

The `OnlineHandler` must only do one thing at a time. It shouldn't do Trading and Battle at once for example. Regardless, for some specific uses, it's allowed that `OnlineHandler` tries to list all available battles while it's doing something else (Map Communication for example).

The `OnlineHandler` must send a Disconnect packet when the game SoftResets or the Game closes.

The `OnlineHandler` must handle every external communication in a Thread/Ractor that isn't the Main Thread/Ractor.

All data queries sent to `OnlineHandler` will be asynchronous unless they're state related queries (eg, which mode the `OnlineHandler` is in or if it is connected to the server). This mean that all asynchronous queries will take a block that will have as first parameter `success` and other parameters the expected data.

## OnlineHandler methods

Here's a list of methods implemented by the `OnlineHandler` if they're asynchronous a block will be shown in method definition:

- `connected?`: Tells if the `OnlineHandler` is connected to the server.
- `mode`: Gives the current mode of the `OnlineHandler`. List of modes:
  - `:listed_battle`
  - `:listed_trade`
  - `:listed_map`
  - `:in_battle`
  - `:in_trade`
  - `:in_private_map`
  - `:in_mystery_gift`
  - `:in_wonder_trade`
  - `:in_gts`
  - `:none`
- `id`: ID of the client on the server
- `connect_to_listed_battle(battle_driver) { |success| }`: Change the mode to `:listed_battle` and expose the player as awaiting for battle. The `battle_driver` handle all the communication between the game and the server. It must implement usefull function for the game (eg. list player), `on_data_received`, `on_user_connect` and `on_user_disconnect`.
- `connect_to_listed_trade(trade_driver) { |success| }`: Change the mode to `:listed_trade` and expose the player as awaiting for trade. The `trade_driver` handle all the communication between the game and the server. It must implement usefull function for the game (eg. list player), `on_data_received`, `on_user_connect` and `on_user_disconnect`.
- `connect_to_listed_map(map_driver) { |success| }`: Change the mode to `:listed_map` and expose the player as in the map he currently is (handled by `map_driver`). The `map_driver` handle all the communication between the game and the server. It must implement usefull function for the game (eg. list player), `on_data_received`, `on_user_connect` and `on_user_disconnect`.
- `start_battle(battle_secret, battle_driver) { |success| }`: Change the mode to `:in_battle`. `battle_driver` handle the communication and `battle_secret` correspond to the secret of the player who "hosts" the battle. (host = decided about the rules and accepted all the participant to the battle).
- `start_trade(trade_secret, trade_driver) { |success| }`: Change the mode to `:in_trade`. `trade_driver` handle the communication and `trade_secret` correspond to the secret of the player who accepted to participate to the trade.
- `join_map_player(map_secret, map_driver) { |success| }`: Change the mode to `:in_private_map`. `map_driver` handle the communication while `map_secret` correspond to the secret of the playyer who accepted to let other player in its map. (Example: underground, secret bases etc...)
- `start_mystery_gift(mystery_gift_driver) { |success| }`: Change the mode to `:in_mystery_gift`. `mystery_gift_driver` handles the communication, it should communicate properly with the mystery gift sub server.
- `start_wonder_trade(wonder_trade_driver) { |success| }`: Change the mode to `:in_wonder_trade`. `wonder_trade_driver` handles the communication, it should communicate properly with the wonder trade sub server.
- `start_gts(gts_driver) { |success| }`: Change the mode to `:in_gts`. `gts_driver` handles the communication, it should communicate properly with the gts sub server.
- `disconnect`: Change the mode to `:none` and effectively disconnect the player from the server.

## About the drivers

Drivers works a bit the same `OnlineHandler` in term of communication with the game. All data is handled asynchronously and the driver might have states. Putting aside the `map_driver` all driver has no control over the player's name in the Proxy. The `OnlineHandler` choose the name and then bind all the usefull functions.

In order to communicate properly with the proxy, all the drivers should implement the functions:
- `on_data_received(from_id, data)`: Handle data (string) received from_id (Integer)
- `on_user_connect(id, name)`: Handle user connection where id (integer) is the ID of the user in the proxy and name is the name of the user in the proxy (see [## Communication specification]("## Communication specification"))
- `on_user_disconnect(id)`: Handle the user disconnection where id (integer) is the ID of the user in the proxy.
- `client=`: Function that takes an encapsulated NuriGame::Online::Proxy::Client where the only available methods are those `OnlineHandler` expects the driver to use. (For instance, `send_data`, `list_user_by_name`).
- `name=`: Function that takes the name the `OnlineHandler` provided when registering the user.

If you need to implement some "room system", it's also possible that you define a `name_suffix` method. In such case, `OnlineHandler` will automatically connect with `{ServiceName}:{name_suffix}` when the connect function is called.

The `OnlineHandler` relies on drivers so the fangame is not limited to what PSDK has to offer, the fangame can do much more and maybe way better!
