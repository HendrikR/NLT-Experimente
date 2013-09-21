# -*- coding: utf-8 -*-
f = File.open("TENT.3D", mode="rb")
points = []
f.seek(0x196)
while not f.eof
  z = f.read(2).unpack("s")[0]
  fixpt = z / (2**15).to_f
  points.push(fixpt)
end
i = 0
for p in points.each
  printf "%f" % p
  if i < 2
    i+=1
    printf ", "
  else
    i=0;
    printf "\n"
  end
end
f.close

require 'opengl'
require 'glu'
require 'glut'

$preshift = 0
$inshift = 0
$intershift = 0
$corners = 3
$variant = GL::POINTS
display = Proc.new {
  p = points.clone
  GL.ClearColor(0.0, 0.0, 0.0, 1.0)
  GL.Clear(GL::COLOR_BUFFER_BIT)
  GL.Begin($variant)
  i = 0
  for j in 0...$preshift do p.shift end
  while p.size > 0
    GL.Color3f(1.0, i/100.0, 0.0)
    GL.Vertex3f(p.shift, p.shift, 0.0)
    for j in 0...$inshift do p.shift end
    i+= 1
    if (i % $corners == 0)
      GL.End
      for j in 0...$intershift do p.shift end
      GL.Begin($variant)
    end
  end
=begin
  while p.size > 0
    GL.Vertex3f(p.shift, p.shift, p.shift)
  end
=end
  GL.End
  GLUT.SwapBuffers
}

reshape = Proc.new{|width, height|
  GL.Viewport(0, 0, width, height)
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity
  GLU.Perspective(90.0, 4/3.0, -2, 0)
  GL.MatrixMode(GL::MODELVIEW)
  GLU.LookAt(0, 0, -1.5,   0, 0, 0,   0, 1, 0)
}
motion = Proc.new{|x,y|
  GL.MatrixMode(GL::MODELVIEW)
  GL.LoadIdentity
  GLU.LookAt(x/160.0, y/210.0, -1.5,   0, 0, 0,   0, 1, 0)
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
GLUT.IdleFunc(Proc.new{GLUT.PostRedisplay})
GLUT.ReshapeFunc(reshape)
GL.PointSize(3)
GL.Enable(GL::BLEND)
GLUT.MainLoop
