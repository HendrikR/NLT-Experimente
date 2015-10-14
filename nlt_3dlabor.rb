# -*- coding: utf-8 -*-
f = File.open("TENT.3D", mode="rb")
points = []
while not f.eof
  z = f.read(4).unpack("l")[0]
  break if z == nil
  fixpt = z / (2**31).to_f
  points.push(fixpt)
end
points.shift
puts "added #{points.size} points"
f.close

require 'opengl'
require 'glu'
require 'glut'

$preshift = 0
$inshift = 0
$intershift = 0
$postshift = 0
$corners = 3
$variant = GL::POINTS
display = Proc.new {
  p = points.clone
  $preshift.times do p.shift end
  $postshift.times do p.pop; end
  GL.ClearColor(0.0, 0.0, 0.0, 1.0)
  GL.Clear(GL::COLOR_BUFFER_BIT)
  GL.Begin($variant)
  i = 0
  while p.size > 0
    GL.Color3f(1.0, i/100.0, 0.0)
    x = p.shift
    y = p.shift
    z = p.shift
    break if z==nil
    GL.Vertex3f(x, y, z)
    $inshift.times do p.shift end
    i+= 1
    if (i % $corners == 0)
      GL.End
      $intershift.times do p.shift end
      GL.Begin($variant)
    end
  end
  GL.End
  GLUT.SwapBuffers
}

reshape = Proc.new{|width, height|
  GL.Viewport(0, 0, width, height)
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity
  GLU.Perspective(90.0, 4/3.0, -2, 0)
  GL.MatrixMode(GL::MODELVIEW)
  GL.LoadIdentity
  GLU.LookAt(0, 0, -1.5,   0, 0, 0,   0, 1, 0)
  $width = width
  $height= height
}
motion = Proc.new{|x,y|
  GL.MatrixMode(GL::MODELVIEW)
  GL.LoadIdentity
  GLU.LookAt((2.0*x)/$width-1.0,  (2.0*y)/$height-1.0,  -1.5,
             0, 0, 0,
             0, 1, 0)
  GLUT.PostRedisplay
}

keyboard = Proc.new{|c|
  case (c)
  when 'q' then exit
  when 'y' then $corners -= 1
  when 'u' then $corners += 1
  when ',' then $preshift -= 1
  when 'o' then $preshift += 1
  when '.' then $inshift -= 1
  when 'e' then $inshift += 1
  when 'p' then $intershift -= 1
  when 'i' then $intershift += 1
  when 'd' then puts "c=#{$corners}, pre=#{$preshift}, in=#{$inshift}, inter=#{$intershift}"
  end
  GLUT.PostRedisplay
}

GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB)
GLUT.InitWindowSize(320, 240)
GLUT.CreateWindow("glut")
GLUT.DisplayFunc(display)
GLUT.KeyboardFunc(keyboard)
GLUT.MotionFunc(motion)
GLUT.ReshapeFunc(reshape)
GL.PointSize(3)
GL.Enable(GL::BLEND)
GLUT.MainLoop
