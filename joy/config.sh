#!/bin/bash

#
# Support old builds
#
cp Makefile.joy Makefile
cp src/Makefile.joy src/Makefile

##
# Usage Function - prints out how to use the command
#    Valid options are:
#         -h | --help           - Help screen
#         -l | --lib-path       - specify the library path
#         -s | --ssl-path       - specify the OpenSSL header path
#         -c | --curl-path      - specify the Curl header path
#         -z | --zip-lib        - specify the compression library to use (gzip default)
##
print_usage ()
{
   echo "$0 [-h | --help] [-l <path> | --lib-path <path>] [-s <path> | --ssl-path <path>] [-c <path> | --curl-path <path>] [-z <gzip | bzip2 | none> | --zip-lib <gzip | bzip2 | none>]"
   echo "examples:"
   echo "	$0 --help"
   echo "	$0 --lib-path /usr/local/lib/x86_64-linux-gnu"
   echo "	$0 --ssl-path /var/ssl/openssl/include"
   echo "	$0 --curl-path /var/include"
   echo "	$0 --zip-lib  gzip"
}

##
# Function to see if a string contains another string
#    Returns:
#       0 - substring is not in the string
#       1 - substring is in the string
##
string_has ()
{
    string="$1"
    substring="$2"
    if [ "${string#*$substring}" != "$string" ]; then
        ## substring is in string
        string_has_result=1
    else
        ## substring is not in string
        string_has_result=0
    fi
}

##
# Function that looks for the OpenSSL header files. Typically they are
# stored in the /usr or /include directory tree somewhere. We will search
# there for the header files. 
##
find_ssl_headers ()
{
    if [ $1 ]; then
        ssl_crypto=`find "$1" -name "crypto.h" 2>/dev/null | grep -m 1 "openssl"`
        if [ "$ssl_crypto" != "" ]; then
           echo "Searching for OpenSSL headers...found"
           ## remove /openssl/crypto.h from the end of the path
           ssl_crypto_path=${ssl_crypto::${#ssl_crypto}-17}
           return
        fi
    fi

    ssl_crypto=`find /usr -name "crypto.h" 2>/dev/null | grep -m 1 "openssl"`
    if [ "$ssl_crypto" != "" ]; then
        echo "Searching for OpenSSL headers...found"
        ## remove /openssl/crypto.h from the end of the path
        ssl_crypto_path=$ssl_crypto_path${ssl_crypto::${#ssl_crypto}-17}
        return
    fi

    ssl_crypto=`find /include -name "crypto.h" 2>/dev/null | grep -m 1 "openssl"`
    if [ "$ssl_crypto" != "" ]; then
        echo "Searching for OpenSSL headers...found"
        ## remove /openssl/crypto.h from the end of the path
        ssl_crypto_path=${ssl_crypto::${#ssl_crypto}-17}
        return
    fi

    ssl_crypto=`find /opt -name "crypto.h" 2>/dev/null | grep -m 1 "openssl"`
    if [ "$ssl_crypto" != "" ]; then
        echo "Searching for OpenSSL headers...found"
        ## remove /openssl/crypto.h from the end of the path
        ssl_crypto_path=${ssl_crypto::${#ssl_crypto}-17}
        return
    fi

    if [ $1 ]; then
        echo "Checked paths [/usr, /include, /opt, $1] for OpenSSL headers...missing!"
    else
        echo "Checked paths [/usr, /include, /opt] for OpenSSL headers...missing!"
    fi
    echo "Couldn't find OpenSSL Header files. Please install the header files"
    echo "or provide the location using the -s or --ssl-path option."
    echo "For intance, if OpenSSL headers were installed at /var/ssl/openssl/include:"
    echo "	$0 -s /var/ssl/openssl/include	or"
    echo "	$0 --ssl-path /var/ssl/openssl/include"
    exit 1
}

##
# Function that looks for the Curl header files. Typically they are
# stored in the /usr or /include directory tree somewhere. We will search
# there for the header files. 
##
find_curl_headers ()
{
    curl_header=`find /usr -name "curl.h" 2>/dev/null | grep -m 1 "curl/curl.h"`
    if [ "$curl_header" != "" ]; then
        echo "Searching for Curl headers...found"
        ## remove /curl/curl.h from the end of the path
        curl_header_path=$curl_header_path${curl_header::${#curl_header}-12}
        return
    fi

    curl_header=`find /include -name "curl.h" 2>/dev/null | grep -m 1 "curl/curl.h"`
    if [ "$curl_header" != "" ]; then
        echo "Searching for Curl headers...found"
        ## remove /curl/curl.h from the end of the path
        curl_header_path=$curl_header_path${curl_header::${#curl_header}-12}
        return
    fi

    curl_header=`find /opt -name "curl.h" 2>/dev/null | grep -m 1 "curl/curl.h"`
    if [ "$curl_header" != "" ]; then
        echo "Searching for Curl headers...found"
        ## remove /curl/curl.h from the end of the path
        curl_header_path=$curl_header_path${curl_header::${#curl_header}-12}
        return
    fi

    if [ $1 ]; then
        curl_header=`find "$1" -name "curl.h" 2>/dev/null | grep -m 1 "curl/curl.h"`
        if [ "$curl_header" != "" ]; then
            echo "Searching for Curl headers...found"
            ## remove /curl/curl.h from the end of the path
            curl_header_path=$curl_header_path${curl_header::${#curl_header}-12}
            return
        fi
    fi

    if [ $1 ]; then
        echo "Checked paths [/usr, /include, /opt, $1] for Curl headers...missing!"
    else
        echo "Checked paths [/usr, /include, /opt] for Curl headers...missing!"
    fi
    echo "Couldn't find Curl Header files. Please install the header files"
    echo "or provide the location using the -c or --curl-path option."
    echo "For intance, if Curl headers were installed at /var/include/curl :"
    echo "	$0 -c /var/include	or"
    echo "	$0 --curl-path /var/include"
    exit 1
}

##
# Function that checks /lib, /usr/lib and /usr/local/lib for the
# library dependecnies. /lib, /usr/lib and /usr/local/lib are the
# default library search paths. 
##
check_libraries ()
{
    if ls /usr/local/lib/$1.* 1> /dev/null 2>&1; then
       echo "Checking for $1...exists"
       string_has "$library_path" "/usr/local/lib"
       if [ $string_has_result -eq 0 ]; then
           library_path=$library_path" -L \"/usr/local/lib\""
       fi
       return
    fi

    if ls /usr/lib/$1.* 1> /dev/null 2>&1; then
       echo "Checking for $1...exists"
       string_has "$library_path" "/usr/lib"
       if [ $string_has_result -eq 0 ]; then
           library_path=$library_path" -L \"/usr/lib\""
       fi
       return
    fi

    if ls /lib/$1.* 1> /dev/null 2>&1; then
       echo "Checking for $1...exists"
       string_has "$library_path" "/lib"
       if [ $string_has_result -eq 0 ]; then
           library_path=$library_path" -L \"/lib\""
       fi
       return
    fi

    if ls /usr/lib/x86_64-linux-gnu/$1.* 1> /dev/null 2>&1; then
       echo "Checking for $1...exists"
       string_has "$library_path" "/usr/lib/x86_64-linux-gnu"
       if [ $string_has_result -eq 0 ]; then
           library_path=$library_path" -L \"/usr/lib/x86_64-linux-gnu\""
       fi
       return
    fi

    if ls /usr/lib64/$1.* 1> /dev/null 2>&1; then
       echo "Checking for $1...exists"
       string_has "$library_path" "/usr/lib64"
       if [ $string_has_result -eq 0 ]; then
           library_path=$library_path" -L \"/usr/lib64\""
       fi
       return
    fi

    if [ $2 ]; then
        if ls $2/$1.* 1> /dev/null 2>&1; then
           echo "Checking for $1...exists"
           string_has "$library_path" "$2"
           if [ $string_has_result -eq 0 ]; then
               library_path=$library_path" -L \"$2\""
           fi
           return
        fi
    fi

    if [ $2 ]; then
        echo "Checked paths [/lib, /usr/lib, /usr/local/lib, /usr/lib/x86_64-linux-gnu, /usr/lib64 $2] for $1...missing!"
    else
        echo "Checked paths [/lib, /usr/lib, /usr/local/lib, /usr/lib/x86_64-linux-gnu, /usr/lib64] for $1...missing!"
    fi
    echo "Some systems store libraries in the /usr/local/<arch-triplet> directory."
    echo "If your system does this, execute config command with the Library Path specified."
    echo "For intance, on a GNU 64-bit Linux system:"
    echo "	$0 -l /usr/lib/x86_64-linux-gnu	or"
    echo "	$0 --lib-path /usr/lib/x86_64-linux-gnu"
    exit 1
}

##
# parse the options passed to us
##
rm -f config.vars
LIBPATH=""
SSLPATH=""
CURLPATH=""
ZIPLIB="gzip"
if [ $# -eq 1 ]; then
    print_usage
    exit 2
fi
while [ $# -gt 1 ]
do
key="$1"

case $key in
    -l|--lib-path)
    LIBPATH="$2"
    shift # past argument
    ;;
    -s|--ssl-path)
    SSLPATH="$2"
    shift # past argument
    ;;
    -c|--curl-path)
    CURLPATH="$2"
    shift # past argument
    ;;
    -z|--zip-lib)
    ZIPLIB="$2"
    shift # past argument
    ;;
    -h|--help)
    print_usage
    shift # past argument
    exit 2
    ;;
    *)
        #unknown option
        print_usage
        exit 2
    ;;
esac
shift # past argument or value
done

echo "Checking for required dependencies"
##
# check for required libraries
##

##
# figure out which compression library to look for
##
if [ "$ZIPLIB" == "bzip2" ]; then
   c_lib="libbz2"
elif [ "$ZIPLIB" == "none" ]; then
   c_lib=""
else
   c_lib="libz"
fi

library_path=""
for ck_lib in libpcap libcrypto libcurl libpthread $c_lib
do
   if [ "$LIBPATH" != ""  ]; then
       check_libraries $ck_lib $LIBPATH
   else
       check_libraries $ck_lib
   fi
done
echo "export LIBPATH=$library_path" >> config.vars

##
# Try to find the openssl header files
##
ssl_crypto_path=""
if [ "$SSLPATH" != ""  ]; then
    find_ssl_headers $SSLPATH
else
    find_ssl_headers 
fi
echo "export SSLPATH= -I \"$ssl_crypto_path\"" >> config.vars

##
# Try to find the curl header files
##
curl_header_path=""
if [ "$CURLPATH" != ""  ]; then
    find_curl_headers $CURLPATH
else
    find_curl_headers 
fi
echo "export CURLPATH= -I \"$curl_header_path\"" >> config.vars

if [ $ZIPLIB == "bzip2" ]; then
echo "export COMPDEF= -DUSE_BZIP2" >> config.vars
echo "export COMPRESSED= -DCOMPRESSED_OUTPUT=1" >> config.vars
elif [ $ZIPLIB == "none" ]; then
echo "export COMPDEF= -DUSE_NONE" >> config.vars
echo "export COMPRESSED= -DCOMPRESSED_OUTPUT=0" >> config.vars
else
echo "export COMPDEF= -DUSE_GZIP" >> config.vars
echo "export COMPRESSED= -DCOMPRESSED_OUTPUT=1" >> config.vars
fi

echo "The following variables were defined:"
cat config.vars

echo "All dependencies found. Issue 'make clean;make' to build the code"
