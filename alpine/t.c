/*
  +----------------------------------------------------------------------+
  | PHP Version 5                                                        |
  +----------------------------------------------------------------------+
  | Copyright (c) 1997-2014 The PHP Group                                |
  +----------------------------------------------------------------------+
  | This source file is subject to version 3.01 of the PHP license,      |
  | that is bundled with this package in the file LICENSE, and is        |
  | available through the world-wide-web at the following url:           |
  | http://www.php.net/license/3_01.txt                                  |
  | If you did not receive a copy of the PHP license and are unable to   |
  | obtain it through the world-wide-web, please send a note to          |
  | license@php.net so we can mail you a copy immediately.               |
  +----------------------------------------------------------------------+
  | Author: ZiHang Gao <gaozihang@zhangyue.com>                          |
  +----------------------------------------------------------------------+
*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
#include "ext/standard/php_var.h" /* for serialize */
#include "ext/standard/php_smart_str.h" /* for smart_str */
#include "php_inprocess_store.h"

static int le_inprocess_store;

HashTable inprocess_store_content_ht;

struct content {
    zval *zv_p;
    long expire;
    int type;
};


//serialize array or object
static inline int inproc_serializer(zval *pzval, smart_str *buf TSRMLS_DC) {
	php_serialize_data_t var_hash;

	PHP_VAR_SERIALIZE_INIT(var_hash);
	php_var_serialize(buf, &pzval, &var_hash TSRMLS_CC);
	PHP_VAR_SERIALIZE_DESTROY(var_hash);

	return 1;
}

//unserialize array or object
zval * inproc_unserializer(char *content, size_t len TSRMLS_DC) {
	zval *return_value;
	const unsigned char *p;
	php_unserialize_data_t var_hash;
	p = (const unsigned char*)content;

	MAKE_STD_ZVAL(return_value);
	ZVAL_FALSE(return_value);
	PHP_VAR_UNSERIALIZE_INIT(var_hash);
	if (!php_var_unserialize(&return_value, &p, p + len,  &var_hash TSRMLS_CC)) {
		zval_ptr_dtor(&return_value);
		PHP_VAR_UNSERIALIZE_DESTROY(var_hash);
		return NULL;
	}
	PHP_VAR_UNSERIALIZE_DESTROY(var_hash);

	return return_value;
}


//if expired return false, else return true
static inline int inproc_check_ttl(char *key, int key_len) {
    struct content *ct;

	if (zend_hash_find(&inprocess_store_expire_ht, key, key_len, (void **)&ct) == SUCCESS
            && *ct->expire > 0) {
        long curr_time = time((time_t*)NULL);
        if (curr_time > *expire_time) { //exired
            zend_hash_del(&inprocess_store_content_ht, key, key_len);
            return SUCCESS;
        }
	}

    return FAILURE;
}

//replace zv_pp with duplicated memory poiter
static int inproc_dup_zval(zval **zv_pp){
    zval *zdest_p;

    switch(Z_TYPE_PP(zv_pp)) {
        case IS_NULL:
        case IS_BOOL:
        case IS_LONG:
        case IS_DOUBLE:
            return 0;
        case IS_CONSTANT:
        case IS_STRING:
            MAKE_STD_ZVAL(zdest_p);
            ZVAL_STRINGL(
                zdest_p,
                pestrndup(Z_STRVAL_PP(zv_pp), Z_STRLEN_PP(zv_pp), 1),
                Z_STRLEN_PP(zv_pp),
                0
            );
            *zv_pp = zdest_p;
            return 0;
        case IS_ARRAY:
#ifdef IS_CONSTANT_ARRAY
		case IS_CONSTANT_ARRAY:
#endif
        case IS_OBJECT:
            {
                smart_str buf = {0};
                if (inproc_serializer(*zv_pp, &buf TSRMLS_CC)) {

                    MAKE_STD_ZVAL(zdest_p);
                    ZVAL_STRINGL(
                        zdest_p,
                        pestrndup(buf.c, buf.len, 1),
                        buf.len,
                        0
                    );
                    *zv_pp = zdest_p;
                }
                smart_str_free(&buf);
            }
            return 0;
        case IS_RESOURCE:
        default:
            php_error(E_ERROR, "inprocess_store wrong zval type");
            break;
    }

    return -1;
}

//release the memory allocated by inproc_dup_zval
static void inproc_dtor_zval(content *ct){
    switch(Z_TYPE_P(ct->zv_p)) {
        case IS_NULL:
        case IS_BOOL:
        case IS_LONG:
        case IS_DOUBLE:
            return;
        case IS_CONSTANT:
        case IS_STRING:
        case IS_ARRAY:
#ifdef IS_CONSTANT_ARRAY
		case IS_CONSTANT_ARRAY:
#endif
        case IS_OBJECT:
            pefree(Z_STRVAL_P(ct->zv_p), 1);
            return;
        case IS_RESOURCE:
        default:
            php_error(E_ERROR, "inprocess_store wrong zval type");
            return;
    }
}

const zend_function_entry inprocess_store_functions[] = {
	PHP_FE(inproc_get,	NULL)
	PHP_FE(inproc_set,	NULL)
	PHP_FE(inproc_inc,	NULL)
	PHP_FE(inproc_del,	NULL)
	PHP_FE(inproc_exists,	NULL)
	PHP_FE_END	/* Must be the last line in inprocess_store_functions[] */
};


zend_module_entry inprocess_store_module_entry = {
#if ZEND_MODULE_API_NO >= 20010901
	STANDARD_MODULE_HEADER,
#endif
	"inprocess_store",
	inprocess_store_functions,
	PHP_MINIT(inprocess_store),
	PHP_MSHUTDOWN(inprocess_store),
	NULL,		/* PHP_RINIT(inprocess_store) */
	NULL,	/* PHP_RSHUTDOWN(inprocess_store) */
	PHP_MINFO(inprocess_store),
#if ZEND_MODULE_API_NO >= 20010901
	PHP_INPROCESS_STORE_VERSION,
#endif
	STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_INPROCESS_STORE
ZEND_GET_MODULE(inprocess_store)
#endif

PHP_MINIT_FUNCTION(inprocess_store)
{
	zend_hash_init(&inprocess_store_content_ht, 0, NULL, (void (*)(void *))inproc_dtor_zval, 1);

	return SUCCESS;
}

PHP_MSHUTDOWN_FUNCTION(inprocess_store)
{
    zend_hash_destroy(&inprocess_store_content_ht);

	return SUCCESS;
}


PHP_MINFO_FUNCTION(inprocess_store)
{
	php_info_print_table_start();
	php_info_print_table_header(2, "Inprocess Store Support", "enabled");
	php_info_print_table_row(2, "Version", "0.0.1");
	php_info_print_table_end();
}

PHP_FUNCTION(inproc_get)
{
	char *key = NULL;
	int key_len;
    zval *zv_p;
    int *type;
    struct content *ct;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &key, &key_len) == FAILURE) {
        return;
	}

    if (inproc_check_ttl(key, key_len) == SUCCESS){
        RETURN_FALSE;
    }

	if (zend_hash_find(&inprocess_store_content_ht, key, key_len, (void **)&ct) == SUCCESS) {

        switch(Z_TYPE_P((*ct)->type)) {
            case IS_NULL:
            case IS_BOOL:
            case IS_LONG:
            case IS_DOUBLE:
            case IS_CONSTANT:
            case IS_STRING:
                break;
            case IS_ARRAY:
#ifdef IS_CONSTANT_ARRAY
            case IS_CONSTANT_ARRAY:
#endif
            case IS_OBJECT:
                zv_p = inproc_unserializer(Z_STRVAL_P(zv_p), Z_STRLEN_P(zv_p));
                break;
            case IS_RESOURCE:
            default:
                php_error(E_ERROR, "inprocess_store wrong zval type");
                break;
        }

        RETURN_ZVAL(zv_p, 1, 0);
	}

    RETURN_FALSE;
}

PHP_FUNCTION(inproc_set)
{
	char *key = NULL;
	int key_len;
    zval *zv_p = NULL;
    long expire = 0;
    struct content *ct;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "sz|l", &key, &key_len, &zv_p, &expire) == FAILURE) {
        return;
    }
    
    switch(Z_TYPE_P(zv_p)) {
        
        case IS_NULL:
        case IS_BOOL:
        case IS_LONG:
        case IS_DOUBLE:
        case IS_CONSTANT:
        case IS_STRING:
            break;
        case IS_ARRAY:
#ifdef IS_CONSTANT_ARRAY
        case IS_CONSTANT_ARRAY:
#endif
        case IS_OBJECT:
            ct->type = Z_TYPE_P(zv_p);
            break;
        case IS_RESOURCE:
        default:
            php_error(E_ERROR, "inprocess_store wrong zval type");
            break;
    }
    
    inproc_dup_zval(&zv_p);
    
    ct->zv_p = zv_p;
    
    if (expire) {
        long curr_time = time((time_t*)NULL);
        expire += curr_time;
        ct->expire = expire;
    }
    
    if (zend_hash_update(&inprocess_store_content_ht, key, key_len, (void *)&ct, sizeof(content), NULL) == FAILURE) {
        RETURN_FALSE;
    }

    RETURN_TRUE;
}

PHP_FUNCTION(inproc_inc)
{
	char *key = NULL;
	long step = 1;
	zval *zv_p;
	int key_len;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "sl", &key, &key_len, &step) == FAILURE) {
		return;
	}

	if (zend_hash_exists(&inprocess_store_content_ht, key, key_len)) {
        if (inproc_check_ttl(key, key_len) == FAILURE) {
            RETURN_FALSE;
        }

        if (zend_hash_find(&inprocess_store_content_ht, key, key_len, (void **)&zv_p) == SUCCESS) {
            if (Z_TYPE_P(zv_p) != IS_LONG) {
                php_error(E_ERROR, "inproc_inc require long zval");
                RETURN_FALSE;
            }

            Z_LVAL_P(zv_p) += step;

            RETURN_ZVAL(zv_p, 1, 0);
        }
	} else {
        MAKE_STD_ZVAL(zv_p);
        ZVAL_LONG(zv_p, step);
        if (zend_hash_add(&inprocess_store_content_ht, key, key_len, (void *)zv_p, sizeof(zval), NULL) == FAILURE) {
            RETURN_FALSE;
        }

        RETURN_ZVAL(zv_p, 1, 0);
    }

    RETURN_FALSE;
}

PHP_FUNCTION(inproc_exists)
{
    char *key = NULL;
	int key_len;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &key, &key_len) == FAILURE) {
        return;
	}

	if (inproc_check_ttl(key, key_len) == FAILURE){
        RETURN_FALSE;
    }

	if (zend_hash_exists(&inprocess_store_content_ht, key, key_len)) {
        RETURN_TRUE;
	}

    RETURN_FALSE;
}

PHP_FUNCTION(inproc_del)
{
	char *key = NULL;
	int key_len;

	if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &key, &key_len) == FAILURE) {
        return;
	}

	if (zend_hash_exists(&inprocess_store_content_ht, key, key_len)) {
        if (zend_hash_del(&inprocess_store_content_ht, key, key_len) == FAILURE) {
            RETURN_FALSE;
        }
	}

	if (zend_hash_exists(&inprocess_store_type_ht, key, key_len)) {
        if (zend_hash_del(&inprocess_store_type_ht, key, key_len) == FAILURE) {
            RETURN_FALSE;
        }
	}

	if (zend_hash_exists(&inprocess_store_expire_ht, key, key_len)) {
        if (zend_hash_del(&inprocess_store_expire_ht, key, key_len) == FAILURE) {
            RETURN_FALSE;
        }
	}

    RETURN_TRUE;
}

