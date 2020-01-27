#include once "fbgfx.bi"
#include once "SDL2/SDL2.bi"

'' To get the pixel area of a Fb.Image buffer
#define pixelsOf( buffer ) _
  cptr( ulong ptr, _
    ( buffer ) ) + sizeOf( Fb.Image ) \ sizeOf( ulong )

'' Masks for the color components
#define __R_MASK__ &h00ff0000
#define __G_MASK__ &h0000ff00
#define __B_MASK__ &h000000ff
#define __A_MASK__ &hff000000

const as string _
  exampleTitle => "SDL2 Initialization example"

'' Init all needed SDL2 extensions
SDL_Init( SDL_INIT_VIDEO )

dim as integer _
  scrW => 800, _
  scrH => 600

/'
  To be able to use FBGFX buffers and standard primitives, you
  need to initialize FBGFX using the null driver, like this:
'/
screenRes( _
  scrW, scrH, 32, , Fb.GFX_NULL )
screenControl( _
  Fb.SET_ALPHA_PRIMITIVES, 1 )

'' Create a SDL2window
var _
  wnd => SDL_CreateWindow( _
    exampleTitle, _
    SDL_WINDOWPOS_UNDEFINED, _
    SDL_WINDOWPOS_UNDEFINED, _
    scrW, scrH, _
    SDL_WINDOW_OPENGL or _
    SDL_WINDOW_RESIZABLE )

'' If you want full screen
'SDL_SetWindowFullScreen( _
'  wnd, SDL_WINDOW_FULLSCREEN )

'' Create a renderer
var _
  renderer => SDL_CreateRenderer( _
    wnd, -1, 0 )

'' Create a Fb.Image bitmap to draw
dim as integer _
  bw => 800, _
  bh => 600

dim as Fb.Image ptr _
  buffer => imageCreate( _
    bw, bh, rgba( 255, 128, 64, 255 ) )

/'
  Let's draw something on the FBGFX buffer
'/
dim as string _
  text => "Hello SDL2!"

randomize()

for _
  i as integer => 1 _
  to 500
  
  line _
    buffer, _
    ( rnd() * bw, rnd() * bh ) - _
    ( rnd() * bw, rnd() * bh ), _
    rgba( _
      rnd() * &hff, _
      rnd() * &hff, _
      rnd() * &hff, _
      rnd() * &hff )
next

draw string _
  buffer, _
  ( ( bw - len( text ) * 8 ) \ 2, _
    ( bh - 8 ) \ 2 ), _
  text, _
  rgba( 0, 0, 255, 255 )

/'
  Create a SDL2 surface, and configure it to match the
  specs the Fb.Image buffer.
'/
var _
  SDLSurface => SDL_CreateRGBSurfaceFrom( _
    pixelsOf( buffer ), _
    bw, bh, 32, _
    buffer->pitch, _
    __R_MASK__, _
    __G_MASK__, _
    __B_MASK__, _
    __A_MASK__ )

'' ...and a rectangle to define the extents to copy to.
dim as SDL_Rect _
  dst

/'
  This creates a texture in GPU memory, but it also works on
  non-accelerated graphic cards.
'/
var _
  texture => SDL_CreateTextureFromSurface( _
    renderer, SDLSurface )

/'
  Once the texture is created this way, the SDL surface is no
  longer needed so we can dispose of it.
'/
SDL_FreeSurface( SDLSurface )

dim as boolean _
  done

/'
  Updating is done in SDL by polling SDL_events
'/
dim as SDL_Event _
  event

do while( not done )
  '' Copy texture to the renderer
  SDL_QueryTexture( _
    texture, 0, 0, @dst.w, @dst.h )
  SDL_RenderCopy( _
    renderer, texture, 0, @dst )
  
  '' And show (present) the renderer
  SDL_RenderPresent( renderer )
  
  '' Always poll like this, to make sure all events get processed
  do while( SDL_PollEvent( @event ) )
    select case event.type
      '' This is the user closing the SDL window
      case SDL_QUIT_
        done => true
      end select
  loop
  
  '' Always delay a little
  SDL_Delay( 2 )
loop

/'
  And that's pretty much all there is to it. Cleanup follows.
'/
SDL_DestroyTexture( texture )
SDL_DestroyRenderer( renderer )
SDL_DestroyWindow( wnd )

SDL_Quit()

imageDestroy( buffer )
