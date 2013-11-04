class Movement extends Base
  public:
    'movementDescription': 'description'
    'movementMinSize': 'minSize'

class MovementOne extends Movement
  public:
    'movementDescription': 'description'
    'movementMinSize': 'minSize'
    'movementOneAttribute': 'maxSize'
  defaults:
    descripton: 'Movement 1'
    maxSize: 50
    minSize: 3
  init: ()->
    console.log 'hello I\'m Movement 1'

class MovementTwo extends Movement
  public:
    'movementTwoAttribute': 'maxSize'
  defaults:
    descripton: 'Movement 2'
    maxSize: 40
    minSize: 1
  init: ()->
    console.log 'hello I\'m Movement 2'

class MovementThree extends Movement
  public:
    'movementThreeAttribute': 'maxSize'
  defaults:
    descripton: 'Movement 1'
    maxSize: 20
    minSize: 6
  init: ()->
    console.log 'hello I\'m Movement 3'

# -----------------------------------------------------------------------------
# Brush Interface:
# .x() | .y() -> get position
# .size()     -> get brush size
# .type       -> get brush type
class Brush extends Base
  defaults:
    type: 'circle'
    movementType: 'Movement 1'
    _oldMovement: 'Movement 1'
    movement: {}

  public: 
    'brushMinSize': 'sizem.value.min',
    'brushMaxSize': 'sizem.value.max',
    'brushMovementType': 'movementType',
    'brushMovement': 'movement',
    'brushType': 'type'

  startMovement: (movementClass) ->
    movementClass = movementClass or MovementOne
    @movement = new movementClass

  switchMovement: () =>
    switch @movementType
      when 'Movement 1' then @startMovement(MovementOne)
      when 'Movement 2' then @startMovement(MovementTwo)
      when 'Movement 3' then @startMovement(MovementThree)
      else @startMovement()

  init: (w, h) ->
    @pos = new Mutable
      value: new RandomPosition(0, w, 0, h)
      upmode: 'discrete'
      cycle: {
        mode: 'irregular'
        min: 900
        max: 2000
      }

    # locally change update behavior of position randomintervalnumber
    setValue = (v) -> 
      @val = if v<@min then @max else if v>@max then @min else v
      @

    @pos.value.x.setValue = setValue;
    @pos.value.y.setValue = setValue;

    @delta = new Mutable
      value: new RandomPosition -10, 10, -10, 10
      upmode: 'linp'
      cycle: 
        mode: 'irregular'
        min: 10
        max: 50

    @sizem = new Mutable
      value: new RandomIntervalNumber 2, 15
      upmode: 'linp'
      cycle: 
        mode: 'irregular'
        min: 20
        max: 100


    # initialize state (and use bound values)
    @.update() 
    @.startMovement()

  changeMovement: (movement)->

  update : ->
    @pos.update()                 # randomly spawn a new position
    @sizem.update()               # randomly set a new brush size now and then
    S = +@sizem.value
    @delta.value.setRange(-S/2,S/2,-S/2,S/2)
    @delta.update()               # interpolate moving direction
    D = @delta.valueOf()
    @pos.value.x.setValue(@pos.value.x + D.x)
    @pos.value.y.setValue(@pos.value.y + D.y)
    @bsize = S | 0
    #d=@delta.valueOf()
    #@bsize = (Math.round(Math.sqrt(d.x*d.x+d.y*d.y))*2)+1
    if(@_oldMovement isnt @movementType)
      @switchMovement()
      @_oldMovement = @movementType

  x : ->
    @pos.valueOf().x | 0

  y : ->
    @pos.valueOf().y | 0

  size : ->
    @bsize

# -----------------------------------------------------------------------------
# ImageSource abstracts a set of images, accesible by index
# width and height of ImageSource correspond to 
# the maximal width and height of images it contains
class ImageSource extends Base
  defaults: 
    width: 0
    height: 0
    images: []

  setSize: (width, height) =>
    @width = width
    @height = height

  getImageCount: =>
    @images.length

  getImage: (index) ->
    @images[index]

  addImage: (img) ->
    @images.push img

# -----------------------------------------------------------------------------
# The painter is responsible for what is going to get drawn where

# This object just defines the interface
class Painter extends Base
  #constructor: () ->
  #  @PS = new PublishSubscriber();

  # the Painter interface
  defaults:
    #Defaults
    imgSrc: null
    brushCount: 6

  start: ->
  paint: (renderer, destination) ->
  update: ->
  setImageSource: (image) ->
    @imgSrc = image

# The MovingBrushPainter is a simple painter that just copies
# brushes from multiple input images to a destination image
class MovingBrushPainter extends Painter
  setBrushes: (num) ->
    @brushCount = num
    @init

  public: 
    'brushCount': 'brushCount'

  start: =>
    # initialize brushes
    @brushes = []
    i = 0
    while i <= @brushCount
      @brushes[i] =  new Brush(@imgSrc.width, @imgSrc.height)
      ++i
  @

  paint: (renderer, dest) ->
    imgIndex = 0
    imgCount = @imgSrc.getImageCount()

    # render each brush, cycling through input images
    i = 0
    while i < @brushCount
      src = @imgSrc.getImage imgIndex
      if(!@brushes[i])
        @brushes[i] = new Brush(@imgSrc.width, @imgSrc.height)
      renderer.renderBrush @brushes[i], src, dest
      imgIndex++
      imgIndex = 0 if imgIndex is imgCount
      ++i

  update: ->
    for br in @brushes
      br.update()
    @
