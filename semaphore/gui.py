#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
from gi.repository import Gtk, Gdk, Gio, GLib

class AnsibleProvisionApp(Gtk.ApplicationWindow):

    def __init__(self, app):
        super().__init__(application=app, title="ansible-provision")
        self.set_default_size(500, 420)

        # inject custom CSS
        css_provider = Gtk.CssProvider()

        # Adding margin-left to checkbutton labels creates the gap!
        css_data = b"""
        .small-cmd { font-size: 0.85em; }
        checkbutton label { margin-left: 10px; }
        """
        css_provider.load_from_data(css_data)

        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # main layout container
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        main_box.set_margin_top(20)
        main_box.set_margin_bottom(20)
        main_box.set_margin_start(20)
        main_box.set_margin_end(20)
        self.set_child(main_box)

        # Header Box
        header_box = Gtk.CenterBox(margin_bottom=15)

        # left logo
        left_logo = Gtk.Picture.new_for_filename("../icon/ansible.png")
        left_logo.set_size_request(50, 50)
        left_logo.set_content_fit(Gtk.ContentFit.CONTAIN)
        left_logo.set_margin_start(15) # Adds space to the left of the logo
        header_box.set_start_widget(left_logo)

        # title text
        header = Gtk.Label(label="<span size='x-large' weight='bold'>ansible-provision</span>")
        header.set_use_markup(True)
        header_box.set_center_widget(header)

        # right logo
        right_logo = Gtk.Picture.new_for_filename("../icon/semaphore-ui.png")
        right_logo.set_size_request(50, 50)
        right_logo.set_content_fit(Gtk.ContentFit.CONTAIN)
        right_logo.set_margin_end(15) # Adds space to the right of the logo
        header_box.set_end_widget(right_logo)

        main_box.append(header_box)

        # TOP GRID
        self.top_grid = Gtk.Grid(row_spacing=15, column_spacing=12)
        # FILL forces the grid to stretch the full width of the window
        self.top_grid.set_halign(Gtk.Align.FILL)

        # hosts (h) - Row 0
        self.top_grid.attach(Gtk.Label(label="Hosts (h)", halign=Gtk.Align.START), 0, 0, 1, 1)
        self.hosts_drop = Gtk.DropDown.new(Gtk.StringList.new(["localhost", "LBiC", "homelab", "rootless"]))
        self.hosts_drop.connect("notify::selected", self.update_command)
        self.top_grid.attach(self.hosts_drop, 1, 0, 1, 1)

        # strategy (m) - Row 3
        self.top_grid.attach(Gtk.Label(label="Strategy (m)", halign=Gtk.Align.START), 0, 3, 1, 1)
        self.strategy_drop = Gtk.DropDown.new(Gtk.StringList.new(["Mitogen", "Linear"]))
        self.strategy_drop.connect("notify::selected", self.update_command)
        self.top_grid.attach(self.strategy_drop, 1, 3, 1, 1)

        # tags (t) - Row 1
        self.top_grid.attach(Gtk.Label(label="Tags (t)", halign=Gtk.Align.START), 0, 1, 1, 1)
        self.tags_entry = Gtk.Entry(placeholder_text="e.g. brave")
        self.tags_entry.connect("changed", self.update_command)
        self.top_grid.attach(self.tags_entry, 1, 1, 1, 1)

        # skip tags (s) - Row 2
        self.top_grid.attach(Gtk.Label(label="Skip tags (s)", halign=Gtk.Align.START), 0, 2, 1, 1)
        self.skip_tags_entry = Gtk.Entry(placeholder_text="e.g. emacs")
        self.skip_tags_entry.connect("changed", self.update_command)
        self.top_grid.attach(self.skip_tags_entry, 1, 2, 1, 1)

        # vertical separator
        v_sep = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        # hexpand forces the separator's column to absorb all leftover space!
        v_sep.set_hexpand(True)
        # Centers the 1px line directly inside that newly expanded empty space
        v_sep.set_halign(Gtk.Align.CENTER)
        self.top_grid.attach(v_sep, 2, 0, 1, 4)

        # options label - Row 0
        self.top_grid.attach(Gtk.Label(label="<b>Options:</b>", use_markup=True, halign=Gtk.Align.START), 3, 0, 1, 1)

        # dry run (c) - Row 1
        self.dry_run_check = Gtk.CheckButton(label="Dry run (c)")
        self.dry_run_check.connect("toggled", self.update_command)
        self.top_grid.attach(self.dry_run_check, 3, 1, 1, 1)

        # diff (d) - Row 2
        self.diff_check = Gtk.CheckButton(label="Diff (d)")
        self.diff_check.connect("toggled", self.update_command)
        self.top_grid.attach(self.diff_check, 3, 2, 1, 1)

        # debug (D) - Row 3
        self.debug_check = Gtk.CheckButton(label="Debug (D)")
        self.debug_check.connect("toggled", self.update_command)
        self.top_grid.attach(self.debug_check, 3, 3, 1, 1)

        # Append the tightly-packed top grid to the main box
        main_box.append(self.top_grid)

        # horizontal separator
        main_box.append(Gtk.Separator(margin_top=5, margin_bottom=5))

        # BOTTOM GRID (For wide, stretching elements)
        self.bottom_grid = Gtk.Grid(row_spacing=15, column_spacing=12)

        # start at task (a) - Row 0
        self.bottom_grid.attach(Gtk.Label(label="Start at task (a)", halign=Gtk.Align.START), 0, 0, 1, 1)
        self.start_task_entry = Gtk.Entry(placeholder_text="Search tasks...", hexpand=True)
        self.start_task_entry.connect("changed", self.update_command)
        self.bottom_grid.attach(self.start_task_entry, 1, 0, 1, 1)

        # command - Row 1
        self.bottom_grid.attach(Gtk.Label(label="Command:", halign=Gtk.Align.START), 0, 1, 1, 1)
        self.command_entry = Gtk.Entry(hexpand=True)
        self.command_entry.set_editable(False) # Read-only
        self.command_entry.add_css_class("monospace")
        self.command_entry.add_css_class("small-cmd") # Applies our smaller font
        self.bottom_grid.attach(self.command_entry, 1, 1, 1, 1)

        # Append the stretching bottom grid to the main box
        main_box.append(self.bottom_grid)

        # left: Mode Indicator perfectly aligned in Col 0 - Row 2 of bottom_grid
        self.mode_label = Gtk.Label(label="NORMAL")
        self.mode_label.add_css_class("dim-label") # GTK's native class for discrete, faded text
        self.mode_label.set_halign(Gtk.Align.START)
        self.mode_label.set_margin_top(10)
        self.bottom_grid.attach(self.mode_label, 0, 2, 1, 1)

        # center: Action buttons wrapped in a Box
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_box.set_halign(Gtk.Align.CENTER) # Centers the buttons relative to the inputs above
        btn_box.set_margin_top(10)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: self.close())
        btn_box.append(cancel_btn)

        launch_btn = Gtk.Button(label="Launch")
        launch_btn.add_css_class("suggested-action")
        launch_btn.connect("clicked", self.on_launch_clicked)
        btn_box.append(launch_btn)

        # Spanning columns 1 to 3 underneath the input fields
        self.bottom_grid.attach(btn_box, 1, 2, 3, 1)

        # keybindings (event controller)
        key_controller = Gtk.EventControllerKey.new()
        key_controller.connect("key-pressed", self.on_key_pressed)
        self.add_controller(key_controller)

        # focus tracker to update Mode indicator automatically
        self.connect("notify::focus-widget", self.on_focus_changed)

        # initialize the command string
        self.update_command()

        # GTK automatically focuses the first text entry on launch.
        # This idle hook guarantees we start in perfect NORMAL mode.
        GLib.idle_add(self.drop_initial_focus)

    def update_command(self, *args):
        """Dynamically builds the bash command based on UI state."""
        cmd = ["./api.sh", "run"]

        if self.strategy_drop.get_selected_item().get_string() == "Linear":
            cmd.append("--linear")

        if self.dry_run_check.get_active():
            cmd.append("--test")
        if self.diff_check.get_active():
            cmd.append("--diff")
        if self.debug_check.get_active():
            cmd.append("-v")

        tags = self.tags_entry.get_text().strip()
        if tags:
            cmd.append(f'--tags "{tags}"')

        skip_tags = self.skip_tags_entry.get_text().strip()
        if skip_tags:
            cmd.append(f'--skip-tags "{skip_tags}"')

        start_task = self.start_task_entry.get_text().strip()
        if start_task:
            cmd.append(f'--start-at-task "{start_task}"')

        self.command_entry.set_text(" ".join(cmd))

    def drop_initial_focus(self):
        """Drops focus to enter NORMAL mode on startup."""
        self.set_focus(None)
        return False # Removes the idle hook

    def on_focus_changed(self, *args):
        """Updates the Mode indicator whenever focus shifts (clicks or keys)."""
        focus_widget = self.get_focus()
        is_insert_mode = isinstance(focus_widget, (Gtk.Entry, Gtk.Text, Gtk.TextView))

        if is_insert_mode:
            self.mode_label.set_text("INSERT")
        else:
            self.mode_label.set_text("NORMAL")

    def on_key_pressed(self, controller, keyval, keycode, state):
        """Handles Vim-style mode switching."""
        focus_widget = self.get_focus()
        is_insert_mode = isinstance(focus_widget, (Gtk.Entry, Gtk.Text, Gtk.TextView))

        if keyval == Gdk.KEY_Escape:
            if is_insert_mode:
                # 1st ESC: Leave the text entry (Drop to NORMAL mode)
                self.set_focus(None)
            else:
                # 2nd ESC (or starting ESC): Exit the application
                self.close()
            return True

        # If in a text entry, let the user type normally
        if is_insert_mode:
            return False

        # convert keyval to a string character
        unicode_char = Gdk.keyval_to_unicode(keyval)
        if not unicode_char:
            return False

        key = chr(unicode_char)

        if key == 'c':
            self.dry_run_check.set_active(not self.dry_run_check.get_active())
            return True
        elif key == 'd':
            self.diff_check.set_active(not self.diff_check.get_active())
            return True
        elif key == 'D':
            self.debug_check.set_active(not self.debug_check.get_active())
            return True

        # focus jumps (enters INSERT mode or opens dropdown)
        elif key == 'h':
            self.hosts_drop.grab_focus()
            return True
        elif key == 'm':
            self.strategy_drop.grab_focus()
            return True
        elif key == 't':
            self.tags_entry.grab_focus()
            self.tags_entry.set_position(-1) # Move cursor to end of text
            return True
        elif key == 's':
            self.skip_tags_entry.grab_focus()
            self.skip_tags_entry.set_position(-1)
            return True
        elif key == 'a':
            self.start_task_entry.grab_focus()
            self.start_task_entry.set_position(-1)
            return True

        return False

    def on_launch_clicked(self, button):
        """Executes the generated command."""
        command = self.command_entry.get_text()
        print(f"Executing: {command}")

        # here you would actually launch it, e.g., using subprocess
        import subprocess
        # subprocess.Popen(command, shell=True)

class MyApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="local.ansible-provision")

    def do_activate(self):
        win = AnsibleProvisionApp(self)
        win.present()

if __name__ == "__main__":
    app = MyApp()
    app.run(None)
