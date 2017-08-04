/* puavo-conf-update
 * Copyright (C) 2016 Opinsys Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#define _GNU_SOURCE

#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>

#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <fnmatch.h>
#include <getopt.h>
#include <glob.h>
#include <jansson.h>
#include <limits.h>
#include <regex.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "conf.h"

#define DEFINITIONS_DIR "/usr/share/puavo-conf/definitions"
#define DEVICEJSON_PATH "/etc/puavo/device.json"
#define DMI_ID_PATH     "/sys/class/dmi/id"
#define HWQUIRKS_DIR    "/usr/share/puavo-conf/hwquirk-overwrites"
#define IMAGE_CONF_PATH "/etc/puavo-conf/image.json"
#define PROFILES_DIR    "/usr/share/puavo-conf/profile-overwrites"

#define PCI_MAX         1024
#define USB_MAX         1024

char *puavo_hosttype;

struct dmi {
	const char      *key;
	char            *value;
};

struct hw_characteristics {
	struct dmi	*dmi_table;
	size_t		 dmi_itemcount;
	char		*pci_ids[PCI_MAX];
	size_t		 pci_id_count;
	char		*usb_ids[USB_MAX];
	size_t		 usb_id_count;
};

static int	 apply_device_settings(puavo_conf_t *, const char *, int);
static int	 apply_hosttype_profile(puavo_conf_t *, int);
static int	 apply_hwquirk_rule_parameters(puavo_conf_t *, json_t *, int);
static int	 apply_hwquirks(puavo_conf_t *, int);
static int	 apply_hwquirks_from_rules(puavo_conf_t *,
    struct hw_characteristics *, int);
static int	 apply_hwquirks_from_a_json_root(puavo_conf_t *, json_t *,
    struct hw_characteristics *, int);
static int	 apply_kernel_arguments(puavo_conf_t *, int);
static int	 apply_one_profile(puavo_conf_t *, const char *, int);
static int	 apply_profiles(puavo_conf_t *, int);
static int	 check_match_for_hwquirk_rule(const char *, const char *,
    const char *, struct hw_characteristics *);
static char	*get_cmdline(void);
static char	*get_first_line(const char *);
static int	 glob_error(const char *, int);
static int	 handle_one_paramdef(puavo_conf_t *, const char *, json_t *,
    int);
static int	 handle_paramdef_file(puavo_conf_t *, const char *, int);
static int	 init_with_parameter_definitions(puavo_conf_t *, int);
static int	 lookup_ids_from_cmd(const char *, size_t, char **, size_t *,
    size_t);
static int	 match_pattern(const char *, const char *, const regex_t *,
    const char *);
static int	 overwrite_value(puavo_conf_t *, const char *, const char *,
    int);
static json_t	*parse_json_file(const char *);
static int	 update_dmi_table(struct dmi *, size_t);
static int	 update_puavoconf(puavo_conf_t *, const char *, int);
static void	 usage(void);

int
main(int argc, char *argv[])
{
	puavo_conf_t *conf;
	struct puavo_conf_err err;
	const char *device_json_path;
	static struct option long_options[] = {
	    { "devicejson-path", required_argument, 0, 0 },
	    { "help",            no_argument,       0, 0 },
	    { "init",            no_argument,       0, 0 },
	    { "verbose",         no_argument,       0, 0 },
	    { 0,                 0,                 0, 0 },
	};
	int c, init, option_index, status, verbose;

	init = 0;
	status = 0;
	verbose = 0;

	device_json_path = DEVICEJSON_PATH;

	for (;;) {
		option_index = 0;
		c = getopt_long(argc, argv, "", long_options, &option_index);
		if (c == -1)
			break;

		if (c != 0) {
			usage();
			return 1;
		}

		switch (option_index) {
		case 0:
			device_json_path = optarg;
			break;
		case 1:
			usage();
			return 0;
		case 2:
			init = 1;
			break;
		case 3:
			verbose = 1;
			break;
		default:
			usage();
			return 1;
		}
	}

	if (optind < argc) {
		usage();
		return 1;
	}

	if (puavo_conf_open(&conf, &err))
		errx(1, "Failed to open config backend: %s", err.msg);

	if (init) {
		if (init_with_parameter_definitions(conf, verbose) != 0) {
			warnx("failure in initializing puavo conf db");
			status = EXIT_FAILURE;
		}
	}

	if (update_puavoconf(conf, device_json_path, verbose) != 0) {
		warnx("problem in updating puavoconf");
		status = EXIT_FAILURE;
	}

	if (puavo_conf_close(conf, &err) == -1) {
		warnx("Failed to close config backend: %s", err.msg);
		status = EXIT_FAILURE;
	}

	return status;

	return 0;
}

static void
usage(void)
{
	printf("Usage:\n"
	       "    puavo-conf-update [OPTION]...\n"
	       "\n"
	       "Update configuration database by overwriting parameter values\n"
	       "from the following sources, in the given order:\n"
	       "\n"
	       "  1. image specific settings from " IMAGE_CONF_PATH "\n"
	       "  2. requested puavo-conf profiles (using puavo.profiles.list)\n"
	       "  3. hardware quirks\n"
	       "  4. device specific settings from " DEVICEJSON_PATH "\n"
	       "  5. kernel command line\n"
	       "\n"
	       "Options:\n"
	       "  --help                    display this help and exit\n"
	       "  --devicejson-path FILE    filepath of the device.json,\n"
	       "                            defaults to " DEVICEJSON_PATH "\n"
	       "  --init                    initialize the database\n"
	       "  --verbose                 verbose output\n"
	       "\n");
}

static int
init_with_parameter_definitions(puavo_conf_t *conf, int verbose)
{
	glob_t globbuf;
	size_t i;
	int ret, retvalue;

	retvalue = 0;

	ret = glob(DEFINITIONS_DIR "/*.json", 0, glob_error, &globbuf);
	if (ret != 0) {
		if (ret == GLOB_NOMATCH)
			return 0;
		warnx("glob() failure in init_with_parameter_definitions()");
		globfree(&globbuf);
		return 1;
	}

	for (i = 0; i < globbuf.gl_pathc; i++) {
		ret = handle_paramdef_file(conf, globbuf.gl_pathv[i], verbose);
		if (ret != 0) {
			warnx("error handling %s", globbuf.gl_pathv[i]);
			/* Return error, but try other files. */
			retvalue = 1;
		}
	}

	globfree(&globbuf);

	return retvalue;
}

static int
glob_error(const char *epath, int eerrno)
{
	if (eerrno == ENOENT)
		return 0;

	warnx("glob error with %s: %s", epath, strerror(eerrno));

	return 1;
}

static int
handle_paramdef_file(puavo_conf_t *conf, const char *filepath, int verbose)
{
	json_t *root, *param_value;
	const char *param_name;
	int ret, retvalue;

	retvalue = 0;

	if ((root = parse_json_file(filepath)) == NULL) {
		warnx("parse_json_file() failed for %s", filepath);
		return 1;
	}

	if (!json_is_object(root)) {
		warnx("root is not a json object in %s", filepath);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(root, param_name, param_value) {
		ret = handle_one_paramdef(conf, param_name, param_value,
		    verbose);
		if (ret != 0) {
			warnx("error handling %s in %s", param_name, filepath);
			/* Return error, but try other keys. */
			retvalue = 1;
		}
	}

finish:
	json_decref(root);

	return retvalue;
}

static int
handle_one_paramdef(puavo_conf_t *conf, const char *param_name,
    json_t *param_value, int verbose)
{
	json_t *default_node;
	struct puavo_conf_err err;
	const char *value;

	if (!json_is_object(param_value)) {
		warnx("parameter %s does not have an object as value",
		    param_name);
		return 1;
	}

	if ((default_node = json_object_get(param_value, "default")) == NULL) {
		warnx("parameter %s does not have a default value", param_name);
		return 1;
	}

	if ((value = json_string_value(default_node)) == NULL) {
		warnx("parameter %s default is not a string", param_name);
		return 1;
	}

	if (puavo_conf_add(conf, param_name, value, &err) != 0) {
		warnx("error adding %s --> '%s' : %s", param_name, value,
		    err.msg);
		return 1;
	}

	if (verbose) {
		(void) printf("puavo-conf-update: initialized puavo conf key"
		    " %s --> %s\n", param_name, value);
	}

	return 0;
}

static int
update_puavoconf(puavo_conf_t *conf, const char *device_json_path, int verbose)
{
	int retvalue;

	retvalue = 0;

	/* First apply kernel arguments, because we get puavo.hosttype
	 * and puavo.profiles.list from there, which affect subsequent
	 * settings. */
	if (apply_kernel_arguments(conf, verbose) != 0)
		retvalue = 1;

	if (apply_one_profile(conf, IMAGE_CONF_PATH, verbose) != 0)
		retvalue = 1;

	if (apply_profiles(conf, verbose) != 0)
		retvalue = 1;

	if (apply_hwquirks(conf, verbose) != 0)
		retvalue = 1;

	if (apply_device_settings(conf, device_json_path, verbose) != 0)
		retvalue = 1;

	/* Apply kernel arguments again,
	 * because those override everything else. */
	if (apply_kernel_arguments(conf, verbose) != 0)
		retvalue = 1;

	return retvalue;
}

static int
apply_profiles(puavo_conf_t *conf, int verbose)
{
	struct puavo_conf_err err;
	char *profile, *profiles, *profile_path;
	int retvalue, ret;

	ret = puavo_conf_get(conf, "puavo.profiles.list", &profiles, &err);
	if (ret == -1) {
		warnx("error getting puavo.profiles.list: %s", err.msg);
		return 1;
	}

	/*
	 * If no profiles have been set, use puavo.hosttype variable as
	 * the profile name.
	 */
	if (strcmp(profiles, "") == 0) {
		if (verbose) {
			(void) printf("puavo-conf-update: applying hosttype"
			    " profile because puavo.profiles.list is not"
			    " set\n");
		}

		free(profiles);
		return apply_hosttype_profile(conf, verbose);
	}

	retvalue = 0;

	while ((profile = strsep(&profiles, ",")) != NULL) {
		ret = asprintf(&profile_path, PROFILES_DIR "/%s.json",
		    profile);
		if (ret == -1) {
			warnx("asprintf() error in apply_hosttype_profile()");
			retvalue = 1;
			continue;
		}

		if (apply_one_profile(conf, profile_path, verbose) != 0)
			retvalue = 1;
		free(profile_path);
	}

	free(profiles);

	return retvalue;
}

static int
apply_hosttype_profile(puavo_conf_t *conf, int verbose)
{
	struct puavo_conf_err err;
	char *hosttype;
	char *hosttype_profile_path;
	int ret, retvalue;

	if (puavo_conf_get(conf, "puavo.hosttype", &hosttype, &err) == -1) {
		warnx("error getting puavo.hosttype: %s", err.msg);
		return 1;
	}

	ret = asprintf(&hosttype_profile_path, PROFILES_DIR "/%s.json",
	    hosttype);
	if (ret == -1) {
		warnx("asprintf() error in apply_hosttype_profile()");
		free(hosttype);
		return 1;
	}

	retvalue = 0;

	if (apply_one_profile(conf, hosttype_profile_path, verbose) != 0)
		retvalue = 1;

	free(hosttype);
	free(hosttype_profile_path);

	return retvalue;
}

static char *
get_cmdline(void)
{
	FILE *cmdline;
	char *line;
	size_t n;

	if ((cmdline = fopen("/proc/cmdline", "r")) == NULL) {
		warn("fopen /proc/cmdline");
		return NULL;
	}

	line = NULL;
	n = 0;
	if (getline(&line, &n, cmdline) == -1) {
		warn("getline() on /proc/cmdline");
		free(line);
		return NULL;
	}

	(void) fclose(cmdline);

	return line;
}

static int
apply_device_settings(puavo_conf_t *conf, const char *device_json_path,
    int verbose)
{
	json_t *root, *device_conf, *node_value;
	const char *param_name, *param_value;
	int ret, retvalue;

	if (verbose) {
		(void) printf("puavo-conf-update: applying device settings"
		    " from %s\n", device_json_path);
	}

	retvalue = 0;

	if ((root = parse_json_file(device_json_path)) == NULL) {
		warnx("parse_json_file() failed for %s", device_json_path);
		return 1;
	}

	if (!json_is_object(root)) {
		warnx("device settings in %s are not in correct format",
		    device_json_path);
		retvalue = 1;
		goto finish;
	}

	if ((device_conf = json_object_get(root, "conf")) == NULL) {
		warnx("device settings in %s are lacking configuration values",
		    device_json_path);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(device_conf, param_name, node_value) {
		if ((param_value = json_string_value(node_value)) == NULL) {
			warnx("device settings in %s has a non-string value"
			    " for key %s", device_json_path, param_name);
			retvalue = 1;
			continue;
		}
		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

finish:
	json_decref(root);

	return retvalue;
}

static int
apply_one_profile(puavo_conf_t *conf, const char *profile_path, int verbose)
{
	json_t *root, *node_value;
	const char *param_name, *param_value;
	int ret, retvalue;

	retvalue = 0;
	root = NULL;

	if (verbose) {
		(void) printf("puavo-conf-update: applying profile %s\n",
		    profile_path);
	}

	if ((root = parse_json_file(profile_path)) == NULL) {
		warnx("parse_json_file() failed for %s", profile_path);
		retvalue = 1;
		goto finish;
	}

	if (!json_is_object(root)) {
		warnx("profile %s is not in correct format", profile_path);
		retvalue = 1;
		goto finish;
	}

	json_object_foreach(root, param_name, node_value) {
		if ((param_value = json_string_value(node_value)) == NULL) {
			warnx("profile %s has a non-string value for key %s",
			    profile_path, param_name);
			retvalue = 1;
			continue;
		}
		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

finish:
	if (root != NULL)
		json_decref(root);

	return retvalue;
}

static int
apply_hwquirks(puavo_conf_t *conf, int verbose)
{
	struct dmi dmi_table[] = {
		{ "bios_date",         NULL, },
		{ "bios_date",         NULL, },
		{ "bios_vendor",       NULL, },
		{ "bios_version",      NULL, },
		{ "board_asset_tag",   NULL, },
		{ "board_name",        NULL, },
		{ "board_serial",      NULL, },
		{ "board_vendor",      NULL, },
		{ "board_version",     NULL, },
		{ "chassis_asset_tag", NULL, },
		{ "chassis_serial",    NULL, },
		{ "chassis_type",      NULL, },
		{ "chassis_vendor",    NULL, },
		{ "chassis_version",   NULL, },
		{ "product_name",      NULL, },
		{ "product_serial",    NULL, },
		{ "product_uuid",      NULL, },
		{ "product_version",   NULL, },
		{ "sys_vendor",        NULL, },
	};
	struct hw_characteristics hw;
	size_t i;
	int ret, retvalue;

	retvalue = 0;

	hw.dmi_table = dmi_table;
	hw.dmi_itemcount = sizeof(dmi_table) / sizeof(struct dmi);
	hw.pci_id_count = 0;
	hw.usb_id_count = 0;

	ret = update_dmi_table(hw.dmi_table, hw.dmi_itemcount);
	if (ret != 0)
		retvalue = ret;

	ret = lookup_ids_from_cmd("lspci -n", 3, hw.pci_ids, &hw.pci_id_count,
	    PCI_MAX);
	if (ret != 0)
		retvalue = ret;

	ret = lookup_ids_from_cmd("lsusb", 6, hw.usb_ids, &hw.usb_id_count,
	    USB_MAX);
	if (ret != 0)
		retvalue = ret;

	if (verbose) {
		for (i = 0; i < hw.dmi_itemcount; i++) {
			(void) printf("puavo-conf-update: dmi id %s = %s\n",
			    dmi_table[i].key, dmi_table[i].value);
		}
		for (i = 0; i < hw.pci_id_count; i++) {
			(void) printf("puavo-conf-update: found PCI device"
			    " %s\n", hw.pci_ids[i]);
		}
		for (i = 0; i < hw.usb_id_count; i++) {
			(void) printf("puavo-conf-update: found USB device"
			    " %s\n", hw.usb_ids[i]);
		}
	}

	ret = apply_hwquirks_from_rules(conf, &hw, verbose);
	if (ret != 0)
		retvalue = ret;

	/* free tables */
	for (i = 0; i < hw.dmi_itemcount; i++)
		free(hw.dmi_table[i].value);
	for (i = 0; i < hw.pci_id_count; i++)
		free(hw.pci_ids[i]);
	for (i = 0; i < hw.usb_id_count; i++)
		free(hw.usb_ids[i]);

	return retvalue;
}

static int
apply_hwquirks_from_rules(puavo_conf_t *conf, struct hw_characteristics *hw,
    int verbose)
{
	json_t *root;
	glob_t globbuf;
	size_t i;
	int ret, retvalue;
	const char *quirkfilepath;

	retvalue = 0;

	ret = glob(HWQUIRKS_DIR "/*.json", 0, glob_error, &globbuf);
	if (ret != 0) {
		if (ret == GLOB_NOMATCH)
			return 0;
		warnx("glob() failure in apply_hwquirks_from_rules()");
		globfree(&globbuf);
		return 1;
	}

	for (i = 0; i < globbuf.gl_pathc; i++) {
		quirkfilepath = globbuf.gl_pathv[i];

		if ((root = parse_json_file(quirkfilepath)) == NULL) {
			warnx("parse_json_file() failed for %s", quirkfilepath);
			retvalue = 1;
			continue;
		}
		ret = apply_hwquirks_from_a_json_root(conf, root, hw, verbose);
		if (ret != 0) {
			warnx("apply_hwquirks_from_a_json_root() failed for %s",
			    quirkfilepath);
			retvalue = 1;
		}

		json_decref(root);
	}

	return retvalue;
}

static int
apply_hwquirks_from_a_json_root(puavo_conf_t *conf, json_t *root,
    struct hw_characteristics *hw, int verbose)
{
	json_t *rule, *key_obj, *mm_obj, *pattern_obj, *params_obj;
	const char *key, *matchmethod, *pattern;
	size_t i;
	int is_match, ret, retvalue;

	retvalue = 0;

	if (!json_is_array(root)) {
		warnx("rules file json is not a json array");
		return 1;
	}

	json_array_foreach(root, i, rule) {
		if (!json_is_object(rule)) {
			warnx("hwquirk rule is not an object");
			retvalue = 1;
			continue;
		}

		if ((key_obj = json_object_get(rule, "key")) == NULL ||
		    (key = json_string_value(key_obj)) == NULL) {
			warnx("hwquirk rule field 'key' is missing");
			retvalue = 1;
			continue;
		}

		if ((mm_obj = json_object_get(rule, "matchmethod")) == NULL ||
		    (matchmethod = json_string_value(mm_obj)) == NULL) {
			warnx("hwquirk rule field 'matchmethod' is missing");
			retvalue = 1;
			continue;
		}

		if ((pattern_obj = json_object_get(rule, "pattern")) == NULL ||
		    (pattern = json_string_value(pattern_obj)) == NULL) {
			warnx("hwquirk rule field 'pattern' is missing");
			retvalue = 1;
			continue;
		}

		params_obj = json_object_get(rule, "parameters");
		if (params_obj == NULL) {
			warnx("hwquirk rule field 'parameters' is missing");
			retvalue = 1;
			continue;
		}

		is_match = check_match_for_hwquirk_rule(key, matchmethod,
		    pattern, hw);
		if (is_match) {
			if (verbose) {
				(void) printf("puavo-conf-update: APPLYING"
				    " hwquirk rule with key=%s matchmethod=%s"
				    " pattern=%s\n", key, matchmethod,
				    pattern);
			}

			ret = apply_hwquirk_rule_parameters(conf, params_obj,
			    verbose);
			if (ret != 0)
				retvalue = 1;
			if (verbose) {
				(void) printf("puavo-conf-update: ... hwquirk"
				    " rule done\n");
			}
		} else {
			(void) printf("puavo-conf-update: hwquirk rule"
			    " with key=%s matchmethod=%s pattern=%s did not"
			    " match\n", key, matchmethod, pattern);
		}
	}

	return retvalue;
}

static int
check_match_for_hwquirk_rule(const char *key, const char *matchmethod,
    const char *pattern, struct hw_characteristics *hw)
{
	regex_t regex;
	regex_t *regex_p;
	size_t i;
	int match;

	match = 0;

	if (strcmp(matchmethod, "regexp") == 0) {
		if (regcomp(&regex, pattern, REG_EXTENDED|REG_NOSUB) != 0) {
			warn("error compiling regexp %s", pattern);
			return 0;
		}
		regex_p = &regex;
	} else {
		regex_p = NULL;
	}

	if (strcmp(key, "pci-id") == 0) {
		for (i = 0; i < hw->pci_id_count; i++) {
			match = match_pattern(matchmethod, pattern, regex_p,
			    hw->pci_ids[i]);
			if (match)
				break;
		}
	} else if (strcmp(key, "usb-id") == 0) {
		for (i = 0; i < hw->usb_id_count; i++) {
			match = match_pattern(matchmethod, pattern, regex_p,
			    hw->usb_ids[i]);
			if (match)
				break;
		}
	} else {
		for (i = 0; i < hw->dmi_itemcount; i++) {
			if (strcmp(hw->dmi_table[i].key, key) == 0) {
				match = match_pattern(matchmethod, pattern,
				    regex_p, hw->dmi_table[i].value);
				if (match)
					break;
			}
		}
	}

	if (regex_p != NULL)
		regfree(regex_p);

	return match;
}

static int
match_pattern(const char *matchmethod, const char *pattern,
    const regex_t *regex, const char *value)
{
	if (regex != NULL)
		return (regexec(regex, value, 0, NULL, 0) == 0);

	if (strcmp(matchmethod, "exact") == 0)
		return (strcmp(pattern, value) == 0);

	if (strcmp(matchmethod, "glob") == 0)
		return (fnmatch(pattern, value, 0) == 0);

	warnx("Unsupported matchmethod %s", matchmethod);

	return 0;
}

static int
apply_hwquirk_rule_parameters(puavo_conf_t *conf, json_t *params_obj,
    int verbose)
{
	json_t *node_value;
	const char *param_name, *param_value;
	int ret, retvalue;

	retvalue = 0;

	if (!json_is_object(params_obj)) {
		warnx("parameters in hwquirk rule is not an object");
		return 1;
	}

	json_object_foreach(params_obj, param_name, node_value) {
		if ((param_value = json_string_value(node_value)) == NULL) {
			warnx("parameter value in hwquirk is not a string");
			retvalue = 1;
		}
		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;

	}

	return retvalue;
}

static int
lookup_ids_from_cmd(const char *cmd_string, size_t fieldnum, char **idtable,
    size_t *id_count, size_t id_max)
{
	FILE *cmd_pipe;
	char **next_id;
	char *field, *line, *linep;
	size_t i, n;
	ssize_t len;
	int cmd_status, retvalue;

	retvalue = 0;

	if ((cmd_pipe = popen(cmd_string, "r")) == NULL) {
		warn("%s popen error", cmd_string);
		return 1;
	}

	for (;;) {
		line = NULL;
		n = 0;
		len = getline(&line, &n, cmd_pipe);
		if (len == -1) {
			if (feof(cmd_pipe))
				break;
			warn("could not read a line from %s", cmd_string);
			free(line);
			retvalue = 1;
			break;
		} else if (len < 1) {
			continue;
		}
		line[len-1] = '\0';	/* remove newline */

		linep = line;
		for (i = 0; i < fieldnum; i++) {
			field = strsep(&linep, " \t");
			if (field == NULL) {
				warn("could not parse a line from %s",
				    cmd_string);
				retvalue = 1;
				break;
			}
		}
		if (field != NULL) {
			next_id = &idtable[*id_count];
			if ((*next_id = strdup(field)) == NULL) {
				warn("strdup() with %s", field);
				retvalue = 1;
				free(line);
				continue;
			}

			(*id_count)++;
			if (*id_count >= id_max) {
				warnx("id count maximum reached");
				retvalue = 1;
				free(line);
				break;
			}
		}

		free(line);
	}

	cmd_status = pclose(cmd_pipe);
	if (cmd_status == -1) {
		warn("%s error with pclose()", cmd_string);
		retvalue = 1;
	} else if (cmd_status != 0) {
		warnx("%s returned error code %d", cmd_string, cmd_status);
		retvalue = 1;
	}

	return retvalue;
}

static char *
get_first_line(const char *path)
{
	FILE *id_file;
	char *line;
	ssize_t s;
	size_t n;

	if ((id_file = fopen(path, "r")) == NULL) {
		warn("could not open %s", path);
		return NULL;
	}

	line = NULL;
	n = 0;
	s = getline(&line, &n, id_file);
	if (s == -1) {
		warn("could not read a line from %s", path);
		free(line);
		line = NULL;
	} else if (s >= 1) {
		line[s-1] = '\0';	/* remove newline */
	}

	if (fclose(id_file) != 0)
		warn("could not close a file");

	return line;
}

static int
update_dmi_table(struct dmi *dmi_table, size_t tablesize)
{
	char id_path[PATH_MAX];
	char *line;
	size_t i;
	int ret, retvalue;

	retvalue = 0;

	for (i = 0; i < tablesize; i++) {
		ret = snprintf(id_path, PATH_MAX, "%s/%s", DMI_ID_PATH,
		    dmi_table[i].key);
		if (ret >= PATH_MAX) {
			warnx("snprintf() error with %s", dmi_table[i].key);
			retvalue = 1;
			continue;
		}

		if ((line = get_first_line(id_path)) == NULL) {
			retvalue = 1;
			continue;
		}

		dmi_table[i].value = line;
	}

	return retvalue;
}

static int
apply_kernel_arguments(puavo_conf_t *conf, int verbose)
{
	char *cmdarg, *cmdline, *param_name, *param_value;
	size_t prefix_len;
	int ret, retvalue;

	(void) printf("puavo-conf-update: applying kernel arguments\n");

	cmdline = get_cmdline();
	if (cmdline == NULL) {
		warnx("could not read /proc/cmdline");
		return 1;
	}

	retvalue = 0;

	prefix_len = sizeof("puavo.") - 1;

	while ((cmdarg = strsep(&cmdline, " \t\n")) != NULL) {
		if (strncmp(cmdarg, "puavo.", prefix_len) != 0)
			continue;

		param_value = cmdarg;
		param_name = strsep(&param_value, "=");
		if (param_value == NULL)
			continue;

		ret = overwrite_value(conf, param_name, param_value, verbose);
		if (ret != 0)
			retvalue = 1;
	}

	free(cmdline);

	return retvalue;
}

static int
overwrite_value(puavo_conf_t *conf, const char *key, const char *value,
    int verbose)
{
	struct puavo_conf_err err;

	if (puavo_conf_overwrite(conf, key, value, &err) != 0) {
		warnx("error overwriting %s --> '%s' : %s", key, value,
		    err.msg);
		return 1;
	}

	if (verbose) {
		(void) printf("puavo-conf-update: setting puavo conf key %s"
		    " --> %s\n", key, value);
	}

	return 0;
}

static json_t *
parse_json_file(const char *filepath)
{
	json_t *root;
	json_error_t error;
	const char *json;
	off_t len;
	int fd;

	root = NULL;

	if ((fd = open(filepath, O_RDONLY)) == -1) {
		warn("open() on %s", filepath);
		return NULL;
	}

	if ((len = lseek(fd, 0, SEEK_END)) == -1) {
		warn("lseek() on %s", filepath);
		goto finish;
	}
	if (len == 0) {
		warnx("file %s has zero size", filepath);
		goto finish;
	}

	if ((json = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0)) == NULL) {
		warn("mmap() on %s", filepath);
		goto finish;
	}

	if ((root = json_loads(json, 0, &error)) == NULL) {
		warnx("error parsing json file %s line %d: %s", filepath,
		    error.line, error.text);
	}

finish:
	(void) close(fd);

	return root;
}
