#==============================================================================
# This module encapsulates image processing part of the pipeline. It requires
# Imager perl module.
#==============================================================================

package UfSc::Image;

use strict;
use warnings;

use Moo;
use Imager;
use Imager::Color;
use Path::Tiny;

#--- attributes ---------------------------------------------------------------

has file => (
  is => 'ro',
  required => 1
);

has image => (
  is => 'lazy',
);

has colors => (
  is => 'lazy',
);

has darkest_color => (
  is => 'lazy',
);

has bg_color => (
  is => 'lazy',
);

#--- builders -----------------------------------------------------------------

sub _build_image
{
  my ($self) = @_;

  my $img = Imager->new(file => $self->file)
  or die Imager->errstr;
}

# we build a list of colours present in the image; it takes the form of an
# array of hashrefs, each with 'r', 'g', 'b', 'v' and 'count' keys.

sub _build_colors
{
  my ($self) = @_;

  my $colors_hash = $self->image->getcolorusagehash;
  my @colors_decoded;
  foreach my $c (keys %$colors_hash) {
    my @colors_rgb = unpack('CCC', $c);
    my $color = Imager::Color->new(@colors_rgb);
    my @colors_hsv = $color->hsv;
    push(@colors_decoded, {
      r => $colors_rgb[0],
      g => $colors_rgb[1],
      b => $colors_rgb[2],
      v => $colors_hsv[2],
      count => $colors_hash->{$c}
    });
  }

  return \@colors_decoded;
}

# we find the darkest color (ie. color with the lowest hsv 'value'); only
# colors with count == 1 are included, otherwise the search for the 'dark pixel'
# would be ambiguous

sub _build_darkest_color
{
  my ($self) = @_;
  my $colors = $self->colors;

  my ($darkest_color) = sort {
    $a->{v} <=> $b->{v}
  } grep {
    $_->{count} == 1
  } @$colors;

  if($darkest_color) {
    return Imager::Color->new(@{$darkest_color}{qw(r g b)});
  } else {
    return undef;
  }
}

sub _build_bg_color
{
  my ($self) = @_;
  my $colors = $self->colors;

  my ($bg_color) = sort { $b->{count} <=> $a->{count} } @$colors;
  return Imager::Color->new(@{$bg_color}{qw(r g b)});
}

#--- methods ------------------------------------------------------------------

sub width { $_[0]->image->getwidth }
sub height { $_[0]->image->getheight }

# UFSC's original "unnamed" series had a frame with single dark pixel in them;
# following function tries to find it; it does this by trying to find pixel
# with the darkest color in the image; when one is found, its coordinates are
# returned in an arrayref, otherwise undef is returned

sub find_darkest_pixel
{
  my ($self) = @_;
  my $img = $self->image;
  my $darkest = $self->darkest_color;
  my ($w, $h) = ($self->width, $self->height);

  # no darkest color was found
  return undef if !$self->darkest_color;

  # if all pixels are the same color, then there's nothing to look for
  return undef if @{$self->colors} == 1;

  # exhaustively search the frame, stop searching on the first match
  for(my $x = 0; $x < $w; $x++) {
    for(my $y = 0; $y < $h; $y++) {
      my $pxl = $img->getpixel(x => $x, y => $y);
      if($pxl->equals(other => $darkest, ignore_alpha => 1)) {
        return [ $x, $y ];
      }
    }
  }

  return undef;
}

# draw a cross marker at supplied (x,y) coordinates (modifies the in-memory
# image)

sub draw_marker
{
  my ($self, %arg) = @_;
  my $img = $self->image;

  my $color = Imager::Color->new(200,200,200,0);
  my %line_h = (x1 => 0, y1 => $arg{y}, x2 => $img->getwidth - 1, y2 => $arg{y});
  my %line_v = (x1 => $arg{x}, y1 => 0, x2 => $arg{x}, y2 => $img->getheight - 1);

  $img->line(color => $color, %line_h);
  $img->line(color => $color, %line_v);

  return $self;
}

# save the file back; by default it uses the original name with user definable
# affix appended (or 'mark' if unspecified)

sub save
{
  my ($self, %arg) = @_;
  my $target;

  if(exists $arg{file}) {
    $target = path $arg{file};
  } else {
    my $file = path $self->file;
    my $base = $file->basename('.png');
    my $affix = $arg{'affix'} // 'mark';
    $target = $file->sibling("$base-$affix.png");
  }

  $self->image->write(file => $target->canonpath, type => 'png');
}

#------------------------------------------------------------------------------

1;
