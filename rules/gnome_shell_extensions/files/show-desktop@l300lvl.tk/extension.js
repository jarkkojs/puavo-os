/*much various credit to simonthechipmunk, mikechaberski, mathematicalcoffee, asan, spinus, Xes, gcampax, magcius, and every other dev i have burrowed code from over time. without gnu/gpl/foss nothing i code would ever be possible as i just wouldnt bother*/
const St = imports.gi.St;
const Gtk = imports.gi.Gtk;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const Me = imports.misc.extensionUtils.getCurrentExtension();
const Meta = imports.gi.Meta;
const Atk = imports.gi.Atk;
const Clutter = imports.gi.Clutter;

    //moved from gio why did we do this anyways for hover icons move away from stylesheet _finally_
const baseGIcon = 'puavo-base-user-desktop';
const hoverGIcon = 'puavo-hover-user-desktop';

let indicatorBox, icon, _desktopShown, _alreadyMinimizedWindows, box, shouldrestore;

    //get currently focused window this was pulled from https://github.com/mathematicalcoffee/Gnome-Shell-Window-Buttons-Extension
function _getWindowToControl () {
    let win = global.display.focus_window,
    workspace = global.workspace_manager.get_active_workspace(),
    windows = workspace.list_windows().filter(function (w) {
        return w.get_window_type() !== Meta.WindowType.DESKTOP;
    });
    // BAH: list_windows() doesn't return in stackin order (I thought it did)
    windows = global.display.sort_windows_by_stacking(windows);

    if (win === null || win.get_window_type() === Meta.WindowType.DESKTOP) {
        // No windows are active, control the uppermost window on the
        // current workspace
        if (windows.length) {
            win = windows[windows.length - 1];
            if(!('get_maximized' in win)) {
                win = win.get_meta_window();
            }
        }
    }
    return win;
}
    //toggles the desktop and icon when clicked
function _showDesktop() {
    let metaWorkspace = global.workspace_manager.get_active_workspace();
    let windows = metaWorkspace.list_windows();

    if (_desktopShown) {
        for ( let i = 0; i < windows.length; ++i ) {
            if (windows[i].minimized){
                shouldrestore = true;
                for (let j = 0; j < _alreadyMinimizedWindows.length; j++) {
                    if (windows[i] == _alreadyMinimizedWindows[j]) {
                        shouldrestore = false;
                        break;
                    }
                }
            if (shouldrestore) {
                //toggle icon to the opposite settings when windows are minimized
                indicatorBox.connect('enter-event', function() {
                    _SetButtonIcon('hover');
                });
                indicatorBox.connect('leave-event', function() {
                    _SetButtonIcon('base');
                });
                //only check and hide overview when button clicked durp durp
                if (Main.overview.visible) {
                    Main.overview.hide();
                }
                windows[i].unminimize();
                //activate and bring the last focused window to the top
                let win = _getWindowToControl();
                //find better method than current time as shell complains or did maybe a bug but i have no reference
                win.activate(global.get_current_time());
            }
        }
    }
    _alreadyMinimizedWindows.length = []; //Apparently this is better than this._alreadyMinimizedWindows = [];
    } else {
        for ( let i = 0; i < windows.length; ++i ) {
            if (!windows[i].skip_taskbar){
                if (!windows[i].minimized) {
                    //set dfault hover icon when no windows minimized
                    indicatorBox.connect('enter-event', function() {
                        _SetButtonIcon('base');
                    });
                    indicatorBox.connect('leave-event', function() {
                        _SetButtonIcon('hover');
                    });
                    //only check and hide overview when button clicked durp durp
                    if (Main.overview.visible) {
                        Main.overview.hide();
                    }
                    windows[i].minimize();
                } else {
                    _alreadyMinimizedWindows.push(windows[i]);
                }
            }
        }
    }
    _desktopShown = !_desktopShown;
}
    //creates the button and sets the icon and mouse event connections finally adding everything to status area
function ShowDesktopButton() {
    //create initial panel button
    indicatorBox = new PanelMenu.Button(0.0, null, true);
    indicatorBox.accessible_role = Atk.Role.TOGGLE_BUTTON;
    //get current status to create the right icon mode if we change panel positions and have already toggled
    if (_desktopShown == false) {
        //create base icon since we have not toggled
        icon = new St.Icon({
            icon_name: baseGIcon,
            icon_size: 32,
            style_class: 'system-status-icon' //sets st icon to system style
        });
        //set icon on mouse over
        indicatorBox.connect('enter-event', function() {
            _SetButtonIcon('hover');
        });
        //reverse mode when the cursor is no longer hovering
        indicatorBox.connect('leave-event', function() {
            _SetButtonIcon('base');
        });
    } else {
        //set reverse icon as base since we must have toggled
        icon = new St.Icon({
            icon_name: hoverGIcon,
            icon_size: 32,
            style_class: 'system-status-icon' //sets st icon to system style
        });
        //set icon on mouse over
        indicatorBox.connect('enter-event', function() {
            _SetButtonIcon('base');
        });
        //reverse mode when the cursor is no longer hovering
        indicatorBox.connect('leave-event', function() {
            _SetButtonIcon('hover');
        });
    }
    //add icon to panel button
    indicatorBox.add_actor(icon);
    //sets key release event when icon is hovered via alt tab panel or selecting an item in panel
    indicatorBox.connect_after('key-release-event', _onKeyRelease);
    //calls the function to toggle desktop when clicked now works when click is released
    indicatorBox.connect('button-release-event', _showDesktop);
    //finally add panel button to statusArea todo allow settings position as well as box
    Main.panel.addToStatusArea("ShowDesktop", indicatorBox, 1, box);
}
    //from panel.js sets keys to toggle showDesktop the same as those for activities button
    //this may change again so must keep an eye on panel.js
function _onKeyRelease(actor, event) {
    let symbol = event.get_key_symbol();
    if (symbol == Clutter.KEY_Return || symbol == Clutter.KEY_space) {
        _showDesktop();
    }
    return Clutter.EVENT_PROPAGATE;
}
    //hover icon function dirty, each mode can be set explicitly but for now this works
function _SetButtonIcon(mode) {
    if (mode === 'hover') {
        icon.icon_name = hoverGIcon;
    } else {
        icon.icon_name = baseGIcon;
    }
}
    //sets the panel box location
function _setPosition() {
    //works because were calling only a function on enable the function controls everything important
    //check that indicatorBox is present, or settings could throw error when extension disabled after being enabled
    if (indicatorBox !== null){
        disable();
        enable();
    }
}

function init(extensionMeta) {
    //sets initial desktop status also used to get toggle status mode
    _desktopShown = false;
    //creates windows we have minimized variable
    _alreadyMinimizedWindows = [];
    //get icon path gio wasnt being called correctly gi gi o
    Gtk.IconTheme.get_default().append_search_path(Me.dir.get_child('icons').get_path());
}
    //by creating everything in a function and calling that function in enable we can call disbale enable to force correct settings
function enable() {
    // Set position on panel. Possible values are 'left', 'center', 'right'.
    this.boxPosition = 'left';
    box = this.boxPosition;
    //call function which creates button
    new ShowDesktopButton();
}

function disable() {
    //null out status role so this role can be used again
    Main.panel.statusArea['ShowDesktop'] = null;
    //destroy button and null it out were done here
    indicatorBox.destroy();
    indicatorBox = null;
}
