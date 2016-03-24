--- 
layout: post
title: DBus vs. Schlange
date: 2011-02-19 05:08:51 +01:00
category: Nokia N900
---
Eigentlich war ja von Anfang an klar, dass es nicht bei dem Lauschangriff auf DBus mittels C-Code bleibt, das Crosskompilieren ist schlichtweg einfach zu lästig im Umgang mit dem N900.  Nach nur wenigen Stunden der Rätselei (zugegeben, ich kann nicht wirklich gut Python, aber die Auswirkung hierauf dürfte eher marginal sein) wie das Python-DBus Modul im Innersten wohl funktioniert, hier jetzt die Lösung wie man die Desktop-Benachrichtigungen in einem Skript abfangen und weiterverbarbeiten kann:

    import gobject
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    
    def msg_filter(_bus, msg):
        if msg.get_member() != "Notify": return
        args = msg.get_args_list()
        print "%s:%s" % (args[3], args[4])
    
    if __name__ == '__main__':
        DBusGMainLoop(set_as_default = True)
        bus = dbus.SessionBus()
        bus.add_match_string("type='method_call',interface='org.freedesktop.Notifications'")
        bus.add_message_filter(msg_filter)
        gobject.MainLoop().run()</pre>

... nennen wir das Kind _notify-spy_, Lizenz GPLv3+
