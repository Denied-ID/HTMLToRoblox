![Html2Rbx-Thumb](https://github.com/user-attachments/assets/0d2376d2-79cc-4942-82fc-b13e50aefc1e)

> [!CAUTION]  
> This is not at all ready for production use, but more for testing environments.  
> I'm just trying to get this out there for bug testing, and for people to contribute and improve on.

## Where’s the Documentation?

Well, you’re in luck—it’s right over here on this website:  
<https://systech-corp-1.gitbook.io/html-to-roblox/>

## What’s “HTML to Roblox”?

**HTML to Roblox** is an up‑and‑coming module that allows you to place HTML code into the module, and have it convert the contents of that HTML into a Roblox GUI.

## Why do I need this?

If you’re planning to recreate a website (I know a lot of games like [LegacyVerse](https://www.roblox.com/games/12147220287/LegacyVerse) do this), or maybe you just want something easy to set up and use, this might be useful. All you have to do is copy the website’s HTML code (with permission, of course), and the CSS if needed, and then you can see it on your GUI.

## What about the other solutions out there?

I’ve noticed this question in some older forum posts. I’ve seen “Roblox‑TS” mentioned quite a bit—it might be useful for some, but it appears to be harder to set up and less beginner‑friendly than this one aims to be. Plus, it uses TypeScript, which isn’t the easiest thing to learn right away. That’s why I made this module specifically for HTML—it’s the easiest for you.

## Does this include things like JavaScript support?

Absolutely. In fact, it also supports other features on HTML buttons like:
```html
<button onclick="console.log('Button pressed!')">
  Press me
</button>
```

All this does is put the code into a JSTranspiler script within HtmlToRoblox's module and converts that same code into LuaU code supported by the Roblox engine. Depending on how much support compatibility we add, we might be able to put javascript html games in this thing.

# Want to Contribute?
Go ahead. The module’s source is in this repository for you to look over and help us improve for everyone using it. Thanks for making HTML to Roblox a better module for everyone.
