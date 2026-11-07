// AppIcons.qml
// ---------------------------------------------------------------------------
// Window class/title -> Nerd Font glyph. This is a straight port of the
// window-rewrite map from waybar/config.jsonc, including its class/title
// regexes, so the workspaces show the same icons as the old bar.
// ---------------------------------------------------------------------------
pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQml

Singleton {
    id: root

    readonly property string fallback: "󰘔"

    // Checked before class rules, like waybar's universal title overrides.
    readonly property var titleRules: [
        { re: "youtube",  icon: "" },
        { re: "opencode", icon: "󰚩" }
    ]

    readonly property var classRules: [
        // Terminals & browsers
        { re: "^(kitty)$",                                  icon: "󰆍" },
        { re: "^(alacritty)$",                              icon: "" },
        { re: "^(google-chrome|com\.google\.Chrome)$",   icon: "" },

        // Code & development
        { re: "^(code|code-url-handler|com\.microsoft\.VSCode)$", icon: "󰨞" },
        { re: "^(opencode)$",                               icon: "󰚩" },
        { re: "^(meld|org\.gnome\.Meld)$",                icon: "F" },
        { re: "^(micro)$",                                  icon: "󰘦" },
        { re: "^(vim|nvim)$",                               icon: "" },

        // System, file managers & audio
        { re: "^(nemo|org\.kde\.dolphin)$",               icon: "󰉋" },
        { re: "^(io\.missioncenter\.MissionCenter|missioncenter)$", icon: "󰍛" },
        { re: "^(btop)$",                                   icon: "󰄨" },
        { re: "^(org\.pulseaudio\.pavucontrol|pavucontrol)$", icon: "󰍰" },
        { re: "^(com\.github\.wwmm\.easyeffects|easyeffects)$", icon: "󰓃" },
        { re: "^(com\.obsproject\.Studio|obs)$",          icon: "󰑋" },
        { re: "^(org\.kde\.spectacle|spectacle)$",        icon: "󰹑" },
        { re: "^(org\.kde\.partitionmanager|partitionmanager)$", icon: "󰋊" },

        // Communication & web apps
        { re: "^(org\.telegram\.desktop|telegram)$",     icon: "" },
        { re: "^(discord)$",                                icon: "󰙯" },
        { re: "^(slack)$",                                  icon: "󰒱" },
        { re: "^(com\.rtosta\.zapzap|com\.rtosta\.zapzap\.nogpu|zapzap)$", icon: "󰖣" },
        { re: "^(abdownloadmanager)$",                      icon: "󰇚" },
        { re: "^(org\.qbittorrent\.qBittorrent|qbittorrent)$", icon: "󰛴" },
        { re: "^(filezilla)$",                              icon: "󰈂" },

        // Media & viewers
        { re: "^(mpv|org\.kde\.haruna)$",                 icon: "" },
        { re: "^(spotify)$",                                icon: "󰓇" },
        { re: "^(vlc)$",                                    icon: "󰕼" },
        { re: "^(imv|imv-dir|org\.kde\.gwenview)$",       icon: "󰋩" },
        { re: "^(org\.kde\.kate|org\.kde\.kwrite|kate|kwrite)$", icon: "󰏫" },
        { re: "^(org\.kde\.kcalc|kcalc)$",                icon: "󰪚" },
        { re: "^(org\.kde\.ark|ark)$",                    icon: "󰛫" },

        // Gaming & launchers
        { re: "^(steam)$",                                  icon: "󰓓" },
        { re: "^(net\.lutris\.Lutris|net\.lutris\.Lutris1|lutris)$", icon: "󰺵" },
        { re: "^(org\.vinegarhq\.Sober)$",                icon: "󰲡" },
        { re: "^(com\.modrinth\.ModrinthApp)$",           icon: "󰍳" },
        { re: "^(net\.davidotek\.pupgui2)$",              icon: "󰓓" },
        { re: "^(dosbox)$",                                 icon: "󰊴" },
        { re: "^(io\.github\.benjamimgois\.goverlay)$",  icon: "󰓓" },
        { re: "^(wine|winetricks)$",                        icon: "󰡷" },

        // CachyOS / tools
        { re: "^(com\.wayle\.settings)$",                 icon: "󰒓" },
        { re: "^(cachyos-hello|org\.cachyos\.KernelManager|org\.cachyos\.scx-manager)$", icon: "" },
        { re: "^(nvidia-settings)$",                        icon: "󰢮" },
        { re: "^(nwg-look|nwg-displays|qt6ct)$",            icon: "󰏘" }
    ]

    function classOf(toplevel) {
        if (!toplevel) return "";
        if (toplevel.lastIpcObject && toplevel.lastIpcObject.class)
            return String(toplevel.lastIpcObject.class);
        if (toplevel.handle && toplevel.handle.appId)
            return String(toplevel.handle.appId);
        return "";
    }

    function titleOf(toplevel) {
        if (!toplevel) return "";
        // HyprlandToplevel.title is live. lastIpcObject is only refreshed on
        // demand, which is why the old title (and its icon) could get stuck.
        if (toplevel.title)
            return String(toplevel.title);
        if (toplevel.lastIpcObject && toplevel.lastIpcObject.title)
            return String(toplevel.lastIpcObject.title);
        return "";
    }

    function matches(pattern, value) {
        return new RegExp(pattern, "i").test(value);
    }

    // Quickshell only fills a toplevel's lastIpcObject (where the class
    // lives) during refreshToplevels(). Windows opened after Quickshell
    // started would otherwise have no class and always get the fallback.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openwindow")
                Hyprland.refreshToplevels();
        }
    }

    function iconFor(toplevel) {
        const cls = classOf(toplevel);
        const title = titleOf(toplevel);

        // 1. Title overrides
        for (let i = 0; i < titleRules.length; ++i) {
            if (matches(titleRules[i].re, title))
                return titleRules[i].icon;
        }

        // 2. Class rules
        for (let i = 0; i < classRules.length; ++i) {
            if (matches(classRules[i].re, cls))
                return classRules[i].icon;
        }

        return fallback;
    }
}
