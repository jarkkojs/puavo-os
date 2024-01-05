/* puavo-conf
 * Copyright (C) 2016 Opinsys Oy
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef PUAVO_CONF_H
#define PUAVO_CONF_H

#include <stdbool.h>
#include <stdlib.h>

typedef struct puavo_conf puavo_conf_t;

struct puavo_conf_err {
        enum {
                PUAVO_CONF_ERRNUM_SUCCESS,
                PUAVO_CONF_ERRNUM_DB,
                PUAVO_CONF_ERRNUM_SYS,
                PUAVO_CONF_ERRNUM_KEYFOUND,
                PUAVO_CONF_ERRNUM_KEYNOTFOUND,
                PUAVO_CONF_ERRNUM_TYPE,
                PUAVO_CONF_ERRNUM_DBUS,
                PUAVO_CONF_ERRNUMCOUNT
        } errnum;
        int db_error;
        int sys_errno;
        char msg[1024];
};

enum puavo_conf_type {
        PUAVO_CONF_TYPE_ANY,
        PUAVO_CONF_TYPE_BOOL
};

/**
 * puavo_conf_open() - open a config backend
 *
 * @conf - initialized config object
 *
 * @errp - pointer to an error struct or NULL
 *
 * After a successful call, the caller is responsible for calling
 * puavo_conf_close().
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_open(puavo_conf_t **confp,
                    struct puavo_conf_err *errp);

/**
 * puavo_conf_open_direct() - open a config backend with direct database access
 *
 * @conf - initialized config object
 *
 * @errp - pointer to an error struct or NULL
 *
 * After a successful call, the caller is responsible for calling
 * puavo_conf_close().
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_open_direct(puavo_conf_t **confp,
                           struct puavo_conf_err *errp);

/**
 * puavo_conf_close() - close a config backend
 *
 * @conf - initialized config object
 *
 * @errp - pointer to an error struct or NULL
 *
 * This function must be called on every succesfully opened config
 * backend object to ensure all config operations get finished and all
 * resources get released properly.
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_close(puavo_conf_t *conf,
                     struct puavo_conf_err *errp);

/**
 * puavo_conf_clear() - remove all parameters
 *
 * @conf - initialized config object
 *
 * @errp - pointer to an error struct or NULL
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_clear(puavo_conf_t *conf,
                     struct puavo_conf_err *errp);

/**
 * puavo_conf_set() - store a parameter
 *
 * @conf  - initialized config object
 *
 * @key   - NUL-terminated string constant
 *
 * @value - NUL-terminated string constant
 *
 * @errp  - pointer to an error struct or NULL
 *
 * If @key already exists in the config backend, the value is
 * overwritten.
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_set(puavo_conf_t *conf,
                   char const *key,
                   char const *value,
                   struct puavo_conf_err *errp);

/**
 * puavo_conf_overwrite() - overwrite a parameter value
 *
 * @conf  - initialized config object
 *
 * @key   - NUL-terminated string constant
 *
 * @value - NUL-terminated string constant
 *
 * @errp  - pointer to an error struct or NULL
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Errnums:
 *
 * PUAVO_CONF_ERRNUM_KEYNOTFOUND - @key does not exist in the config backend
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_overwrite(puavo_conf_t *conf,
                         char const *key,
                         char const *value,
                         struct puavo_conf_err *errp);

/**
 * puavo_conf_add() - add a new parameter
 *
 * @conf  - initialized config object
 *
 * @key   - NUL-terminated string constant
 *
 * @value - NUL-terminated string constant
 *
 * @errp  - pointer to an error struct or NULL
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Errnums:
 *
 * PUAVO_CONF_ERRNUM_KEYFOUND - @key already exists in the config backend
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_add(puavo_conf_t *conf,
                   char const *key,
                   char const *value,
                   struct puavo_conf_err *errp);

/**
 * puavo_conf_has_key() - check if the parameter exists
 *
 * @conf   - initialized config object
 *
 * @key    - NUL-terminated string constant
 *
 * @haskey - pointer to a boolean
 *
 * @errp   - pointer to an error struct or NULL
 *
 * If @key exists in the config backend, @haskey is set to true,
 * otherwise to false.
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_has_key(puavo_conf_t *conf,
                       char const *key,
                       bool *haskey,
                       struct puavo_conf_err *errp);

/**
 * puavo_conf_get() - get a parameter value
 *
 * @conf   - initialized config object
 *
 * @key    - NUL-terminated string constant
 *
 * @valuep - pointer to an uninitialized string or NULL
 *
 * @errp  - pointer to an error struct or NULL
 *
 * After a successful call, if @valuep is not NULL, @valuep points to a
 * heap-allocated NUL-terminated string value for @key. The caller is
 * responsible for calling free() on the string afterwards.
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_get(puavo_conf_t *conf,
                   char const *key,
                   char **valuep,
                   struct puavo_conf_err *errp);

struct puavo_conf_list {
        char **keys;
        char **values;
        size_t length;
};

/**
 * puavo_conf_get_all() - get a list of all parameters
 *
 * @conf - initialized config object
 *
 * @list - uninitialized parameter list
 *
 * @errp  - pointer to an error struct or NULL
 *
 * After a successful call, @list contains two heap-allocated vectors
 * of heap-allocated NUL-terminated strings. The caller is responsible
 * for calling puavo_conf_list_free() on @list afterwards.
 *
 * If @errp is not NULL and an error is encountered, the error struct
 * pointed by @errp is filled to convey error details.
 *
 * Return 0 on success and -1 on error.
 */
int puavo_conf_get_all(puavo_conf_t *conf,
                       struct puavo_conf_list *list,
                       struct puavo_conf_err *errp);

/**
 * puavo_conf_list_free() - free a parameter list
 *
 * @list - initialized parameter list
 */
void puavo_conf_list_free(struct puavo_conf_list *list);

enum puavo_conf_conn {
        PUAVO_CONF_CONN_DB,
        PUAVO_CONF_CONN_DBUS
};

/**
 * puavo_conf_get_conn() - get connection type
 *
 * Return PUAVO_CONF_CONN_DB if @conf is connected directly to the
 * database or PUAVO_CONF_CONN_DBUS if @conf relies on DBus to
 * communicate with the database manager.
 *
 */
enum puavo_conf_conn puavo_conf_get_conn(puavo_conf_t const *conf);

#endif /* PUAVO_CONF_H */
