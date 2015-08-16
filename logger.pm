#!/usr/bin/perl
#
package logger;
@ISA = qw(Exporter);
use Log::Log4perl;
use strict;
use warnings;
our @EXPORT = qw(log);


############################################################
#    # A simple root logger with a Log::Log4perl::Appender::File 
#    # file appender in Perl.
#############################################################
#log4perl.appender.LOGFILE.layout.ConversionPattern=[%r] %F %L %c - %m%n
#Logging levels refer page 27
my $levels = {
    trivia  => "DEBUG",
    verbose => "TRACE",
    info    => "INFO",
    warning => "WARNING",
    error   => "ERROR"
};

sub log {
    unless (Log::Log4perl->initialized()) {
        Log::Log4perl->easy_init($Log::Log4perl::TRACE);
    }
    return Log::Log4perl::get_logger();
}
sub initlog {
    my (%params) = @_;
    my $conf = {
        "log4perl.rootLogger" => "DEBUG, LOGFILE, console",
        "log4perl.appender.console" => "Log::Log4perl::Appender::Screen",
        "log4perl.appender.console.stderr" => 0,
        "log4perl.appender.console.utf8" => 1,
        "log4perl.appender.console.layout" => "Log::Log4perl::Layout::PatternLayout",
        "log4perl.appender.console.layout.ConversionPattern" => "[%d] %F %L %p - %m%n",
        "log4perl.appender.LOGFILE" => "Log::Dispatch::FileRotate",
        "log4perl.appender.LOGFILE" =>"Log::Log4perl::Appender::File",
        "log4perl.appender.LOGFILE.filename"  =>    $params{file},
        "log4perl.appender.LOGFILE.mode" => "append",
        "log4perl.appender.LOGFILE.layout" => "Log::Log4perl::Layout::PatternLayout",
        "log4perl.appender.LOGFILE.layout.ConversionPattern" => "[%d] %F %L %p - %m%n"};
    Log::Log4perl->init($conf);
}

1;
