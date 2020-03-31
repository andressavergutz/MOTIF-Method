/*
 *      
 * Copyright (c) 2016-2018 Cisco Systems, Inc.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 *   Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * 
 *   Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following
 *   disclaimer in the documentation and/or other materials provided
 *   with the distribution.
 * 
 *   Neither the name of the Cisco Systems, Inc. nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * \file anon.c
 * \brief address anonymization implementation
 *
 ** The anonymization key is generated via calls to /dev/random, and is
 * stored in the file ANON_KEYFILE in encrypted form, with the
 * decryption key being stored inside the executable.  A user who can
 * access ANON_KEYFILE and the executable will be able to determine
 * the anonymization key; it is essential to provide strong access
 * control on ANON_KEYFILE in particular.
 */

#include <stdio.h>         
#include <ctype.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifndef WIN32
#include <netinet/in.h> 
#include <sys/socket.h> 
#include <arpa/inet.h>
#else
#include <WS2tcpip.h>
#include <wincrypt.h>
#endif
#include <openssl/aes.h>
#include "safe_lib.h"
#include "err.h" 
#include "anon.h" 
#include "addr.h"
#include "radix_trie.h"
#include "str_match.h"

/** file used for output */ 
FILE *anon_info;

/** Max key size used for anonymization */
#define MAX_KEY_SIZE 16

/** structure used to store encrypt/decrypt keys */
struct anon_aes_128_ipv4_key {
    AES_KEY enc_key;
    AES_KEY dec_key;
};

/** key used for anonymization */
struct anon_aes_128_ipv4_key key;

/** flag used to detemine if anonymzation is ready or not */
unsigned int anonymize = 0;

/**
 * \fn joy_status_e key_init(char *ANON_KEYFILE)
 * \param ANON_KEYFILE file that contains the key to be used for anonymzation
 * \return ok 
 * \return failure 
 */
joy_status_e key_init (const char *ANON_KEYFILE) {
    int fd;
    ssize_t bytes;
    unsigned char buf[MAX_KEY_SIZE];
    unsigned char x[16] = {
        0xa9, 0xd1, 0x62, 0x94, 
        0x4b, 0x7c, 0x20, 0x18, 
        0xac, 0x6d, 0x1a, 0x6b, 
        0x42, 0x8a, 0x0b, 0x2e
    };
    AES_KEY tmp;
    unsigned char c[16];

#ifdef WIN32
    HCRYPTPROV hProv = 0;
#endif

    fd = open(ANON_KEYFILE, O_RDWR);
    if (fd != -1) {
    
        /* key file exists, so read contents */
        bytes = read(fd, c, MAX_KEY_SIZE);
        close(fd);
        if (bytes != MAX_KEY_SIZE) {
            perror("error: could not read anonymization key");
            return failure;
        } else {
            AES_set_decrypt_key(x, 128, &tmp);
            AES_decrypt(c, buf, &tmp);
        }
    } else {
#ifdef WIN32
                if (!CryptAcquireContextW(&hProv, 0, 0, PROV_RSA_AES, CRYPT_VERIFYCONTEXT | CRYPT_SILENT)) {
                        return failure;
                }
                if(!CryptGenRandom(hProv, 16, buf)) {
                        CryptReleaseContext(hProv, 0);
                        perror("error: could not get random data");
                        return failure;
                }
                CryptReleaseContext(hProv, 0);
#else
        /* key file does not exist, so generate new one */
        fd = open("/dev/urandom", O_RDONLY);
        if (fd == -1) {
            perror("error: could not open /dev/urandom");
            return failure;
        }
        bytes = read(fd, buf, MAX_KEY_SIZE);
        close(fd);
        if (bytes != MAX_KEY_SIZE) {
            perror("error: could not read key from /dev/urandom");
            return failure;
        }
#endif
        AES_set_encrypt_key(x, 128, &tmp);
        AES_encrypt(buf, c, &tmp);

#ifndef WIN32
        fd = open(ANON_KEYFILE, O_RDWR|O_CREAT, S_IRUSR|S_IWUSR);
#else
        fd = open(ANON_KEYFILE, O_RDWR | O_CREAT, _S_IREAD | _S_IWRITE);
#endif
        if (fd == -1) {
            perror("error: could not create joy.bin");
        } else {
            bytes = write(fd, c, MAX_KEY_SIZE);
            close(fd);
            if (bytes != MAX_KEY_SIZE) {
                perror("error: could not write anonymization key");
                return failure;
            }
        } 
    } 
    AES_set_encrypt_key(buf, 128, &key.enc_key);    
    AES_set_decrypt_key(buf, 128, &key.dec_key);    
    anonymize = 1;

    return ok; 
}

/** anonymized subnets */
anon_subnet_t anon_subnet[MAX_ANON_SUBNETS];

/** number of anonymized subnets */
unsigned int num_subnets = 0;

/* adds a subnet to the anonymization list */
static joy_status_e anon_subnet_add (struct in_addr a, unsigned int netmasklen) {
    if (num_subnets >= MAX_ANON_SUBNETS) {
        return failure;
    } else {
        anon_subnet[num_subnets].addr = a;
        anon_subnet[num_subnets].mask.s_addr = ipv4_mask(netmasklen);
        num_subnets++;
    }
    return ok;
}

/* add a subnet to the anonymization list from a string */
static joy_status_e anon_subnet_add_from_string (char *addr) {
    int i, masklen = 0;
    char *mask = NULL;
    struct in_addr a;

    for (i=0; i<80; i++) {
        if (addr[i] == '/') {
            mask = addr + i + 1;
            addr[i] = 0;
            break;
        }
    }
    if (mask) {
        /* avoid confusing atoi() with nondigit characters */
        for (i=0; i<80; i++) {
            if (mask[i] == 0) {
                      break;
            }
            if (!isdigit(mask[i])) {
                      mask[i] = 0;   /* null terminate */
                      break;
            }
        }    
        masklen = atoi(mask);
        if (masklen < 1 || masklen > 32) {
            fprintf(anon_info, "error: cannot parse subnet; netmask is %d bits\n", masklen);
            return failure;
        }
#ifndef WIN32
        inet_aton(addr, &a);
#else
        inet_pton(AF_INET, addr, &a);
#endif
        a.s_addr = addr_mask(a.s_addr, masklen);
        return anon_subnet_add(a, masklen);
    }                    
    return failure;
}

/* finds address in anonymization list */
static unsigned int addr_is_in_set (const struct in_addr *a) {
    unsigned int i;

    for (i=0; i < num_subnets; i++) {
        if ((a->s_addr & anon_subnet[i].mask.s_addr) == anon_subnet[i].addr.s_addr) {
            return 1;
        } 
    }
    return 0;
}
/* determines number of bits in the subnet mask */
static unsigned int bits_in_mask (void *a, unsigned int bytes) {
    unsigned int n = 0;
    unsigned char *buf = (unsigned char *)a;

    while (bytes-- > 0) {
        unsigned char bit = 128;
    
        while (bit > 0) {
            n++;
            if ((bit & *buf) == 0) {
                      return n-1;
            }
            bit >>= 1;
        }
        buf++;
    }
    return 32;
}

/**
 * \fn int anon_print_subnets (FILE *f)
 * \param f file to print subnets out to
 * \return ok
 * \return failure
 */
int anon_print_subnets (FILE *f) {
    char ipv4_addr[INET_ADDRSTRLEN];

    if (num_subnets > MAX_ANON_SUBNETS) {
        fprintf(f, "error: %u anonymous subnets configured, but maximum is %u\n", 
              num_subnets, MAX_ANON_SUBNETS);
        return failure;
    } else {
        unsigned int i;

        for (i=0; i<num_subnets; i++) {
            inet_ntop(AF_INET, &anon_subnet[i].addr, ipv4_addr, INET_ADDRSTRLEN);
            fprintf(f, "anon subnet %u: %s/%d\n", i, ipv4_addr,
                  bits_in_mask(&anon_subnet[i].mask, 4));
        }
    }
    return ok;
}

/**
 * \fn joy_status_e anon_init (const char *pathname, FILE *logfile)
 * \param pathname file of anonymization subnets
 * \param logfile file to output information to
 * \return ok
 * \return failure
 */
joy_status_e anon_init (const char *pathname, FILE *logfile) {
    joy_status_e s;
    FILE *fp;
    size_t len;
    char *line = NULL;

    if (logfile != NULL) {
        anon_info = logfile;
    } else {
        anon_info = stderr;
    }

    fp = fopen(pathname, "r");
    if (fp == NULL) {
        return failure;
    } else {
        while (getline(&line, &len, fp) != -1) {
            char *addr = line;
            int i, got_input = 0;

            for (i=0; i<80; i++) {
                if (line[i] == '#') {
                    break;
                }
                if (isblank(line[i])) {
                    if (got_input) {
                        line[i] = 0; /* null terminate */
                    } else {
                        addr = line + i + 1;
                    }
                }
                if (!isprint(line[i])) {
                    break;
                }
                if (isxdigit(line[i])) {
                    got_input = 1;
                }
            }
            if (got_input) {
                if (anon_subnet_add_from_string(addr) != ok) {
                    fprintf(anon_info, "error: could not add subnet %s to anon set\n", addr);
                    return failure;
                }
            }
        }
        anon_print_subnets(anon_info);
        fprintf(anon_info, "configured %d subnets for anonymization\n", num_subnets);
        free(line);
        fclose(fp);
    } 
    s = key_init(ANON_KEYFILE_DEFAULT);
    return s;
}

/** buffer used for anonymized data */
static char hexout[33];

/**
 * \fn char *addr_get_anon_hexstring (const struct in_addr *a)
 * \param a address to be anonymized
 * \return pointer to the anonymized output
 */
char *addr_get_anon_hexstring (const struct in_addr *a) {
    unsigned char pt[16] = { 0, };
    unsigned char c[16];

    memcpy_s(pt, sizeof(struct in_addr), a, sizeof(struct in_addr));
    AES_encrypt(pt, c, &key.enc_key);
    snprintf(hexout, 33, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", 
               c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7], 
               c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15]);
 
    return hexout;
}

/**
 * \fn unsigned int ipv4_addr_needs_anonymization (const struct in_addr *a)
 * \param a address to check
 * \return 0 doesn't need anonymization
 * \return 1 needs anonymization
 */
unsigned int ipv4_addr_needs_anonymization (const struct in_addr *a) {
    if (anonymize) {
        return addr_is_in_set(a);
    }
    return 0;
}

/**
 * \fn int anon_unit_test ()
 * \param none
 * \return ok
 */
int anon_unit_test () {
    struct in_addr inp;

    anon_init("internal.net", stderr);

#ifndef WIN32
    if (inet_aton("64.104.192.129", &inp) == 0) {
#else
    if (inet_pton(AF_INET, "64.104.192.129", &inp) == 0) {
#endif 
        fprintf(anon_info, "error: could not convert address\n");
    }  
    if (ipv4_addr_needs_anonymization(&inp) != 1) {
        fprintf(anon_info, "error in anon_unit_test\n");
    } else {
        fprintf(anon_info, "passed\n");
    }

    return ok;
}

/* END address anonymization  */

/* START http anonymization */

/**
 * \fn joy_status_e anon_string (const char *s, unsigned int len, char *outhex, unsigned int outlen)
 * \param s string to be anonymized
 * \param len length of the string to be anonymized
 * \param outhex pointer to the destination containing anonymized string
 * \param outlen length of the anonymized string
 * \return ok
 * \return failure
 */ 
joy_status_e anon_string (const char *s, unsigned int len, char *outhex, unsigned int outlen) {
    unsigned char pt[16] = { 
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
    };
    unsigned char c[16];

    if (len > 16 || outlen < 33) {
        return failure;
    }
    memcpy_s(pt, len, s, len);
    AES_encrypt(pt, c, &key.enc_key);

    snprintf(outhex, 33, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", 
               c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7], 
               c[8], c[9], c[10], c[11], c[12], c[13], c[14], c[15]);
    outhex[32] = 0; /* null termination */
  
   return ok;
}

/**
 * \fn joy_status_e deanon_string (const char *hexinput, unsigned int len, char *s, unsigned int outlen)
 * \param hexinput anonymized string
 * \param len anonymized string length
 * \param s pointer to output buffer for de-anonymized string
 * \param outlen length of the de-anonymized string
 * \return ok
 * \return failure
 */
joy_status_e deanon_string (const char *hexinput, unsigned int len, char *s, unsigned int outlen) {
    unsigned char c[16];
    unsigned char pt[16];
    struct in_addr *addr = (struct in_addr *)pt;
    char ipv4_addr[INET_ADDRSTRLEN];

    if (len != 32 || outlen < 16) {
        return failure;
    }

    if (16 != sscanf(hexinput,
              "%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx", 
                    &c[0], &c[1], &c[2], &c[3], &c[4], &c[5], &c[6], &c[7], 
                          &c[8], &c[9], &c[10], &c[11], &c[12], &c[13], &c[14], &c[15])) {
        return failure;
    }

    AES_decrypt(c, pt, &key.dec_key);
    inet_ntop(AF_INET, addr, ipv4_addr, INET_ADDRSTRLEN);
    strncpy_s(s, outlen, ipv4_addr, outlen-1);
    return ok; 
}

/* context used for unsername anonymization */
str_match_ctx usernames_ctx = NULL;

/**
 * \fn joy_status_e anon_http_init (const char *pathname, FILE *logfile, enum anon_mode mode, char *ANON_KEYFILE)
 * \param pathname file containg usernames to anonymize
 * \param logfile file to output debug, errors and information to
 * \param mode whether to anonymized, check or deanonymize the data
 * \param ANON_KEYFILE file contianing the anonymization keys
 * \return ok
 * \return failure
 */
joy_status_e anon_http_init (const char *pathname, FILE *logfile, enum anon_mode mode, const char *ANON_KEYFILE) {
    joy_status_e s;
    string_transform transform = NULL;

    /* make sure that key is initialized */
    s = key_init(ANON_KEYFILE);

    if (mode == mode_deanonymize) {
        transform = anon_string;
    }

    if (logfile != NULL) {
        anon_info = logfile;
    } else {
        anon_info = stderr;
    }

    usernames_ctx = str_match_ctx_alloc();
    if (usernames_ctx == NULL) {
        fprintf(stderr, "error: could not allocate string matching context\n");
        return failure;
    }
    if (str_match_ctx_init_from_file(usernames_ctx, pathname, transform) != 0) {
        fprintf(stderr, "error: could not init string matching context from file\n");
        exit(EXIT_FAILURE);
    }
    return s;
}

/**
 * \fn void anon_http_ctx_cleanup (void)
 * \param none
 * \return none
 */
void anon_http_ctx_cleanup (void)
{
    /* nothing to do */
    if (usernames_ctx == NULL) {
        return;
    }

    str_match_ctx_free(usernames_ctx);
    usernames_ctx = NULL;
}

/**
 * \fn void zprintf_nbytes (zfile f, char *s, size_t len)
 * \param f file to output to
 * \param s pointer to the bytes to print
 * \param len length of the bytes to print
 * \return none
 */
void zprintf_nbytes (zfile f, const char *s, size_t len) {
    char tmp[1024];
  
    if (len >= 1024) {
        fprintf(stderr, "error: string longer than fixed buffer (length: %zu)\n", len);
        return;
    }
    memcpy_s(tmp, len, s, len);
    tmp[len] = 0;
    zprintf(f, "%s", tmp);
}

/**
 * \fn void zprintf_anon_nbytes (zfile f, size_t len)
 * \param f file to output to
 * \param len length of the bytes to print
 * \return none
 */
void zprintf_anon_nbytes (zfile f, size_t len) {
    char tmp[1024];
    unsigned int i;

    if (len >= 1024) {
        fprintf(stderr, "error: string longer than fixed buffer (length: %zu)\n", len);
        return;
    }
    for (i=0; i<len; i++) {
        tmp[i] = '*';
    }
    tmp[len] = 0;
    zprintf(f, "%s", tmp);
}

/**
 * \fn int is_special (char *ptr)
 * \param ptr pointer to the character to check
 * \return 0 is not special
 * \return 1 is special
 */
int is_special (const char *ptr) {
    char c = *ptr;
    return (c=='?')||(c=='&')||(c=='/')||(c=='-')||(c=='\\')||(c=='_')||(c=='.')||(c=='=')||(c==';')||(c==0); // ||(c==' ')||(c=='@')||(c=='.');
}

/**
 * \fn void anon_print_uri (zfile f, struct matches *matches, char *text)
 * \param f file to output to
 * \param matches structure determining the match of the uri
 * \param text the uri string
 * \return none
 */
void anon_print_uri(zfile f, struct matches *matches, const char *text) {
    unsigned int i;

    if (matches->count == 0) {
        zprintf(f, "%s", text);
        return;
    }

    zprintf_nbytes(f, text, matches->start[0]);   /* nonmatching */
    for (i=0; i < matches->count; i++) {
        if ((matches->start[i] == 0 || is_special(text + matches->start[i] - 1)) &&
            is_special(text + matches->stop[i] + 1)) {
            /* matching and special */
            zprintf_anon_nbytes(f, matches->stop[i] - matches->start[i] + 1);
        } else {
            /* matching, not special */
            zprintf_nbytes(f, text + matches->start[i], matches->stop[i] - matches->start[i] + 1);
        }
        if (i < matches->count-1) {
            /* nonmatching */
            zprintf_nbytes(f, text + matches->stop[i] + 1, matches->start[i+1] - matches->stop[i] - 1);
        } else {
           /* nonmatching */
           zprintf(f, "%s", text + matches->stop[i] + 1);
        }
    }
}

/**
 * \fn email_special_chars (char *ptr)
 * \param ptr pointert to the character to check
 * \return o is not special
 * \return 1 is special
 */
int email_special_chars (const char *ptr) {
    char c = *ptr;
    return (c==0)||(c==' ')||(c=='@')||(c==',')||(c=='\t')||(c=='"')||(c=='\'');
}

/**
 * \fn void anon_print_string (zfile f, struct matches *matches, char *text, 
                        char_selector selector, string_transform transform)
 * \param f file to output to
 * \param matches structure to determine matching
 * \param text string to print out
 * \param selector character selector
 * \param transform transform to use for anonymization
 * \return none
 */
void anon_print_string (zfile f, struct matches *matches, const char *text, 
                        char_selector selector, string_transform transform) {
    unsigned int i;
    joy_status_e err;
    char hex[33];

    if (matches->count == 0) {
        zprintf(f, "%s", text);
        return;
    }

    zprintf_nbytes(f, text, matches->start[0]);   /* nonmatching */
    for (i=0; i < matches->count; i++) {
        if ((matches->start[i] == 0 || selector(text + matches->start[i] - 1)) && 
             selector(text + matches->stop[i] + 1)) {
            /* 
             * matching and special 
             */
            const void *start = text + matches->start[i];
            size_t len = matches->stop[i] - matches->start[i] + 1;

            if (transform) {
                      err = transform(start, len, hex, sizeof(hex));
                      if (err == ok) {
                          zprintf(f, "%s", hex);
                      } else {
                          zprintf_anon_nbytes(f, len);
                      }
            } else {
                      zprintf_nbytes(f, start, len);
            }
        } else {
            /* matching, not special */
            zprintf_nbytes(f, text + matches->start[i], matches->stop[i] - matches->start[i] + 1);
        }
        if (i < matches->count-1) {
            /* nonmatching */
            zprintf_nbytes(f, text + matches->stop[i] + 1, matches->start[i+1] - matches->stop[i] - 1);
        } else {
            /* nonmatching */
            zprintf(f, "%s", text + matches->stop[i] + 1); 
        }
    }
}

/**
 * \fn void anon_print_uri_pseudonym (zfile f, struct matches *matches, char *text)
 * \param f file to output to
 * \param matches structure used toi determine matching
 * \param text string to print out
 * \return none
 */
void anon_print_uri_pseudonym (zfile f, struct matches *matches, const char *text) {
    anon_print_string(f, matches, text, is_special, anon_string);
        return;
}

/**
 * \fn void zprintf_usernames (zfile f, struct matches *matches, char *text, 
                        char_selector selector, string_transform transform)
 * \param f file to output to
 * \param matches structure to determine matching
 * \param text string to print out
 * \param selector character selector
 * \param transform transform to use for anonymization
 * \return none
 */
void zprintf_usernames (zfile f, struct matches *matches, const char *text, 
                        char_selector selector, string_transform transform) {
    unsigned int i;
    char tmp[1024];
    joy_status_e err;
    char hex[33];
    unsigned int count = 0;

    zprintf(f, "\"usernames\":[");
    for (i=0; i < matches->count; i++) {
        size_t len = matches->stop[i] - matches->start[i] + 1;
        if (len >= 1024) {
            break; /* error state */
        }
        if ((matches->start[i] == 0 || selector(text + matches->start[i] - 1)) && 
            selector(text + matches->stop[i] + 1)) {
            memcpy_s(tmp, len, text + matches->start[i], len);
            tmp[len] = 0;
            if (count++) {
                      zprintf(f, ",");
            }
            if (transform) {
                      err = transform(tmp, len, hex, sizeof(hex));
                      if (err == ok) {
                          zprintf(f, "\"%s\"", hex);    
                      } else {    
                        //zprintf_anon_nbytes(f, start, len);  
                      }
            } else {
                    zprintf(f, "\"%s\"", tmp);
            }
        }
    }
    zprintf(f, "]");
}

/* END http anonymization */
