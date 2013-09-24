require 'opengl'
require 'glut'

class Route
  attr_accessor :points, :meta1, :meta2, :meta3, :meta4
  def initialize
    @meta1 = @meta2 = @meta3 = @meta4 = 0
    @points = Array.new
  end
  def addPoint(x,y)
    @points << [x,y]
  end
end
$routes = Array.new(263)

display = Proc.new do
  GL.Clear(GL::COLOR_BUFFER_BIT)
  $routes.each do |r|
    #if r.meta2 > 1 then next; end
    GL.Begin(GL::POINTS)
    GL.Color3f(1, r.meta3/256.0, r.meta4/256.0)
    r.points.each do |p|
      if p[0] > 560 or p[1] > 602 then p p; end
      GL.Vertex2d(p[0], p[1])
    end
    GL.End
  end
  GLUT.SwapBuffers
end

reshape = Proc.new{|width, height|
  GL.Viewport(0, 0, width, height)
  GL.MatrixMode(GL::PROJECTION)
  GL.LoadIdentity
  GL.Ortho(0, 560,  640,0, -1.0, 1.0)
  GL.MatrixMode(GL::MODELVIEW)
}

fl = File.new("SUBLOCS.DAT", "rb")
subloc_data = Array.new(270)
for i in 0...270 do
  data = fl.read(2).bytes
  subloc_data[i] = [data[0], data[1]]
end


f = File.new("ROUTES.DAT", "rb")
for i in 0...263 do
  data = f.read(4).clone.bytes
  $routes[i] = Route.new
  $routes[i].meta1 = data[0]
  $routes[i].meta2 = data[1] + (data[2] << 8)
  if subloc_data[$routes[i].meta2] != nil
    $routes[i].meta3 = subloc_data[$routes[i].meta2][0]
    $routes[i].meta4 = subloc_data[$routes[i].meta2][1]
  else
    $routes[i].meta3 = $routes[i].meta4 = 0x00;
    puts "no such subloc data: #{$routes[i].meta2}"
  end
end

i = 0
while (data = f.read(4)) do
  data = data.bytes
  x = (data[1] << 8) + data[0]
  y = (data[3] << 8) + data[2]
  if x == 0xFFFF
    printf("%d\n", $routes[i].meta4)
    i+= 1
  else
    $routes[i].addPoint(x,y)
  end
end
f.close

GLUT.Init
GLUT.InitDisplayMode(GLUT::DOUBLE | GLUT::RGB)
GLUT.InitWindowSize(560, 640)
GLUT.CreateWindow("glut")
GLUT.DisplayFunc(display)
GLUT.KeyboardFunc(Proc.new{exit})
#GLUT.IdleFunc(Proc.new{GLUT.PostRedisplay})
GLUT.ReshapeFunc(reshape)
GL.PointSize(1)
#GL.BlendFunc(GL::SRC_ALPHA, GL::ONE_MINUS_SRC_ALPHA)
#GL.Enable(GL::BLEND)
GLUT.MainLoop
