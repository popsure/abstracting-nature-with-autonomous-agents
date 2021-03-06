abstract class Creature {
  PVector tar; // target
  float health;
  float r;
  Box2DProcessing box2d;
  Body body;

  Creature(PVector l, Box2DProcessing _box2d) {
    r = 20;
    health = 200;
    tar = new PVector(random(width), random(height));
    box2d = _box2d;

    makeBody(l);
  }

  void makeBody(PVector l) {
    // take a look at Shiffman's explanation about complex shapes in Box2D
    // https://vimeo.com/60782771

    // we use a custom polygon shape to create a rough circle
    // use displayDebug() in order to see the shape drawn
    int shapeResolution = 8;
    Vec2[] vertices = new Vec2[shapeResolution];
    float angle = radians(360/float(shapeResolution));
    for(int i = 0; i < shapeResolution; i++) {
      vertices[i] = box2d.vectorPixelsToWorld(new Vec2(cos(angle*i) * r/2, sin(angle*i) * r/2));
    }

    // lets define a body
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    // lets set its position
    bd.position = box2d.coordPixelsToWorld(l.x, l.y);
    body = box2d.world.createBody(bd);

    // Define a polygon (this is what we use for a rectangle)
    PolygonShape ps = new PolygonShape();
    ps.set(vertices, vertices.length);

    // lets define a fixture
    FixtureDef fd = new FixtureDef();
    fd.shape = ps;

    // parameters that affect physics
    fd.density = 1;
    fd.friction = 0.3;
    fd.restitution = 0.5;
    fd.filter.categoryBits = 0x0001;
    fd.filter.maskBits = 0x0004;
    fd.filter.groupIndex = 2;

    body.createFixture(fd);
    body.setUserData(this);

    body.setLinearVelocity(new Vec2(random(-5, 5), random(-5, 5)));
    body.setAngularVelocity(random(-1, 1));
  }

  void run() {
    update();
    display();
  }

  void eat(Food f) {
    ArrayList<Attractor> food = f.getFood();
    Vec2 vecLoc = box2d.getBodyPixelCoord(body);
    PVector loc = new PVector(vecLoc.x, vecLoc.y);
    // are we touching any food?
    for (int i = food.size()-1; i >= 0; i--) {
      float d = PVector.dist(loc, food.get(i).getPosition());
      // if we are, health goes up
      if (d < r/2) {
        health += 100;
        food.remove(i);
      }
    }
  }

  void update() {
    // death is always near
    health -= 0.2;
  }

  void applyForce(Vec2 v) {
    body.applyForce(v, body.getWorldCenter());
  }

  void seek(Food f) {
    // first we'll need our list of food locations
    ArrayList<Attractor> food = f.getFood();
    Vec2 vecLoc = box2d.getBodyPixelCoord(body);
    PVector loc = new PVector(vecLoc.x, vecLoc.y);
    if (food.size() >= 1) {
      // we'll go to the closest one
      int closestFoodIndex = 0;
      for (int i = food.size()-1; i > 0; i--) {
        // if the distance to our previous closest food is more than the current one we overwrite the index
        if ( PVector.dist(loc, food.get(closestFoodIndex).getPosition()) >= PVector.dist(loc, food.get(i).getPosition()) ) {
          closestFoodIndex = i;
        }
      }

      Vec2 force = food.get(closestFoodIndex).attract(this);
      // we add some noise to the forces to make them a bit more alive
      force.x += noise(millis() * 0.02)/10.0;
      force.y += noise(10000 + (millis() * 0.2))/10.0;
      applyForce(force);

      tar = food.get(closestFoodIndex).getPosition();
    } else {
      // hm, no food, lets check if we are already close to our target
      if ( PVector.dist(loc, tar) >= 50) {
        // yeah we've likely touched our target, lets pick a random new target
        tar.x = random(width);
        tar.y = random(height);
      }
    }
  }

  void display() {
    ellipseMode(CENTER);
    stroke(250, 250, 250, health);
    fill(0, 0, 0, health);
    Vec2 pos = box2d.getBodyPixelCoord(body);
    ellipse(pos.x, pos.y, r, r);
  }

  void displayDebug() {
    // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    float a = body.getAngle();

    Fixture f = body.getFixtureList();
    PolygonShape ps = (PolygonShape) f.getShape();

    rectMode(CENTER);
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(-a);
    noFill();
    stroke(250,0,0);
    strokeWeight(2);
    beginShape();
    //println(vertices.length);
    // For every vertex, convert to pixel vector
    for (int i = 0; i < ps.getVertexCount(); i++) {
      Vec2 v = box2d.vectorWorldToPixels(ps.getVertex(i));
      vertex(v.x, v.y);
    }
    endShape(CLOSE);
    popMatrix();
  }

  PVector getVelocity() {
    Vec2 vel = body.getLinearVelocity();
    PVector p = new PVector(vel.x, vel.y);
    return p;
  }

  PVector getPosition() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    PVector p = new PVector(pos.x, pos.y);
    return p;
  }

  boolean dead() {
    if (health < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
