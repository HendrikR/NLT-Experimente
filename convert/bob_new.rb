# -*- coding: utf-8 -*-
require './images.rb'

class BOB_NEW < ImageGroup
  def read(filename)
    # TODO: alles kaputt. Führe die Infos aus dem BrightEyes-Wiki und deiner .org-Datei zusammen.
    file = File.open(filename, IO::BINARY)
    bob_sig = file.read(3).unpack("a*")[0]
    raise "Error: invalid signature #{bob_sig} for new BOB file, should be BOB" if bob_sig != "BOB"
    bob_version = file.read16
    raise "Error: unknown BOB version #{bob_version}, should be 0x0101" if bob_version != 0x0101
    @parts = Array.new(file.read08){ ImageList.new }
    bob_unk01 = file.read16
    raise_unknown "Error: unexpected value #{bob_unk01} at offset #{file.tell-2}, should be 0x010A" if bob_unk01 != 0x010A
    bob_unk02 = file.read(8).unpack("C*")

    puts "reading #{@parts.size} image parts"
    for i in 0...@parts.size do
      bob_part_imgs1 = file.read08
      bob_part_imgs2 = file.read08
      raise "Error: image counts do not match: #{bob_part_imgs1} != #{bob_part_imgs2}" if bob_part_imgs1 != bob_part_imgs2
      bob_unk03 = file.read16
      ###raise "Error: unexpected value #{bob_unk03} at offset #{file.tell-2}, should be 0x0000" if bob_unk03 != 0x0000
      @parts[i].images = Array.new(bob_part_imgs2) { Image.new }
    end

    ##file.seek(4*8, IO::SEEK_CUR) # TODO: both are wrong.
    file.seek(0x141)

    for i in 0...@parts.size do
      puts "read part at #{file.tell}"
      @parts[i].name = file.read(4).unpack("a*")[0]
      d_x0, bob_unk04, d_y0, d_h, d_w = file.read(5).unpack("CCCCC")
      raise "Error: unexpected value #{bob_unk04} at offset #{file.tell-1}, should be 0x0000" if bob_unk04 != 0x00
      @parts[i].dimensions = Rect.new(d_x0, d_y0, d_w, d_h)
      bob_unk05 = file.read16
      raise "Error: unexpected value #{bob_unk05} at offset #{file.tell-2}, should be 0x0000" if bob_unk05 != 0x0000
      bob_part_imgs3 = file.read08
      raise "Error: image counts do not match: #{@parts[i].images.size} != #{bob_part_imgs3}" if bob_part_imgs1 != bob_part_imgs3
      bob_unk06_size = file.read16
      bob_unk06 = file.read(bob_unk06_size)
      puts "img part #{@parts[i].name} has #{@parts[i].images.size} frames size #{@parts[i].dimensions}"
    end

    for part in @parts do
      for i in 0...part.images.size do
        part.images[i].data = read(part.images[i].dimensions.size)
      end
    end
    file.close
  end

  def write(filename)
    # TODO
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write("BOB") # magic number
    file.write16 0x0101 # Version?
    file.write08 @parts.size
    file.write16 0x010A # unknown
    file.write   Array.new(8,0).pack("C*") # unknown, always 0 (except for SMAGIER.BOB)

    for part in @parts do
      file.write08 part.images.size # TODO: this is also in the part header, why?
      file.write08 part.images.size # for some reason, this is saved twice
      file.write16 0x0000 # unknown
    end

    # TODO: Teilanimations-Miniheader
    # Image header
    for part in @parts do
      for img in part.images do
        file.write16 img.dimensions.width
        file.write16 img.dimensions.height
        # TODO: unknown stuff below here
        file.write16 0x0000 # runlength of following unknown data
        file.write   ""     # unknown data
      end
    end

    for part in @parts do
      file.write   part.name[0..3]
      file.write08 part.dimensions.x0
      file.write08 0x00 # TODO: unknown, maybe high bit for x0?
      file.write08 part.dimensions.y0
      file.write08 part.dimensions.height # yes, height comes first
      file.write08 part.dimensions.width
      # TODO: unknown stuff below here
      file.write16 0x0000 # TODO: unknown
      file.write08 part.images.size
      part.images.size.times{ file.write32 0 } # TODO: unknown
      file.write16 0x00 # runlength of following unknown data
      file.write   "" # unknown data
    end

    # Header done, now write the image data
    for part in @parts do
      for img in part.images do
        # TODO: does BOB support compression?
        file.write img.data
      end
    end
    file.close
  end
end
