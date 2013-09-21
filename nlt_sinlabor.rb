f = File.open("TENT2.3D", mode="rb")
points = []
f.seek(0x192)
while not f.eof
  z = f.read(2).unpack("S")[0] # lese einen unsigned short.
  fixpt = z / (2**16).to_f
  points.push(fixpt)
  puts fixpt
end
f.close

require 'opengl'
require 'glu'
require 'glut'

display = Proc.new {
  i = 0
  GL.ClearColor(0.0, 0.0, 0.0, 1.0)
  GL.Clear(GL::COLOR_BUFFER_BIT)
  GL.Begin(GL::LINE_STRIP)
  for i in 0...(points.size/2)
    GL.Color3f(1.0, 2*i / points.size, 0.0)
    GL.Vertex2f(points[2*i], points[2*i+1])
  end
  GL.End
  GLUT.SwapBuffers
}

reshape = Proc.new{|width, height|
  GL.Viewport(0, 0, width, height)
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity
  GL.Ortho(-1.0, 1.0,   -1.0, 1.0,   -1.0,1.0)
  GL.MatrixMode(GL::MODELVIEW)
  GL.LoadIdentity
}

GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB)
GLUT.InitWindowSize(320, 240)
GLUT.CreateWindow("glut")
GLUT.DisplayFunc(display)
GLUT.KeyboardFunc(Proc.new{exit})
GLUT.IdleFunc(Proc.new{GLUT.PostRedisplay})
GLUT.ReshapeFunc(reshape)
GL.PointSize(3)
GL.Enable(GL::BLEND)
GLUT.MainLoop
