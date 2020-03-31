/*
 *  
 * Copyright (c) 2018-2019 Cisco Systems, Inc.
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
 * \file joy_memory_profile.c
 *
 * \brief Program to test the Joy APIs and joylib.a features for memory profiling
 * 
 */

#include <stdlib.h>  
#include <stdio.h>
#include "safe_lib.h"
#include <unistd.h>
#include "joy_api.h"

/* test program variables */
#define NUM_PACKETS_IN_LOOP 20
#define IP_OR_VLAN  "ip or vlan"

int proc_pcap_file (unsigned long index, char *file_name) {
    int more = 1;
    pcap_t *handle = NULL;
    bpf_u_int32 net = PCAP_NETMASK_UNKNOWN;
    struct bpf_program fp;
    char filter_exp[PCAP_ERRBUF_SIZE];
    char errbuf[PCAP_ERRBUF_SIZE];

    /* initialize fp structure */
    memset_s(&fp, sizeof(struct bpf_program, 0x00, sizeof(struct bpf_program));
    strncpy_s(filter_exp, PCAP_ERRBUF_SIZE, IP_OR_VLAN, strnlen_s(IP_OR_VLAN), 20));

    handle = pcap_open_offline(file_name, errbuf);
    if (handle == NULL) {
        printf("Couldn't open pcap file %s: %s\n", file_name, errbuf);
        return -1;
    }

    /* compile the filter expression */
    if (pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
        fprintf(stderr, "error: could not parse filter %s: %s\n",
                filter_exp, pcap_geterr(handle));
        pcap_close(handle);
        return -2;
    }

    /* apply the compiled filter */
    if (pcap_setfilter(handle, &fp) == -1) {
        fprintf(stderr, "error: could not install filter %s: %s\n",
                filter_exp, pcap_geterr(handle));
        pcap_close(handle);
        return -3;
    }

    while (more) {
        /* Loop over all packets in capture file */
        more = pcap_dispatch(handle, NUM_PACKETS_IN_LOOP, joy_libpcap_process_packet, (unsigned char*)index);
        /* Print out expired flows */
        //joy_print_flow_data(index,JOY_EXPIRED_FLOWS);
    }

    /* Cleanup */
    pcap_close(handle);
    if (fp.bf_insns) {
        free(fp.bf_insns);
        fp.bf_insns = NULL;
    }

    return 0;
}

int main (int argc, char **argv)
{
    int rc = 0;
    joy_init_t init_data;
    char *file = NULL;

    /* setup files */
    if (argc < 2) {
        printf("No file Specified to process\n");
        exit(0);
    } else {
        if (argc == 2) {
            file = (char*)argv[1];
        }
    }

    /* setup the joy options we want */
    memset_s(&init_data, sizeof(joy_init_t), 0x00, sizeof(joy_init_t));

   /* this setup is for general processing */
    init_data.verbosity = 4;      /* verbosity 0 (off) - 5 (critical) */
    init_data.max_records = 0;    /* max records in output file, 0 means single output file */
    init_data.contexts = 1;       /* use 3 worker contexts for processing */
    init_data.bitmask = 0xDFFFF;  /* turn on all features except IPFIX Export */

    /* intialize joy */
    rc = joy_initialize(&init_data, NULL, NULL, NULL);
    if (rc != 0) {
        printf(" -= Joy Initialized Failed =-\n");
        return -1;
    }

    /* setup anonymization of subnets */
    joy_anon_subnets("internal.net");

    /* setup anonymization of http usernames */
    joy_anon_http_usernames("anon_http.txt");

    /* setup subnet labels */
    joy_label_subnets("JoyLabTest",JOY_FILE_SUBNET,"internal.net");

    joy_print_config(0, JOY_JSON_FORMAT);
    proc_pcap_file(0, file);
    joy_print_flow_data(0, JOY_ALL_FLOWS);
    joy_context_cleanup(0);
    joy_shutdown();
    return 0;
}

