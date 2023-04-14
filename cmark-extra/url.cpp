//
// https://gist.github.com/RedCarrottt/c7a056695e6951415a0368a87ad1e493
//

#include "url.hpp"

#include <string>
#include <algorithm>
#include <cctype>
#include <functional>
#include <iostream>
#include <string.h>

using namespace std;

struct url {
public:
    url(const std::string& url_s) {
        this->parse(url_s);
    }
    std::string protocol_, host_, path_, query_;
private:
    void parse(const std::string& url_s);
};

// ctors, copy, equality, ...

void parse_url(const char *address, char **protocol, char **host, char **path, char **query) {
    string s_url = address;
    url u(s_url);
    *protocol = strdup(u.protocol_.c_str());
    *host = strdup(u.host_.c_str());
    *path = strdup(u.path_.c_str());
    *query = strdup(u.path_.c_str());
}

void url::parse(const string& url_s)
{
    const string prot_end("://");
    string::const_iterator prot_i = search(url_s.begin(), url_s.end(),
                                           prot_end.begin(), prot_end.end());
    protocol_.reserve(distance(url_s.begin(), prot_i));
    transform(url_s.begin(), prot_i,
              back_inserter(protocol_),
              [](unsigned char s) { return std::tolower(s); } // ptr_fun<int,int>(tolower)
              ); // protocol is icase
    if( prot_i == url_s.end() )
        return;
    advance(prot_i, prot_end.length());
    string::const_iterator path_i = find(prot_i, url_s.end(), '/');
    host_.reserve(distance(prot_i, path_i));
    transform(prot_i, path_i,
              back_inserter(host_),
              [](unsigned char s) { return std::tolower(s); }
              ); // host is icase
    string::const_iterator query_i = find(path_i, url_s.end(), '?');
    path_.assign(path_i, query_i);
    if( query_i != url_s.end() )
        ++query_i;
    query_.assign(query_i, url_s.end());
}
