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
 * \file wht.c
 *
 * \brief walsh-hadamard transform implementation
 *
 */
#include <stdint.h>
#include "safe_lib.h"
#include <stdio.h>
#include <stdlib.h>
#include "wht.h"     
#include "config.h"
#include "err.h"

/* external definitions from joy.c */
extern FILE *info;

/**
 * \brief Initialize the memory of WHT struct.
 *
 * \param wht_handle contains wht structure to init
 *
 * \return none
 */
__inline void wht_init (wht_t **wht_handle) {
    if (*wht_handle != NULL) {
        wht_delete(wht_handle);
    }

    *wht_handle = calloc(1, sizeof(wht_t));
    if (*wht_handle == NULL) {
        /* Allocation failed */
        joy_log_err("malloc failed");
        return;
    }
}

/*
 * process 4 bytes into transform
 *    pointers are sanity checked before calling this __inline function
 */
static __inline void wht_process_four_bytes (wht_t *wht, const uint8_t *d) {
    int16_t x[4];
  
    x[0] = d[0] + d[2];
    x[1] = d[1] + d[3];
    x[2] = d[0] - d[2];
    x[3] = d[1] - d[3];
    wht->spectrum[0] += (x[0] + x[1]);
    wht->spectrum[1] += (x[0] - x[1]);
    wht->spectrum[2] += (x[2] + x[3]);
    wht->spectrum[3] += (x[2] - x[3]);
}

/**
 * \fn void wht_update (wht_t *wht,
 *                      const struct pcap_pkthdr *header,
                        const void *data,
                        unsigned int len,
                        unsigned int report_wht)
 * \param wht point to the structure
 * \param header pointer to the pcap packet header
 * \param data pointer to the data to update with
 * \param len length of the data passed in
 * \param report_wht value used to determine processing
 * \return none
 */
void wht_update (wht_t *wht, const struct pcap_pkthdr *header, const void *data, unsigned int len, unsigned int report_wht) {
    const uint8_t *d = data;

    /* sanity checks */
    if (data == NULL) {
        return;
    }

    joy_log_debug("wht[%p],header[%p],data[%p],len[%d],report[%d]",
            wht,header,data,len,report_wht);

    /* see if we should process */
    if (report_wht) {
        wht->b += len;
        while (len > 4) {
            wht_process_four_bytes(wht, d);
            d += 4;
            len -= 4;
        }
        if (len > 0) {
            uint8_t buffer[4] = { 0, 0, 0, 0 };
      
            memcpy_s(buffer, len, d, len);
            wht_process_four_bytes(wht, buffer);
        }
    }
}

/* print function for scaled walsh-hadamard structure */
static void wht_printf_scaled (const wht_t *wht, zfile f) {
    unsigned int num_bytes = wht->b;

    if (num_bytes == 0) {
        return;
    }
  
    zprintf(f, ",\"wht\":[%.5g,%.5g,%.5g,%.5g]",
	      (float) wht->spectrum[0] / num_bytes, 
	      (float) wht->spectrum[1] / num_bytes,
	      (float) wht->spectrum[2] / num_bytes,
	      (float) wht->spectrum[3] / num_bytes);
}

/**
 * \fn void wht_print_json (const wht_t *w1, const wht_t *w2, zfile f)
 * \param w1 pointer to walsh-hadamard structure1
 * \param w2 pointer to walsh-hadamard structure2
 * \param f file to be used for output
 * \return none
 */
void wht_print_json (const wht_t *w1, const wht_t *w2, zfile f) {
    int64_t s[4];
    uint64_t n;

    /* sanity check */
    if (w1 == NULL) {
        /* nothing to do */
        return;
    }

    /* if w2 is NULL, just print w1 scaled */
    if (w2 == NULL) {
        wht_printf_scaled(w1, f);
		return;
    }
  
    n = w1->b + w2->b;
    if (n == 0) {
        return;    /* there was no data, so there is no WHT to print */
    }

    /* combine each direction */
    s[0] = w1->spectrum[0] + w2->spectrum[0];  
    s[1] = w1->spectrum[1] + w2->spectrum[1];  
    s[2] = w1->spectrum[2] + w2->spectrum[2];  
    s[3] = w1->spectrum[3] + w2->spectrum[3];  

    zprintf(f, ",\"wht\":[%.5g,%.5g,%.5g,%.5g]",
	      (float) s[0] / n, 
	      (float) s[1] / n,
	      (float) s[2] / n,
	      (float) s[3] / n);
}

/**
 * \brief Delete the memory of WHT struct.
 *
 * \param wht_handle contains wht structure to delete
 *
 * \return none
 */
void wht_delete (wht_t **wht_handle) {
    wht_t *wht = *wht_handle;

    if (wht == NULL) {
        return;
    }

    /* Free the memory and set to NULL */
    free(wht);
    *wht_handle = NULL;
}

/**
 * \fn void wht_unit_test ()
 * \param none
 * \return none
 */
void wht_unit_test() {
    wht_t *wht = NULL;
    wht_t *wht2 = NULL;
    const struct pcap_pkthdr *header = NULL;

    uint8_t buffer1[8] = {
          1, 1, 1, 1, 1, 1, 1, 1
    };
    uint8_t buffer2[8] = {
          1, 0, 1, 0, 1, 0, 1, 0
    };
    uint8_t buffer3[8] = {
          0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 
          //0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf
    };
    uint8_t buffer4[4] = {
          255, 254, 253, 252
    };

    wht_init(&wht);
    wht_update(wht, header, buffer1, sizeof(buffer1), 1);

    wht_init(&wht);
    wht_update(wht, header, buffer2, sizeof(buffer2), 1);

    wht_init(&wht);
    wht_update(wht, header, buffer3, sizeof(buffer3), 1);

    wht_init(&wht);
    wht_init(&wht2);
    wht_update(wht, header, buffer4, 1, 1); /* note: only reading first byte */
    wht_update(wht, header, buffer4, 1, 1); /* note: only reading first byte */
    wht_update(wht, header, buffer4, 1, 1); /* note: only reading first byte */

    wht_delete(&wht);
    wht_delete(&wht2);
} 

