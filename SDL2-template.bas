#include once "fbgfx.bi"
#include once "SDL2/SDL2.bi"

'' To get the pixel area of a Fb.Image buffer
#define getPixels( b ) _
  cptr( ulong ptr, _
    ( b ) ) + sizeOf( Fb.Image ) \ sizeOf( ulong )
  
const as string _
  exampleTitle => "SDL2 Initialization example"

'' Init all needed SDL2 extensions
SDL_Init( SDL_INIT_VIDEO )

dim as integer _
  scrW => 800, _
  scrH => 600

/'
  To be able to use FBGFX buffers and standard primitives, you
  need to initialize FBGFX using the null driver, like this
'/
screenRes( _
  scrW, scrH, 32, , Fb.GFX_NULL )
screenControl( _
  Fb.SET_ALPHA_PRIMITIVES, 1 )

'' Create a SDL2 window
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
  sw => 800, _
  sh => 600

dim as Fb.Image ptr _
  pixels => imageCreate( _
    sw, sh, rgba( 255, 128, 64, 255 ) )

dim as string _
  text => "Hello SDL2!"

draw string _
  pixels, _
  ( ( sw - len( text ) * 8 ) \ 2, _
    ( sh - 8 ) \ 2 ), _
  text, _
  rgba( 0, 0, 255, 255 )

/'
  Create a SDL2 surface, and configure it to match the
  specs the Fb.Image buffer.
'/
var _
  SDLSurface => SDL_CreateRGBSurfaceFrom( _
    getPixels( pixels ), _
    sw, sh, 32, _
    pixels->pitch, _
    &h00FF0000, _
    &h0000FF00, _
    &h000000FF, _
    &hFF000000 )

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
SDL_FreeSurface( SDLSurface )
SDL_DestroyRenderer( renderer )
SDL_DestroyWindow( wnd )

SDL_Quit()

imageDestroy( pixels )
