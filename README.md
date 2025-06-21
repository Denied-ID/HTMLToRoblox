![Html2Rbx-Thumb](https://github.com/user-attachments/assets/0d2376d2-79cc-4942-82fc-b13e50aefc1e)


# THIS IS ALPHA SOFTWARE!
This is not at all ready for production use, but more for testing environments.
I'm just trying to get this out there for bug testing.



# Where's the Documentation?
Well you're in luck. It's right over here on this website: https://systech-corp-1.gitbook.io/

#  What's "HTML to Roblox"?
HTML to Roblox is an up and coming module that allows you to place HTML code into the module, and have it convert the contents of that HTML into a Roblox Gui.

# Why do I need this?
Well if you're planning to recreate a website (I know a lot of games like [LegacyVerse](https://www.roblox.com/games/12147220287/LegacyVerse) do this), or maybe you're just trying to find something easy to setup and use, then this might be useful for you. All you have to do is copy the website's HTML code (if you have permission to), and the CSS if needed, and then you can see it on your Gui.


# What about the other solutions out there?
I have noticed this question a bit in some older forum posts attempting to do the same thing I am, and I have seen "Roblox-TS" quite a bit. That might be useful for some people, but that's appears to be a little hard to set up, and not as beginner friendly as this one aims to be. Plus it uses something called TypeScript, which is something that isn't too easy for someone to learn right away. That's why I made this module specifically for HTML because it's easiest for you.

# Does this include things like JavaScript support?
Absolutely. In fact it also supports other supported features on Html buttons like `onclick="console.log('Button pressed!')`. And that's not all. You can even take a `<script>` delimiter, and add an atribute called `type` (`<script type="">`). Now what's cool about this `type` attribute is you can change the script from JS to LuaU, and it will work the same except it's a different language. Now the JS variant is literally just converted from its JS counterpart, to a Roblox supported variant so it can work in the Roblox engine.

# Example
There a small exemple so you can start to understand 
```lua
local HtmlToRoblox = require(game.ReplicatedStorage.HtmlParser)

HtmlToRoblox:Render([[ 
  <button onclick="print('Clicked!')">Click me!</button> 
]])
```
````
