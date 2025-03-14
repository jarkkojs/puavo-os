const ShellVersion = imports.misc.config.PACKAGE_VERSION.split(".");
const Main = imports.ui.main;
const Lang    = imports.lang;
const PanelMenu = imports.ui.panelMenu;
const St = imports.gi.St;
const HIGHT_SPEED = 0.01;
const GObject = imports.gi.GObject;

const OverviewButton = GObject.registerClass(
class OverviewButton extends PanelMenu.Button{
    _init() {
        super._init(0,'QuickOverview');

        this.buttonIcon = new St.Icon({ style_class: 'system-status-icon', 'icon_size': 32 });
        this.add_actor(this.buttonIcon);
        this.buttonIcon.icon_name='puavo-multitasking-view';
        this.connectObject('button-press-event', Lang.bind(this, this._refresh));
        this.original_speed = St.Settings.get().slow_down_factor;
        this.modified_speed = HIGHT_SPEED;
    };

    _refresh() {

        this.original_speed = St.Settings.get().slow_down_factor;
        St.set_slow_down_factor(this.modified_speed);
        if (Main.overview._shown)
            Main.overview.hide();
        else
            {
            Main.overview.show();
            }
        St.set_slow_down_factor(this.original_speed);

    }

});

function init(extensionMeta) {
    let theme = imports.gi.Gtk.IconTheme.get_default();
    theme.append_search_path(extensionMeta.path + "/icons");
}

let QuickOverviewButton;

function enable() {
    QuickOverviewButton = new OverviewButton();

    Main.panel.addToStatusArea('quickoverview-menu', QuickOverviewButton, 1, 'left');
    let indicator = Main.panel.statusArea['activities'];
    if(indicator != null)
    indicator.container.hide();
}

function disable() {
    QuickOverviewButton.destroy();

    let indicator = Main.panel.statusArea['activities'];
    if(indicator != null)
    indicator.container.show();
}
