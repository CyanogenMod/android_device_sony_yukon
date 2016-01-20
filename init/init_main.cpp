/*
 * Copyright (C) 2016 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>

#include <sys/mount.h>
#include <sys/stat.h>
#include <unistd.h>

#include "init_board.h"
#include "init_prototypes.h"

// Main: executable
int main(int __attribute__((unused)) argc, char** __attribute__((unused)) argv)
{
    // Execution variables
    bool recoveryBoot;

    // Create directories
    mkdir("/dev/block", 0755);
    mkdir("/proc", 0555);
    mkdir("/sys", 0755);

    // Create device nodes
    mknod(DEV_BLOCK_PATH, S_IFBLK | 0600,
            makedev(DEV_BLOCK_MAJOR, DEV_BLOCK_MINOR));
    mknod("/dev/null", S_IFCHR | 0666, makedev(1, 3));

    // Mount filesystems
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);

    // Recovery boot detection
    recoveryBoot = file_contains(WARMBOOT_CMDLINE, WARMBOOT_RECOVERY);

    // Boot to Recovery
    if (recoveryBoot)
    {
        // FOTA Recovery importation
        mknod(DEV_BLOCK_FOTA_PATH, S_IFBLK | 0600,
                makedev(DEV_BLOCK_MAJOR, atoi(DEV_BLOCK_FOTA_NUM)));
        mount("/", "/", NULL, MS_MGC_VAL | MS_REMOUNT, "");
        const char* argv_extract_elf[] = { "", "-i", DEV_BLOCK_FOTA_PATH,
                "-o", SBIN_CPIO_RECOVERY, "-t", "/" };
        extract_ramdisk(sizeof(argv_extract_elf) / sizeof(const char*),
                argv_extract_elf);

        // Recovery ramdisk
        const char* argv_ramdiskcpio[] = { EXEC_TOYBOX, "cpio", "-i", "-F",
                SBIN_CPIO_RECOVERY, nullptr };
        system_exec(argv_ramdiskcpio);
    }

    // Unmount filesystems
    umount("/proc");
    umount("/sys");

    // Unlink /dev/*
    dir_unlink_r("/dev", false);

    // Rename init
    unlink("/init");
    rename("/init.real", "/init");

    // Launch init
    const char* argv_init[] = { "/init", nullptr };
    system_exec(argv_init);

    return 0;
}
