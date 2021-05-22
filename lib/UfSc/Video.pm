package UfSc::Video;

use strict;
use warnings;
use v5.10;

use Moo;
use UfSc::Image;
use Path::Tiny;

has file => (
  is => 'ro',
  required => 1,
  isa => sub {
    die "Not a Path::Tiny instance" unless $_[0]->isa('Path::Tiny')
  },
);

# use ffmpeg to average first 120 frames from a video and return resulting
# image as UfSc::Image instance

sub get_average_frame
{
  my ($self) = @_;
  my $ff = q{ffmpeg -i "%s" -y -vf tmix=frames=120:weights="1",select='not(mod(n\,120))' "%s"};

  my $imgfile = $self->file->sibling(
    $self->file->basename('.mp4') . '.png'
  );

  my $cmd = sprintf($ff, $self->file, $imgfile);
  system $cmd . ' >/dev/null 2>&1';

  die 'ffmpeg failed' if $?;
  die 'ffmpeg did not produce an image' if !$imgfile->exists;

  return UfSc::Image->new(file => $imgfile->canonpath);
}

1;
