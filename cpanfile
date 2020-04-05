requires "Carp::Assert::More" => "0";
requires "Fatal" => "0";
requires "File::Find::Rule" => "0";
requires "Hash::Merge::Simple" => "0";
requires "JSON::MaybeXS" => "0";
requires "Log::Log4perl" => "0";
requires "Log::Log4perl::Appender::ScreenColoredLevels" => "0";
requires "Moo" => "0";
requires "MooX::Cmd" => "0";
requires "MooX::Options" => "0";
requires "Pod::Elemental" => "0";
requires "Pod::Elemental::Transformer::Pod5" => "0";
requires "String::CamelCase" => "0";
requires "String::Util" => "0";
requires "YAML::PP" => "0.021";
requires "YAML::PP::Common" => "0";
requires "feature" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.013002";
requires "strict" => "0";
requires "strictures" => "2";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "JSON::PP" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0.94";
  requires "perl" => "5.013002";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.013002";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
