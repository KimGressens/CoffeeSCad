define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  csg = require 'csg'
  THREE = require 'three'
  THREE.CSG = require 'three_csg'
  threedView_template = require "text!templates/3dview.tmpl"
  requestAnimationFrame = require 'anim'
  
  class GlViewSettings extends Backbone.Model
      defaults:
        antialiasing : true
        showGrid     : false
        showAxis     : true 
  
  #just for testing
  
  class MyAxisHelper
    constructor:(size, xcolor, ycolor, zcolor)->
      geometry = new THREE.Geometry()
      
      geometry.vertices.push(
        new THREE.Vector3(-size or -1, 0, 0 ), new THREE.Vector3( size or 1, 0, 0 ),
        new THREE.Vector3(0, -size or -1, 0), new THREE.Vector3( 0, size or 1, 0 ),
        new THREE.Vector3(0, 0, -size or -1 ), new THREE.Vector3( 0, 0, size or 1 )
        )
        
      geometry.colors.push(
        new THREE.Color( xcolor or 0xffaa00 ), new THREE.Color( xcolor or 0xffaa00 ),
        new THREE.Color( ycolor or 0xaaff00 ), new THREE.Color( ycolor or 0xaaff00 ),
        new THREE.Color( zcolor or 0x00aaff ), new THREE.Color( zcolor or 0x00aaff )
        )
        
      material = new THREE.LineBasicMaterial
        vertexColors: THREE.VertexColors
        #depthTest:false
        linewidth:2
      
      return new THREE.Line(geometry, material, THREE.LinePieces)
      #return THREE.Line.call( @, geometry, material, THREE.LinePieces )
  
  
  
  class GlThreeView extends marionette.ItemView
    template: threedView_template
    ui:
      renderBlock : "#glArea"
      overlayBlock: "#glOverlay" 
    events:
    #  'mousemove'   : 'mousemove'
    #  'mouseup'     : 'mouseup'
      'mousewheel'  : 'mousewheel'
      'mousedown'   :   'mousedown'#'dragstart'
      'contextmenu': 'rightclick'
      
    rightclick:(ev)=>
      #console.log "you clicked right"
    mousewheel:(ev)=>
      ###ev = window.event or ev; # old IE support  
      delta = Math.max(-1, Math.min(1, (ev.wheelDelta or -ev.detail)))
      delta*=75
      if delta - @camera.position.z <= 100
        @camera.position.z-=delta
      return false
      ###
      
    
    mousemove:(ev)->
      if @dragStart?
        moveMinMax = 10
        
        @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
        #@dragAmount[1]=@height-@dragAmount[1]
        #console.log "bleh #{@dragAmount[0]/500}"
        x_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[0]/10))
        y_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[1]/10))
        #x_move = (x_move/x_move+0.0001)*moveMinMax
        #y_move = (y_move/y_move+0.0001)*moveMinMax
        #console.log("moving by #{y_move}")
        @camera.position.x+=  x_move #@dragAmount.x/10000
        @camera.position.y-=  y_move#@dragAmount.y/100
        return false
        
    dragstart:(ev)=>
      @dragStart={'x':ev.offsetX, 'y':ev.offsetY}
      
    mouseup:(ev)=>
      if @dragStart?
        @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
        @dragStart=null
      ###console.log ev
      console.log "clientX: #{ev.clientX} clientY: #{ev.clientY}"
      console.log "clientX: #{ev.offsetX} clientY: #{ev.offsetY}"
      ###
      
      x = ev.offsetX
      y = ev.offsetY
      v = new THREE.Vector3((x/@width)*2-1, -(y/@height)*2+1, 0.5)
      
    mousedown:(ev)=> 
      x = ev.offsetX
      y = ev.offsetY
      #console.log ("x: #{x}, y: #{y}")
      
      ###for i in [0...10000]
         p = new THREE.Vector3(Math.random() * 800,Math.random() * 600,Math.random() * 300-250)
         @selectObj(p.x,p.y)
      ###
      @selectObj(x,y)
      #if @current?
      #  @toCsgTest @current
      
             
    selectObj:(mouseX,mouseY)=>
      v = new THREE.Vector3((mouseX/@width)*2-1, -(mouseY/@height)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      ray = new THREE.Ray(@camera.position, v.subSelf(@camera.position).normalize())
      intersects = ray.intersectObjects(@controller.objects)
      
      reset_col=()=>
        if @current?
          #newMat = new THREE.MeshLambertMaterial
          #  color: 0xCC0000
          #@current.material = newMat
          @current.material = @current.origMaterial
          if @current.cageView?
            @scene.remove @current.cageView
          @current=null
          
      draw_impact=(position)=>
        #particle = new THREE.Particle(@particleMaterial)
        #particle.position = position 
        #particle.scale.x = particle.scale.y = 80
        #@scene.add( particle )
        
        sprite = new THREE.Sprite(
          map: @particleTexture
          transparent: true
          useScreenCoordinates: false
          scaleByViewport:false)
        sprite.position = position
       # sprite.position.x = sprite.position.Y = sprite.position.z = 100
        @scene.add(sprite)
        
        #xLabel=@drawText("X")
        #xLabel.position=position
       # @scene.add(xLabel)
        
          
      if intersects? 
        #console.log "interesects" 
        #console.log intersects
        if intersects.length > 0
          
          #display impact
          #draw_impact(intersects[ 0 ].point)
          
          if intersects[0].object.name != "workplane"
            if @current != intersects[0].object
              @current = intersects[0].object
              newMat = new  THREE.MeshLambertMaterial
                color: 0xCC0000
              #newMat = new THREE.MeshBasicMaterial({color: 0x808080, wireframe: true, shading:THREE.FlatShading})
              #newMat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
                
              @current.origMaterial = @current.material
              @current.material = newMat
              @addCage @current
              if @current.cageView?
                @scene.add @current.cageView
              
              
          else
            reset_col()
        else
          reset_col()
      else
        reset_col()
    
    modelChanged:(model, value)=>
      #console.log "model changed"
      @fromCsg @model
      
      
    constructor:(options, settings)->
      super options
      settings = options.settings
      @bindTo(@model, "change", this.modelChanged)
      #Controls:
      @dragging = false
      ##########
      
      @width = 800
      @height = 600
      
      #camera attributes
      @viewAngle=45
      ASPECT = @width / @height
      NEAR = 1
      FAR = 10000
      
      @renderer = new THREE.WebGLRenderer 
        clearColor: 0x00000000
        clearAlpha: 0
        antialias: true
      @renderer.clear()  
      
      @camera =
        new THREE.PerspectiveCamera(
          @viewAngle,
          ASPECT,
          NEAR,
          FAR)
      #the camera starts at 0,0,0
      #so pull it back
      @camera.position.z = 300
      @camera.position.y = 150
      @camera.position.x = 150
          
      @scene = new THREE.Scene()
      @scene.add(@camera)
      
      #@addObjs()
      #@addObjs2()
      @setupLights()
      
      #TODO: do this properly
      #antialiasing : true
      #  showGrid     : true
      #  showAxis     : true 
      if settings
        console.log ("we have settings")
        if settings.get("showGrid")
          @addPlane()
        if settings.get("showAxis")
          @addAxes()
      #@addCage()
      
      @renderer.setSize(@width, @height)
  
      @controller = new THREE.Object3D()      
      @controller.setCurrent = (current)=>
        @current = current
        
      @controller.objects = []
      @projector = new THREE.Projector()
      
      @controls = new THREE.OrbitControls(@camera)
      @controls.autoRotate = false
      
      
      
      #########
      #Experimental overlay
      #viewAngle=45
      ASPECT = 800 / 600
      #NEAR = 1
      #FAR = 10000
      
      @overlayRenderer = new THREE.WebGLRenderer 
        clearColor: 0x000000
        clearAlpha: 0
        antialias: true
      
     # @overlayCamera =
      #  new THREE.OrthographicCamera(-200,200,150,-150,NEAR, FAR)
        
      @overlayRenderer.setSize(400, 300)
      @overlayCamera =
        new THREE.PerspectiveCamera(@viewAngle,ASPECT, NEAR, FAR)
      
      @overlayCamera.position.z = 300
      @overlayCamera.position.y = 150
      @overlayCamera.position.x = 150
            
      @overlayscene = new THREE.Scene()
      @overlayscene.add(@overlayCamera)
      
      @overlayControls = new THREE.OrbitControls(@overlayCamera)
      @overlayControls.autoRotate = false
      
      @xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),100, 0xFF7700)
      @yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,0),100, 0x77FF00)
      @zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),100, 0x0077FF)
     
      @overlayscene.add(@xArrow)
      @overlayscene.add(@yArrow)
      @overlayscene.add(@zArrow)
      ###
        for i in [-250..250]
        text = @drawText()
        text.position.set(Math.random() * 300-200,Math.random() * 300+100,Math.random() * 300-250)
        @overlayscene.add(text)
      ###
      xLabel=@drawText("X")
      xLabel.position.set(120,20,0)
      @overlayscene.add(xLabel)
      
      yLabel=@drawText("Y")
      yLabel.position.set(0,20,110)
      @overlayscene.add(yLabel)
      
      zLabel=@drawText("Z")
      zLabel.position.set(-15,140,-15)
      @overlayscene.add(zLabel)
      
      canvas = document.createElement('canvas')
      canvas.width = 100
      canvas.height = 100
      context = canvas.getContext('2d')
  
      PI2 = Math.PI * 2
      context.beginPath()
      context.arc( 0, 0, 1, 0, PI2, true )
      context.closePath()
      context.fill()
      context.fillText("X", 40, 40)

      texture = new THREE.Texture( canvas )
      texture.needsUpdate = true

      @particleTexture = new THREE.Texture(canvas)
      @particleTexture.needsUpdate = true
      
      @particleMaterial = new THREE.MeshBasicMaterial( { map: texture, transparent: true ,color: 0x000000} );

      


      ###
      context.fillStyle = "yellow";
      context.fillRect(0, 0, 100, 100);
      context.font = "24pt Arial";
      context.textAlign = "center";
      context.textBaseline = "middle";
      context.fillStyle = "white";
      context.fillText(text, 0, 0);
      ###

        
    addObjs2: () =>
      @cube = new THREE.Mesh(new THREE.CubeGeometry(50,50,50),new THREE.MeshBasicMaterial({color: 0x000000}))
      @scene.add(@cube)
      
    addObjs: () =>
      #set up material
      sphereMaterial =
      new THREE.MeshLambertMaterial
        color: 0xCC0000
      
      radius = 50
      segments = 16
      rings = 16

      sphere = new THREE.Mesh(
      
        new THREE.SphereGeometry(
          radius,
          segments,
          rings),
      
        sphereMaterial)
      sphere.name="Shinyyy"
      @scene.add(sphere)
      
    setupLights:()=>
      pointLight =
        new THREE.PointLight(0x333333,5)
      pointLight.position.x = -2200
      pointLight.position.y = -2200
      pointLight.position.z = 3000

      @ambientColor = '0x253565'
      ambientLight = new THREE.AmbientLight(@ambientColor);
      
      spotLight = new THREE.SpotLight( 0xbbbbbb, 2 )    
      spotLight.position.x = 0
      spotLight.position.y = 1000
      spotLight.position.z = 0
      
      @scene.add(ambientLight);
      @scene.add(pointLight)
      @scene.add( spotLight )
      
    addPlane:()=>
      planeGeo = new THREE.PlaneGeometry(500, 500, 5, 5)
      planeMat = new THREE.MeshBasicMaterial({color: 0x808080, wireframe: true, shading:THREE.FlatShading})
      #planeMat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
      #planeMat = new THREE.MeshLambertMaterial({color: 0xFFFFFF})
      plane = new THREE.Mesh(planeGeo, planeMat)
      plane.rotation.x = -Math.PI/2
      plane.position.y = -30
      plane.name = "workplane"
      #plane.receiveShadow = true
      @scene.add(plane)
      
    addAxes:()->
      axes = new MyAxisHelper(200,0x666666,0x666666, 0x666666)
      @scene.add(axes)
      
    addCage:(mesh)=>
      bbox = mesh.geometry.boundingBox
      length = bbox.max.x-bbox.min.x
      width  = bbox.max.y-bbox.min.y
      height = bbox.max.z-bbox.min.z
      
      cageGeo= new THREE.CubeGeometry(length,width,height)
      #console.log @current.geometry.boundingBox
      v=(x,y,z)->
         return new THREE.Vector3(x,y,z)
     
      lineMat = new THREE.LineBasicMaterial({color: 0x808080, lineWidth: 1,wireframe: true})
      lineMat = new THREE.MeshBasicMaterial({color: 0x808080, wireframe: true, shading:THREE.FlatShading})
      cage = new THREE.Mesh(cageGeo, lineMat)
      #cage.type = THREE.Lines
      console.log mesh.geometry
      ##bla middlepoint
      middlePoint=(geometry)->
        
        #console.log geometry.boundingBox
        
        middle  = new THREE.Vector3()
        middle.x  = ( geometry.boundingBox.max.x + geometry.boundingBox.min.x ) / 2
        middle.y  = ( geometry.boundingBox.max.y + geometry.boundingBox.min.y ) / 2
        middle.z  = ( geometry.boundingBox.max.z + geometry.boundingBox.min.z ) / 2
        return middle
      
      delta = middlePoint(mesh.geometry)#.negate();
      #cage.translate(mesh.geometry, delta)
      cage.position = delta
      
      truc = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(-length/2,-width/2,height/2),width-15,0xFF7700)
      cage.add truc
      mesh.cageView= cage #children = []
      
      
    drawText:(text)=>
      canvas = document.createElement('canvas')
      canvas.width = 120
      canvas.height = 40
      context = canvas.getContext('2d')
      context.fillText(text, 40, 40)

      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      sprite = new THREE.Sprite(
        map: texture
        transparent: true
        useScreenCoordinates: false
        scaleByViewport:false)
        
      return sprite
      
      
      #sprite = THREE.ImageUtils.loadTexture( "textures/sprites/disc.png" );
      #material = new THREE.ParticleBasicMaterial( { size: 35, sizeAttenuation: false, map: sprite } );
      #material.color.setHSV( 1.0, 0.2, 0.8 );
      
    onRender:()=>
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      
      container2 = $(@ui.overlayBlock)
      container2.append(@overlayRenderer.domElement)
      @animate()
      
    animate:()=>
      t= new Date().getTime()
      #console.log t
      #@camera.position.x = Math.sin(t/10000)*300
     # @camera.position.y = 150
     # @camera.position.z = Math.cos(t/10000)*300
      # you need to update lookAt on every frame
      @camera.lookAt(@scene.position)
      @controls.update()
      @renderer.render(@scene, @camera)
      
      @overlayCamera.lookAt(@overlayscene.position)
      @overlayControls.update()
      @overlayRenderer.render(@overlayscene, @overlayCamera)
      
      requestAnimationFrame(@animate)
    
    toCsgTest:(mesh)->
      csgResult = THREE.CSG.toCSG(mesh)
      
      if csgResult?
        console.log "CSG conversion result ok:"
      #console.log csgResult
      
    fromCsg:(csg)=>
      try
        app = require 'app'
        app.csgProcessor.setCoffeeSCad(@model.get("content"))
        resultCSG = app.csgProcessor.csg
        geom = THREE.CSG.fromCSG(resultCSG)
        #console.log "resultCSG:"
        #console.log resultCSG
        #console.log "result geom"
        #console.log geom
        mat = new THREE.MeshBasicMaterial({color: 0xffffff,shading:THREE.FlatShading, vertexColors: THREE.VertexColors })
        mat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
        mat = new THREE.MeshLambertMaterial({color: 0xFFFFFF,shading:THREE.FlatShading, vertexColors: THREE.VertexColors})
        
        shine= 1500#10+  Math.random() * 1000 
        spec= 10000000000#Math.random() * 10000000000
        mat = new THREE.MeshPhongMaterial({color:  0xFFFFFF , shading: THREE.SmoothShading,  shininess: shine, specular: spec, metal: true, vertexColors: THREE.VertexColors}) 
        
        if @mesh?
          @scene.remove @mesh
          
        @mesh = new THREE.Mesh(geom, mat)
        @scene.add @mesh
        @controller.objects = [@mesh]
      catch error
        console.log "error #{error} in from csg conversion"
      #console.log @scene
      

  return {GlThreeView, GlViewSettings}