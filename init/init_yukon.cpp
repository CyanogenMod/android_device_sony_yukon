/*
   Copyright (c) 2015, The CyanogenMod Project

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdlib.h>
#include <stdio.h>

#include "vendor_init.h"
#include "property_service.h"
#include "log.h"
#include "util.h"

#include "init_msm.h"

#include "variants.h"

static int dual_sim = 0;
char model[PROP_VALUE_MAX];

static void import_cmdline(char *name, int for_emulator)
{
    char *value = strchr(name, '=');
    int name_len = strlen(name);

    if (value == 0) return;
    *value++ = 0;
    if (name_len == 0) return;

    if (!strcmp(name,"oemandroidboot.phoneid") && (strlen(value) > 30) ) {
        dual_sim = 1;
    }
}

void ds_properties()
{
    property_set("persist.radio.multisim.config", "dsds");
    property_set("ro.telephony.default_network", "0,1");
    property_set("ro.telephony.ril.config", "simactivation");
}

void variant_from_prop()
{
    int variantID = 0;

    // strip first character
    strcpy(model, &model[1]);

    while((int)model != variants[variantID][0])
        variantID++;

    property_set("ro.product.model", model);

    if (variants[variantID][1]) { // DS
        ds_properties();
    } else if (variants[variantID][2]) { // LTE
        property_set("ro.telephony.default_network", "9");
    } else {
        property_set("ro.telephony.default_network", "0");
    }

}

void variant_from_cmdline()
{
    import_kernel_cmdline(0, import_cmdline);

    if (dual_sim) {
        unsigned int variantID = 0;
        const char* prefix = "D"; // Model prefix
        char modelNo[PROP_VALUE_MAX];

        while(variants[variantID][1] != 1 && variantID < sizeof(variants)/(sizeof (variants[0])))
            variantID++;

        sprintf(modelNo, "%d", variants[variantID][0]);
        strcpy(model, prefix);
        strcat(model, modelNo);

        property_set("ro.product.model", model);
        ds_properties();
    } else {
        property_set("ro.telephony.default_network", "9");
    }
}
void init_msm_properties(unsigned long msm_id, unsigned long msm_ver, char *board_type)
{
    UNUSED(msm_id);
    UNUSED(msm_ver);
    UNUSED(board_type);

    property_get("ro.fxp.variant", model);

    if (strcmp(model, "")) {
        variant_from_prop();
    } else {
        variant_from_cmdline();
    }
}
