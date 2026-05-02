package App::cpm::Resolver::Sample 0.001 {
    use 5.32.0;
    use experimental 'signatures';
    use YAML::PP ();

    sub new ($class, $ctx, $file) {
        my $content = YAML::PP->new->load_file($file);
        bless { index => $content->{index} }, $class;
    }

    sub resolve ($self, $ctx, $task) {
        my $package = $task->{package};
        my $version_range = $task->{version_range}; # TODO take care of version_range
        if (my $entry = $self->{index}{$package}) {
            return $entry;
        }
        return { error => "not found" };
    }
}

1;
