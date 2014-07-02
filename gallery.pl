#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => sub {
  my $self = shift;
  
  opendir(my $dh, "public/") || die "can't opendir public/: $!";
  my @gallery_dirs = grep { ! /^\./ && -d "public/$_" } readdir($dh);
  closedir $dh;

  $self->stash ( gal_dirs => \@gallery_dirs );
  $self->render('index');
};

get '/:dir/:start' => sub {
  my $self        = shift;
  my $directory   = $self->param('dir');
  my $slice_start = $self->param('start');
  my $slice_end   = $slice_start + 11;
  my $next_slice;
  
  my @pics = map { s/public//r } grep { /\.jpg|\.png|\.gif/ } glob "public/$directory/thumbs/*";
  
  if ( $slice_end > $#pics ) {
    $slice_end = $#pics;
    $next_slice = $#pics;
  }
  else {
    $next_slice  = $slice_end + 1;    
  }
  


  my @send_pics = @pics[$slice_start .. $slice_end];

  $self->stash( gallery => \@send_pics );
  $self->stash( next => $next_slice );
  
  $self->render('gallery');
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
View the following galleries

@@ gallery.html.ep
% layout 'view_gallery';
% title 'Welcome';
View the Gallery

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
  <title><%= title %></title>
  </head>
  <body>
    <%= content %>
    <p />
    % foreach my $dir ( @$gal_dirs ) {
    <a href='/<%= $dir %>/0'><%= $dir %></a> <br>
    % }
  </body>
</html>

@@ layouts/view_gallery.html.ep
<!DOCTYPE html>
<html>
  <head>
  <title><%= title %></title>
  </head>
  <style type="text/css">
  .column {
    padding-left: 5px;
    padding-right: 5px;
    float:left;
  }
  .clear {
    clear: both;
    padding-bottom: 10px;
    margin-bottom: 10px;
    font-size: small;
    font-variant: small-caps;
  }
  </style>
  </head>
  <body>
    <%= content %>
    <p />    
    <div class="column">
      % my $counter = 0;
      % my $show_pic;
      % foreach my $img ( @$gallery ) {
        
        % if ( $counter == 0 ) {
        %   $show_pic = $img;
        %   $show_pic =~ s/thumbs//g;
        %   $show_pic =~ s/thumb_//;
        % }
        
        <img src='<%= $img %>' />
        % $counter++;
        
        % if ( ( $counter % 3 ) == 0 ) {
          <div class="clear"></div>
        % }
      % }
     </div>
    <div class="column">
      <img src='<%= $show_pic %>' />
      <p />
      <a href='/Orichids/<%= $next %>'>Next</a>
      <a href='/'>Main Page</a>
    </div>
  </body>
</html>

