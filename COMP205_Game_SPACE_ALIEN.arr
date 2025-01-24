use context starter2024
import image as I
import reactors as R

# Data Types
data Posn:
  | posn(x, y)
end

data FallingObject:
  | falling-object(posn, speed)
end

data World:
  | world(p, f, score, blackhole-pos, star-pos, falling-object, enemy-pos)
end

# Constants
GAME-SPEED = 0.06
WIDTH = 800
HEIGHT = 500
SPACE-HEIGHT = 50
COLLISION-THRESHOLD = 65
KEY-DISTANCE = 10

SPACESHIP-X-MOVE = 5
SPACESHIP-Y-MOVE = 2
ENEMY-SPEED = 8
BLACKHOLE-X-MOVE = -5
STAR-X-MOVE = -5 

# Game Images
ENEMY_SHIP = scale(0.15, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1KjfGkmTGqIYJpqZGetYe-77gjxMk9RVU") )
SPACESHIP = scale(0.2, rotate(180, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1m4hQcQ255Uqi1_PKz48SN37xdoIKVknw")))
STAR = scale(0.2, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1wbIBbs76j1VlkXUk8l8f2n5_90eswOzM"))
ASTEROID = scale(0.1, image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1g9c0LL9BV5LH6YMxWcthq5yKoabS7rsb"))
BLACK_HOLE = I.overlay(I.circle(44, "outline", "white"), I.circle(30, "solid", "midnightblue"))
BACKGROUND = image-url("https://code.pyret.org/shared-image-contents?sharedImageId=1BqLm_RMjKYdLMQwPYxerIQwwyCaCCpdh")

BLANK-SCENE = I.place-image(BACKGROUND, WIDTH / 2, HEIGHT / 2, I.empty-scene(WIDTH, HEIGHT))
INIT-POS = world(posn(80, 100), 100, 0, posn(540, 300), posn(400, 200), 
  falling-object(posn(random(WIDTH), 0.4), random(WIDTH)), posn(WIDTH / 2, 50))

# Euclidean function
fun distance(p1, p2):
  fun squares(n): n * n end
  num-sqrt(squares(p1.x - p2.x) + squares(p1.y - p2.y))
end

#to check for collisions
fun are-overlapping(spaceship-posn, blackhole-posn):
  distance(spaceship-posn, blackhole-posn) < COLLISION-THRESHOLD
end

# movement functions
fun move-blackhole-on-tick(blackhole-pos):
  posn(num-modulo(blackhole-pos.x + BLACKHOLE-X-MOVE, WIDTH), blackhole-pos.y)
end

fun move-star-on-tick(star-pos):
  posn(num-modulo(star-pos.x + STAR-X-MOVE, WIDTH), star-pos.y)
end


fun move-spaceship-wrapping-x-on-tick(x):
  num-modulo(x + SPACESHIP-X-MOVE, WIDTH)
end

fun move-spaceship-y-on-tick(y):
  num-modulo(y + SPACESHIP-Y-MOVE, HEIGHT)
end

#enemy chasing function
fun move-enemy(enemy-pos, player-pos):
  dx = player-pos.x - enemy-pos.x
  dy = player-pos.y - enemy-pos.y
  dist = num-max(distance(enemy-pos, player-pos), 1)
  new-x = enemy-pos.x + ((dx / dist) * ENEMY-SPEED)
  new-y = enemy-pos.y + ((dy / dist) * ENEMY-SPEED)
  
  posn(num-modulo(num-floor(new-x), WIDTH),
    num-min(num-max(new-y, 0), HEIGHT - 50))
end

fun move-falling-object-on-tick(obj :: FallingObject):
  new-y = obj.posn.y + obj.speed
  if new-y > HEIGHT:
    falling-object(posn(random(WIDTH), 0), 5)
  else:
    falling-object(posn(obj.posn.x, new-y), obj.speed)
  end
end

# World State updates
fun move-spaceship-xy-on-tick(w :: World):
  new-blackhole-pos = move-blackhole-on-tick(w.blackhole-pos)
  new-star-pos = move-star-on-tick(w.star-pos)
  new-falling-object = move-falling-object-on-tick(w.falling-object)
  new-enemy-pos = move-enemy(w.enemy-pos, w.p)
  new-ship-pos = posn(move-spaceship-wrapping-x-on-tick(w.p.x),
    move-spaceship-y-on-tick(w.p.y))
  
  if are-overlapping(new-ship-pos, new-blackhole-pos):
    world(w.p, w.f, w.score, new-blackhole-pos, new-star-pos, 
      new-falling-object, new-enemy-pos)
  else if are-overlapping(new-ship-pos, new-star-pos):
    world(new-ship-pos, w.f + 20, w.score + 1, new-blackhole-pos,
      posn(num-modulo(random(WIDTH), WIDTH), random(HEIGHT - SPACE-HEIGHT)),
      new-falling-object, new-enemy-pos)
  else if are-overlapping(new-ship-pos, new-falling-object.posn):
    world(new-ship-pos, w.f, w.score, new-blackhole-pos, new-star-pos,
      new-falling-object, new-enemy-pos)
  else:
    world(new-ship-pos, w.f, w.score, new-blackhole-pos, new-star-pos,
      new-falling-object, new-enemy-pos)
  end
end

#Key movements
fun alter-spaceship-y-on-key(w, key):
  ask:
    | key == "up" then:
      if w.f > 0:
        world(posn(w.p.x, w.p.y - KEY-DISTANCE), w.f - 1, w.score,
          w.blackhole-pos, w.star-pos, w.falling-object, w.enemy-pos)
      else: w
      end
    | key == "down" then:
      world(posn(w.p.x, w.p.y + KEY-DISTANCE), w.f, w.score,
        w.blackhole-pos, w.star-pos, w.falling-object, w.enemy-pos)
    | key == "left" then:
      if w.f > 0:
        world(posn(num-modulo(w.p.x - (KEY-DISTANCE + SPACESHIP-X-MOVE), WIDTH), w.p.y),
          w.f - 1, w.score, w.blackhole-pos, w.star-pos, w.falling-object, w.enemy-pos)
      else: w
      end
    | key == "right" then:
      if w.f > 0:
        world(posn(num-modulo(w.p.x + KEY-DISTANCE, WIDTH), w.p.y),
          w.f - 1, w.score, w.blackhole-pos, w.star-pos, w.falling-object, w.enemy-pos)
      else: w
      end
    | otherwise: w
  end
end

# Background placements
fun place-spaceship-xy(w):
  score-text = I.text("Score: " + tostring(w.score), 24, "white")
  fuel-text = I.text("Fuel: " + tostring(w.f), 24, "white")
  
  I.place-image(score-text, 100, 30,
    I.place-image(fuel-text, 250, 30,
      I.place-image(ENEMY_SHIP, w.enemy-pos.x, w.enemy-pos.y,
        I.place-image(SPACESHIP, w.p.x, w.p.y,
          I.place-image(BLACK_HOLE, w.blackhole-pos.x, w.blackhole-pos.y,
            I.place-image(STAR, w.star-pos.x, w.star-pos.y,
              I.place-image(ASTEROID, w.falling-object.posn.x, w.falling-object.posn.y,
                BLANK-SCENE)))))))
end

# Game End Conditions
fun game-ends(w):
  are-overlapping(w.p, w.blackhole-pos) or 
  are-overlapping(w.p, w.falling-object.posn) or 
  are-overlapping(w.p, w.enemy-pos)
end

# Game Reactor
anim = reactor:
  init: INIT-POS,
  on-tick: move-spaceship-xy-on-tick,
  on-key: alter-spaceship-y-on-key,
  to-draw: place-spaceship-xy,
  seconds-per-tick: GAME-SPEED,
  stop-when: game-ends
end

R.interact(anim)