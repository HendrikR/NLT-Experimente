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
  # TODO: Subtyp
  $builder.get_object("cTypUse" ).set_active(item.typ&0x04 != 0)
  $builder.get_object("cTypEat" ).set_active(item.typ&0x08 != 0)
  $builder.get_object("cTypStk" ).set_active(item.typ&0x10 != 0)
  $builder.get_object("cTypPers").set_active(item.typ&0x40 != 0)
  $builder.get_object("sortiment").set_value(item.sortiment)
  $builder.get_object("preis"    ).set_value(item.preis)
  $builder.get_object("gewicht"  ).set_value(item.gewicht)
  $builder.get_object("magic"    ).set_active(item.magic != 0)
  $builder.get_object("important").set_active(item.i_entry != 0)
end

def update_data(index)
  item = $items[index]
  gui_index = $builder.get_object("item_id").text.to_i
  name      = $builder.get_object("name").text #TODO: Singular/Plural
  #$builder.get_object("icon").text = item.icon.to_s
  case($builder.get_object("typ").active)
  when 0 then item.typ = 0x01
  when 1 then item.typ = 0x02
  when 2 then item.typ = 0x20
  else        item.typ = 0x00
  end
  #if ($builder.get_object("bSubtyp").sensitive?)
  #end
  if $builder.get_object("cTypUse" ).active? then item.typ |= 0x04; end
  if $builder.get_object("cTypEat" ).active? then item.typ |= 0x08; end
  if $builder.get_object("cTypStk" ).active? then item.typ |= 0x10; end
  if $builder.get_object("cTypPers").active? then item.typ |= 0x40; end
  item.sortiment = $builder.get_object("sortiment").value.to_i
  item.preis     = $builder.get_object("preis"    ).value.to_i
  item.gewicht   = $builder.get_object("gewicht"  ).value.to_i
  item.magic     = $builder.get_object("magic"    ).active? ? 1 : 0
  item.i_entry   = $builder.get_object("important").active? ? 1 : 0
  $items[index] = item
end

def make_gui
  # Construct a GtkBuilder instance and load our UI description
  $builder = Gtk::Builder::new
  $builder.add_from_file("editor_items.glade")
  window = $builder.get_object("window")
  make_adjustment($builder.get_object("sortiment"), 0, 255, 0)
  make_adjustment($builder.get_object("preis"),     0, 255, 0)
  make_adjustment($builder.get_object("gewicht"),   0, 255, 0)
  
=begin
  item_id = $builder.get_object("item_id")
  item_id.set_events($builder.get_object("bPrev").events)
  item_id.add_events(Gdk::EventMask::SCROLL_MASK | Gdk::EventMask::SMOOTH_SCROLL_MASK | Gdk::EventMask::BUTTON_PRESS_MASK)
  item_id.signal_connect("scroll-event") {|widget, event, user_data|
    puts "scroll"
  }
  item_id.signal_connect("button-press-event") {|widget, event, user_data|
    puts "button"
  }
=end
  $builder.get_object("bPrev").signal_connect("clicked") {
    update_data($item_index)
    $item_index = $item_index - 1 % $items.size
    if $item_index < 0 then $item_index = 0; end
    update_gui($item_index)
  }
  $builder.get_object("bNext").signal_connect("clicked") {
    update_data($item_index)
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
  $builder.get_object("bSave").signal_connect("clicked") {
    $items[$item_index].write
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
