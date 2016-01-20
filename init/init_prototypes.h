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

#ifndef __INIT_PROTOTYPES_H__
#define __INIT_PROTOTYPES_H__

#include <unistd.h>

// Prototypes: files and dirs controls
bool file_contains(const char* path, const char* needle);
void dir_unlink_r(const char* path_dir, bool rm_top, bool child = false);

// Prototypes: binary executions
int system_exec(const char* argv[]);

// Prototype: elf ramdisk extraction
int extract_ramdisk(int argc, const char** argv);

#endif // __INIT_PROTOTYPES_H__
