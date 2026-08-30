# Discord Nicknames in vMenu Online Players

This custom source changes only the displayed player name in **Online Players**. The normal vMenu label such as `Server #12 ->->->` remains unchanged.

## server.cfg
Add these lines **before** `ensure vMenu`:

```cfg
set vmenu_discord_guild_id "YOUR_DISCORD_SERVER_ID"
set vmenu_discord_bot_token "YOUR_BOT_TOKEN"
ensure vMenu
```

Do **not** use `setr` for the bot token. `set` keeps it server-side. Never post or share the token.

## Discord bot
1. Create/use a Discord bot and invite it to the same Discord server as your FiveM community.
2. Put that guild/server ID in `vmenu_discord_guild_id`.
3. Put the bot token in `vmenu_discord_bot_token`.
4. A FiveM player must expose a `discord:` identifier for the automatic match to work.

## Behavior
- Discord server nickname exists -> vMenu shows it.
- No Discord nickname / Discord lookup fails -> vMenu falls back to the normal FiveM player name.
- Server ID stays exactly as normal vMenu.
- Nicknames refresh every 5 minutes and when players join.

## Build
Build the solution in Release mode with the .NET SDK/Visual Studio as vMenu normally requires. The modified files are:
- `vMenu/menus/OnlinePlayers.cs`
- `vMenu/EventManager.cs`
- `assets/fxmanifest.lua`
- `assets/discord_nicknames.lua`
