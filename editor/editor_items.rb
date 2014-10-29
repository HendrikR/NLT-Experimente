#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Itemviewer für DSA2/RoA2: Sternenschweif (ITEMS.DAT)

require 'gtk3'
load "items.rb"

$item_index = 7
$items = []

def update_gui(index)
  item = $items[index]
  $builder.get_object("item_id").set_text(index.to_s)
  $builder.get_object("name").set_text(item.name_s)
  #$builder.get_object("icon").set_text(item.icon.to_s)
  if    item.typ & 0x01 != 0 then $builder.get_object("typ").set_active(0); $builder.get_object("bSubtyp").set_sensitive(true)
  elsif item.typ & 0x02 != 0 then $builder.get_object("typ").set_active(1); $builder.get_object("bSubtyp").set_sensitive(true)
  elsif item.typ & 0x20 != 0 then $builder.get_object("typ").set_active(2); $builder.get_object("bSubtyp").set_sensitive(true)
  else                            $builder.get_object("typ").set_active(3); $builder.get_object("bSubtyp").set_sensitive(false)
  end
end

def make_gui
  # Construct a GtkBuilder instance and load our UI description
  $builder = Gtk::Builder::new
  $builder.add_from_file("editor_items.glade")
  window = $builder.get_object("window")
  
  $builder.get_object("bPrev").signal_connect("clicked") {
    $item_index = $item_index - 1 % $items.size
    update_gui($item_index)
  }
  $builder.get_object("bNext").signal_connect("clicked") {
    $item_index = $item_index + 1 % $items.size
    update_gui($item_index)
  }
  $builder.get_object("bSubtyp").signal_connect("clicked") {
    case($builder.get_object("typ").active())
    when 0 then make_subwindow_armor
    when 1 then make_subwindow_weapon
    when 2 then make_subwindow_kraut_elixir
    else raise "Error: Trying to edit subtype with strange main type."
    end
  }
  
  window.signal_connect("destroy") {
    puts "Goodbye, World!"
    Gtk::main_quit
  }

  update_gui($item_index)
  window.show_all
  Gtk::main
end

def make_adjustment(spin, min, max, val)
  adj = Gtk::Adjustment.new(val, min, max, 1.0, 10.0, 0.0)
  spin.set_adjustment(adj)
end

def make_subwindow_weapon
  window = $builder.get_object("sw_window")
  weapon = $items[$item_index].fk_object
  window.signal_connect("destroy") {
    window.hide_all
  }

  make_adjustment($builder.get_object("sw_edTPW"),      0, 255, weapon.tp_w6)
  make_adjustment($builder.get_object("sw_edTPMod"), -127, 127, weapon.tp_add);
  make_adjustment($builder.get_object("sw_edKK"),       0, 255, weapon.kk_zuschlag)
  make_adjustment($builder.get_object("sw_edBF"),       0, 255, weapon.bf);
  make_adjustment($builder.get_object("sw_edAT"),    -127, 127, weapon.mod_at)
  make_adjustment($builder.get_object("sw_edPA"),    -127, 255, weapon.mod_pa);
  make_adjustment($builder.get_object("sw_edUnk1"),     0, 255, weapon.unk1)
  make_adjustment($builder.get_object("sw_edUnk2"),     0, 255, weapon.unk2);

  window.show_all
end

def make_subwindow_armor
  window = $builder.get_object("sa_window")
  armor  = $items[$item_index].fk_object
  make_adjustment($builder.get_object("sa_edRS"), -127, 127, armor.rs)
  make_adjustment($builder.get_object("sa_edBE"), -127, 127, armor.be);
  
  window.show_all
end

def make_subwindow_kraut_elixir
end

$items = read_items
make_gui
