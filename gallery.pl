#!/usr/bin/env perl
use Mojolicious::Lite;

get '/:dir' => sub {
  my $self = shift;
  my $directory = $self->param('dir') || '';

  my @pics = map { s/public//r } grep { /\.jpg|\.png|\.gif/ } glob "public/$directory/thumbs/*";
  #my @pics = map { s/public//r } glob 'public/*.jpg';
  $self->stash( gallery => \@pics );
  $self->render('index');
};

get '/gallery/:dir' => sub {
  my $self      = shift;
  my $directory = $self->param('dir');

  #my @pics = map { s/public//r } grep { /\.jpg|\.png|\.gif/ } glob "public/$directory/thumbs/*";
  my @pics = map { s/public//r } glob "public/$directory/thumbs/*.jpg";
  $self->stash( gallery => \@pics );
  $self->render('index');
};

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body>
     <%= content %>
     <p />
     % foreach my $img ( @$gallery ) {
         <img src='<%= $img %>' />
     % }
  </body>
</html>

