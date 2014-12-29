#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use Mojo::Log;

our $VERSION = "1.2";

# load a config file that contains the apps
# configuration parameters
my $config = plugin 'Config';

# hypnotoad server configuration
app->config (
    hypnotoad => {
        listen             => [$config->{ip_address_port}],
        pid_file           => $config->{pid_file},
        heartbeat_timeout  => $config->{heartbeat_timeout},
        heartbeat_interval => $config->{heartbeat_interval},
        inactivity_timeout => $config->{inactivity_timeout},
        workers            => $config->{workers},
    }
);

# location for the log to be stored
my $log_dir = $config->{log_dir};

# if the log directory does not exist then create it
if ( ! -d $log_dir ) {
  print "Creating $log_dir directory\n";
  mkdir $log_dir, 0755 or die "Cannot create $log_dir: $!\n";
}

# setup Mojo logging to use the log directory we just created
# default the log level to info
my $log = Mojo::Log->new (path => "$log_dir/$config->{log_file}", level => $config->{log_level});

# render the hand created html file in the public directory
get '/' => sub {
  my $self = shift;
  
  my $remote_addr = $self->tx->remote_address;
  my $ua          = $self->req->headers->user_agent;
  my $path        = $self->req->url->to_abs->path;
  my $method      = $self->req->method;
  $log->info("$remote_addr $method $path $ua");

  $self->reply->static('index.html');
};

# if you want to have the script auto generate the directories in public
# then uncomment this get block and comment out the get block above
 # get '/' => sub {
  # my $self = shift;
  # my @gallery_dirs;
  
  # if ( $#gallery_dirs <= 0 ) {  
    # opendir(my $dh, "public/") or $log->info("can't opendir public: $!");
    # @gallery_dirs = sort { $a cmp $b } grep { ! /^\./ && -d "public/$_" } readdir($dh);
    # closedir $dh;
  # }
  
  # $self->stash ( gal_dirs => \@gallery_dirs );
  
  # my $remote_addr = $self->tx->remote_address;
  # my $ua          = $self->req->headers->user_agent;
  # my $path        = $self->req->url->to_abs->path;
  # my $method      = $self->req->method;
  # $log->info("$remote_addr $method $path $ua");
  
  # $self->reply->static('index.html');

# };

# this block does the work of building the viewing of the gallery
# start is the first part of an array slice to view chunks of images
# at a time rather than all on one page
get '/:dir/:start' => { start => 0 } => sub {
  my $self        = shift;
  my $directory   = $self->param('dir');
  my $slice_start = $self->param('start');

  # how many images should be shown on a page
  # we want 15 at a time  
  my $slice_end   = $slice_start + 14;
  my $prev_slice;
  my $next_slice;
  my $title;
  my @pics;

  my $remote_addr = $self->tx->remote_address;
  my $ua          = $self->req->headers->user_agent;
  my $path        = $self->req->url->to_abs->path;
  my $method      = $self->req->method;  
  $log->info("$remote_addr $method $path $ua");
  
  # only build the thumbnail image array once
  if ( $#pics <= 0 ) {
    @pics = map { s/public//r }
            grep { /\.[Jj][Pp][Ee][Gg]$|\.[Jj][Pp][Gg]$|\.[Pp][Nn][Gg]$|\.[Gg][Ii][Ff]$/ }
            glob "public/$directory/thumbs/*";
    
    # if there are no thumbnails then build the images from the directory you chose
    if ( $#pics <= 0 ) {
      @pics = map { s/public//r }
              grep { /\.[Jj][Pp][Ee][Gg]$|\.[Jj][Pp][Gg]$|\.[Pp][Nn][Gg]$|\.[Gg][Ii][Ff]$/ }
              glob "public/$directory/*";
    }
    
    # get the title of the gallery from the .title file
    open my $ifh, "<", "public/$directory/.title" or $log->info("could not open (public/$directory/.title): $!");
    while ( <$ifh> ) {
      $title .= $_;
    }
    close $ifh;
    
  }
  
  # in order to show the next and previous page links correctly
  # we need to know the previous slice from the current number
  # we are on
  $prev_slice = $slice_start - 15;
  
  if ( $prev_slice < 0 ) {
    $prev_slice = 0;
  }
  
  if ( $slice_end > $#pics ) {
    $slice_end  = $#pics;
    $next_slice = $#pics;
  }
  else {
    $next_slice  = $slice_end + 1;    
  }
  
  # grab only what we need from the entire list of images
  my @send_pics = @pics[$slice_start .. $slice_end];

  $self->stash( gallery => \@send_pics );
  $self->stash( prev    => $prev_slice );
  $self->stash( next    => $next_slice );
  $self->stash( dir     => $directory );
  $self->stash( header  => $title );
  $self->stash( end     => $#pics );
  
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

  <style type="text/css">
    body {
      color: white;
      background: #336699;
    }
    
    .thumbs {
      margin-left: 10px;
      margin-right: 5px;
      float:left;
    }
    
    .viewer {
      padding-left: 20px;
      padding-bottom: 10px;
      float:left;
    }
    
    .clear {
      clear: both;
    }
    
    .prev {
      float: left;
    }
    
    .next {
      float: left;
      padding-left: 20px;
    }

    .right {
      float: right;
    }
    
    A:link {
      color: white;
      background-color: #336699;
    }

    A:active {
       color: white;
       background-color: #336699;
    }

    A:hover {
       color: yellow;
       background-color: #336699;
    }

    A:visited {
       color: lime;
       background-color: #336699;
    }
  </style>

  <script>
    function show_img(med_img, down_img) {
      document.getElementById("view_pic").src = med_img;
      document.getElementById("download").href = down_img;
    }
  </script>

  </head>
  <body>
  
    <b><%= $header %></b>
  
    <p />    
  
    <div class="thumbs">
      % my $counter = 0;
      % my $show_pic;
      % my $med_pic;
      % my $download_pic;
      % my $viewer_pic;
      
      % foreach my $img ( @$gallery ) {
        
        % $show_pic = $img;
        % $show_pic =~ s/\/thumbs//g;
        % $show_pic =~ s/thumb_//;

        % if ( $counter == 0 ) {
        %  $viewer_pic = $show_pic;
        % }
        
        % $med_pic = $show_pic;
        <!-- % $med_pic =~ s/$dir//g; -->
        <!-- % $med_pic =~ s/\///g; -->
        
        % $download_pic = $show_pic;
        % $download_pic =~ s/($dir)/$1\/originals/;
        
        <a href='#' onclick="show_img('<%= $med_pic %>','<%= $download_pic %>');return false;"><img src='<%= $img %>' /></a>
        % $counter++;
        
        % if ( ( $counter % 3 ) == 0 ) {
          <div class="clear"></div>
        % }
       
      % }
    </div>
     
    <div class="viewer">
      <img src='<%= $viewer_pic %>' id='view_pic' />
      <p />

      % if ( $next > 15 ) {
      <a class="prev" href='/<%= $dir %>/<%= $prev %>'>Prev</a>
      % }
      
      % if ( $next < $end ) {
      <a class="next" href='/<%= $dir %>/<%= $next %>'>Next</a>
      % }
      <a class="right" href='<%= $download_pic %>' id="download">Download original</a>

    </div>
    
    <div class="clear"></div>
  
    <p />
    
    <div class="thumbs">
      <a href='/'>Front page</a>
    </div>
    
  </body>
</html>

__END__

=head1 NAME

gallery.pl - Mojolicious based web gallery

=head1 SYNOPSIS

Web based photo gallery using Mojolicious.  It follows a similar format to Trent Foley's gallerific
http://jquery.kvijayanand.in/galleriffic/

=head1 DESCRIPTION

Web based photo gallery using Mojolicious.  You will see at most 15 images at a time on a page and can page through the next and previous groups of 15.  When you click on a thumbnail image it will show in a larger viewing area just to the right of the thumbnails.

=head1 README

In order to successfully use this script you need to follow a standard directory structure in order to allow the script to work properly.  Read the CONFIGURATION section below.

=head1 FORMATS

=over 3

=item jpg

=item jpeg

=item gif

=item png

=back

=head1 CONFIGURATION

Along side gallery.pl you need a directory called public/.  Inside public/ will be your directories of pictures.  Inside those directories will be a thumbs/ and originals/ directory.  The public/ directory is the dependency of Mojolicious when serving static files.

public/

    index.html - hand written html file pointing to your directories

    Directory1/
      .title - contents of file is the title of the gallery
      image1.jpg - a medium size image
      image2.jpg - a medium size image
      image3.jpg - a medium size image
      
      thumbs/
        thumb_image1.jpg
        thumb_image2.jpg
        thumb_image3.jpg
        
      originals/
        image1.jpg - the original image
        image2.jpg - the original image
        image3.jpg - the original image

=head2 CONFIGURATION

  Please fill in the appropriate fields in the gallery.conf file.

=head1 RUNNING

C<<< # hypnotoad -f gallery.pl >>>

=head1 PREREQUISITES

=over 1

=item Mojolicious::Lite

=back

=head1 SCRIPT CATEGORIES

Web

=head1 AUTHOR

Mike Plemmons, <mikeplem@cpan.org>

=head1 LICENSE

Copyright (c) 2014, Mike Plemmons
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Mike Plemmons nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL MIKE PLEMMONS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
