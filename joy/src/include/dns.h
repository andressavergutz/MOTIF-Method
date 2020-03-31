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
 * \file dns.h
 *
 * \brief interface file for DNS code
 */
#ifndef DNS_H
#define DNS_H

#include <pcap.h>
#include "output.h"

/** usage string */
#define dns_usage "  dns=1                      report DNS response information\n"

/** dns filter key */
#define dns_filter(record) \
    ((record->key.prot == 17) && \
     (record->app == 53 || (record->key.dp == 53 || record->key.sp == 53)) \
    )

/** maximum number of DNS packets */
#define MAX_NUM_DNS_PKT 200

/** maximum DNS name length */
#define MAX_DNS_NAME_LEN 256

/** DNS structure */
typedef struct dns_ {
  unsigned int pkt_count;                      /*!< packet count       */
  char *dns_name[MAX_NUM_DNS_PKT];             /*!< DNS packets        */
  unsigned short int pkt_len[MAX_NUM_DNS_PKT]; /*!< DNS packet lengths */
} dns_t;

/** initialize DNS structure */
void dns_init(dns_t **dns_handle);

/** DNS structure update */
void dns_update(dns_t *dns, 
		const struct pcap_pkthdr *header,
		const void *data, 
		unsigned int len, 
		unsigned int report_dns);

/** print DNS data out in JSON format */
void dns_print_json(const dns_t *dns1, const dns_t *dns2, zfile f);

/** remove a DNS entry */
void dns_delete(dns_t **dns_handle);

/** main entry point for DNS unit testing */
void dns_unit_test(void);

#endif /* DNS_H */
