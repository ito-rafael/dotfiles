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

        # Added min-height override to textview to allow it to shrink fully
        css_data = b"""
        .small-cmd { font-size: 0.7em; }
        textview.small-cmd { min-height: 10px; }
        checkbutton label { margin-left: 10px; }
        .small-mode { font-size: 0.8em; }
        separator.thick-sep { min-width: 3px; min-height: 3px; }
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

        # SINGLE GRID setup
        grid = Gtk.Grid(row_spacing=15, column_spacing=12)
        grid.set_halign(Gtk.Align.CENTER)
        main_box.append(grid)

        # Header Box
        header_box = Gtk.CenterBox()

        # left logo
        left_logo = Gtk.Picture.new_for_filename("../icon/ansible.png")
        left_logo.set_size_request(50, 50)
        left_logo.set_content_fit(Gtk.ContentFit.CONTAIN)
        left_logo.set_margin_start(15)
        header_box.set_start_widget(left_logo)

        # title text
        header = Gtk.Label(label="<span size='x-large' weight='bold'>ansible-provision</span>")
        header.set_use_markup(True)
        header_box.set_center_widget(header)

        # right logo
        right_logo = Gtk.Picture.new_for_filename("../icon/semaphore-ui.png")
        right_logo.set_size_request(50, 50)
        right_logo.set_content_fit(Gtk.ContentFit.CONTAIN)
        right_logo.set_margin_end(15)
        header_box.set_end_widget(right_logo)

        grid.attach(header_box, 0, 0, 5, 1)

        # hosts (h) - Row 1
        grid.attach(Gtk.Label(label="Hosts (h)", halign=Gtk.Align.START), 0, 1, 1, 1)
        self.hosts_drop = Gtk.DropDown.new(Gtk.StringList.new(["localhost", "LBiC", "homelab", "rootless"]))
        self.hosts_drop.connect("notify::selected", self.update_command)
        grid.attach(self.hosts_drop, 1, 1, 1, 1)

        # strategy (m) - Row 4
        grid.attach(Gtk.Label(label="Strategy (m)", halign=Gtk.Align.START), 0, 4, 1, 1)
        self.strategy_drop = Gtk.DropDown.new(Gtk.StringList.new(["Mitogen", "Linear"]))
        self.strategy_drop.connect("notify::selected", self.update_command)
        grid.attach(self.strategy_drop, 1, 4, 1, 1)

        # tags (t) - Row 2
        grid.attach(Gtk.Label(label="Tags (t)", halign=Gtk.Align.START), 0, 2, 1, 1)
        self.tags_entry = Gtk.Entry(placeholder_text="e.g. brave")
        self.tags_entry.connect("changed", self.update_command)
        grid.attach(self.tags_entry, 1, 2, 1, 1)

        # skip tags (s) - Row 3
        grid.attach(Gtk.Label(label="Skip tags (s)", halign=Gtk.Align.START), 0, 3, 1, 1)
        self.skip_tags_entry = Gtk.Entry(placeholder_text="e.g. emacs")
        self.skip_tags_entry.connect("changed", self.update_command)
        grid.attach(self.skip_tags_entry, 1, 3, 1, 1)

        # Spring 1: Vertical separator
        v_sep = Gtk.Separator(orientation=Gtk.Orientation.VERTICAL)
        v_sep.add_css_class("thick-sep")
        v_sep.set_halign(Gtk.Align.CENTER)
        v_sep.set_hexpand(True)
        grid.attach(v_sep, 2, 1, 1, 4)

        # options label
        grid.attach(Gtk.Label(label="<b>Options:</b>", use_markup=True, halign=Gtk.Align.START), 3, 1, 1, 1)

        # dry run (c)
        self.dry_run_check = Gtk.CheckButton(label="Dry run (c)")
        self.dry_run_check.connect("toggled", self.update_command)
        grid.attach(self.dry_run_check, 3, 2, 1, 1)

        # diff (d)
        self.diff_check = Gtk.CheckButton(label="Diff (d)")
        self.diff_check.connect("toggled", self.update_command)
        grid.attach(self.diff_check, 3, 3, 1, 1)

        # debug (D)
        self.debug_check = Gtk.CheckButton(label="Debug (D)")
        self.debug_check.connect("toggled", self.update_command)
        grid.attach(self.debug_check, 3, 4, 1, 1)

        # Spring 2: Invisible dummy box
        right_spring = Gtk.Box()
        right_spring.set_hexpand(True)
        grid.attach(right_spring, 4, 1, 1, 4)

        # start at task (a)
        task_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        task_box.append(Gtk.Label(label="Start at task (a)", halign=Gtk.Align.START))
        self.start_task_entry = Gtk.Entry(placeholder_text="Search tasks...", hexpand=True)
        self.start_task_entry.connect("changed", self.update_command)
        task_box.append(self.start_task_entry)
        grid.attach(task_box, 0, 5, 5, 1)

        # horizontal separator
        h_sep = Gtk.Separator(margin_top=5, margin_bottom=5)
        h_sep.add_css_class("thick-sep")
        grid.attach(h_sep, 0, 6, 5, 1)

        # command
        cmd_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        cmd_box.append(Gtk.Label(label="Command:", halign=Gtk.Align.START))

        self.command_scroll = Gtk.ScrolledWindow(hexpand=True)
        self.command_scroll.set_has_frame(True)

        # CHANGED: These properties strip GTK's safety nets and allow a true 1-line height
        self.command_scroll.set_min_content_height(1)
        self.command_scroll.set_propagate_natural_height(True)
        self.command_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER)

        self.command_view = Gtk.TextView()
        self.command_view.set_editable(False)
        self.command_view.set_cursor_visible(False)
        self.command_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.command_view.add_css_class("monospace")
        self.command_view.add_css_class("small-cmd")

        # Snug interior padding for the small font
        self.command_view.set_left_margin(8)
        self.command_view.set_right_margin(8)
        self.command_view.set_top_margin(4)
        self.command_view.set_bottom_margin(4)

        self.command_scroll.set_child(self.command_view)
        cmd_box.append(self.command_scroll)

        grid.attach(cmd_box, 0, 7, 5, 1)

        # left: Mode Indicator
        self.mode_label = Gtk.Label(label="NORMAL")
        self.mode_label.add_css_class("dim-label")
        self.mode_label.add_css_class("small-mode")
        self.mode_label.set_halign(Gtk.Align.START)
        self.mode_label.set_margin_top(10)
        grid.attach(self.mode_label, 0, 8, 1, 1)

        # center: Action buttons
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_box.set_halign(Gtk.Align.CENTER)
        btn_box.set_margin_top(10)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda b: self.close())
        btn_box.append(cancel_btn)

        launch_btn = Gtk.Button(label="Launch")
        launch_btn.add_css_class("suggested-action")
        launch_btn.connect("clicked", self.on_launch_clicked)
        btn_box.append(launch_btn)

        grid.attach(btn_box, 1, 8, 4, 1)

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

        # Gtk.TextView requires fetching the buffer to set text
        self.command_view.get_buffer().set_text(" ".join(cmd))

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
        # Gtk.TextView requires reading from the buffer's bounds
        buffer = self.command_view.get_buffer()
        start, end = buffer.get_bounds()
        command = buffer.get_text(start, end, True)

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
