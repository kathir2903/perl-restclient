#!/usr/bin/perl
#
#
package restclient;
use strict;
use warnings;
use LWP::UserAgent;
use JSON qw(encode_json decode_json);
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use Data::Dumper;
use logger qw(log);
use POSIX qw(strftime);
$Data::Dumper::Terse = 1;

logger::initlog(file => "/tmp/restclient.log")
use constant ERROR => {
    '400' => 'Bad Request',
    '401' => 'Authorization Failed',
    '403' => 'URL Forbidden',
    '404' => 'URL Not Found',
    '500' => 'Internal Server Error',
    '501' => 'Not Implemented',
    '502' => 'Bad Gateway',
    '503' => 'Service Unavailable'
};
sub new {
    my $class = shift;
    my $self = shift;

    my $http_type = 'https';
    if ($self->{port} != 443) {
        $http_type = 'http';
    }

    if ($http_type eq 'https') {
        $self->{ua} = LWP::UserAgent->new(
                ssl_opts => {
                    verify_hostname => 0,
                    SSL_verify_mode => SSL_VERIFY_NONE},
                    timeout => 120,
                    requests_redirectable => ['GET', 'POST']);
    } else {
        $self->{ua} = LWP::UserAgent->new(
                    requests_redirectable => ['GET', 'POST'],
                    timeout => 120 );
    }
    $self->{netip} = $self->{hostname} . ':' . $self->{port};
    $self->{uname} = "root";
    # $ua->credentials("www.example.com:80", "Some Realm", "foo", "secret");
    # CREDENTIALS usually have your web service's
    # realm, username, password
    #
    $self->{ua}->credentials($self->{netip},
                            "your_realm", $self->{uname}, $self->{pwd});

    if ($http_type eq 'http') {
        $self->{uri} = "http://$self->{hostname}:$self->{port}";
    } else {
        $self->{uri} = "https://$self->{hostname}";
    }
    return bless($self, $class);
}

sub exception {
    my ($self, 
        $error, 
        $op, 
        $uri) = @_;
    chomp $error->{comment};
    $self->{description} = "Code: $error->{status}, Error: $error->{comment}, [$op] - [$uri]";
    $self->{hint} = ERROR->{$error->{status}};
    log->error($self->{description});
    die "$self->{description}\n$self->{fixhint}\n";
}

sub get {
    my ($self, 
        $cmd, 
        %params) = @_;
    my $size = keys %params;
    if (keys %params>=1) {
        $cmd .= "?";
        for my $key(keys %params) {
            $cmd .= ($key. "=". $params{$key}. "&");
        }
    }
    my $uri = $self->{uri} . $cmd;
    log->debug("GET: $uri");
    my $response = $self->{ua}->get($uri);
    my $res = $response->content;
    my $res_code = $response->code;
    $self->{json_text} = decode_json($res);
    if ($res_code ne "200") {
        $self->exception($self->{json_text}, 'GET', $uri);
    }
    return $self->{json_text};
}

sub put {
    my ($self, 
        $cmd, 
        %params) = @_;
    my $data = encode_json(\%params);
    my $uri = $self->{uri} . $cmd;
    log->debug("PUT: $uri - data: $data");
    $response = $self->{ua}->put($uri, 
                                'Content' => $data,
                                'Content-Type' => 'application/json');
    my $res = $response->content;
    my $res_code = $response->code;
    if ($res_code ne "200") {
        $self->{json_text} = decode_json($res);
        $self->exception($self->{json_text}, 'PUT', $uri);
    }
}

sub post {
    my ($self, 
        $cmd, 
        %params) = @_;
    my $data = encode_json(\%params);
    my $uri = $self->{uri} . $cmd;

    log->debug("POST: $uri - data: $data");
    my $response = $self->{ua}->post($uri, 
                        'Content' => $data, 
                        'Content-Type' => 'application/json');
    my $res = $response->content;
    my $res_code = $response->code;
    if ($res_code ne "200") {
        $self->{json_text} = decode_json($res);
        $self->exception($self->{json_text}, 'POST', $uri); return undef;
    }
}

sub delete {
     my ($self, 
         $cmd, 
         $data) = @_;
     my $uri = $self->{uri} . $cmd .'/'. $data;
     log->debug("DELETE: $uri");
     my $response = $self->{ua}->delete($uri);
     my $res = $response->content;
     my $res_code = $response->code;
     if ($res_code ne "200") {
        $self->{json_text} = decode_json($res);
        $self->exception($self->{json_text}, 'DELETE', $uri)
     }
}
1;
