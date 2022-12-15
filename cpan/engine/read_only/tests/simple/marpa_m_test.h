/*
 * Copyright 2022 Jeffrey Kegler
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/* Libmarpa method test interface -- marpa_m_test */

#ifndef MARPA_M_TEST_H
#define MARPA_M_TEST_H 1

#include <stdio.h>
#include "marpa.h"

#include "tap/basic.h"

extern Marpa_Symbol_ID S_invalid, S_no_such;
extern Marpa_Rule_ID R_invalid, R_no_such;

/* Marpa method test interface */

const char *marpa_m_error_message (Marpa_Error_Code error_code);

typedef union {
    void *ptr_rv;
    long long_rv;
    unsigned long ulong_rv;
} API_RV;

typedef struct api_test_data {
    Marpa_Grammar g;
    Marpa_Error_Code expected_errcode;
    char *msg;
    API_RV rv_seen;
} API_test_data;

void rv_std_report (API_test_data * td,
		    const char *method, int rv_wanted, Marpa_Error_Code err_wanted);
void rv_code_report (API_test_data * td,
		     const char *method, Marpa_Error_Code err_seen,
		     Marpa_Error_Code err_wanted);
void rv_hidden_report (API_test_data * td, const char *name, int rv_wanted,
		       Marpa_Error_Code err_wanted);
void rv_ptr_report (API_test_data * td, const char *name,
		    Marpa_Error_Code err_wanted);

#define API_STD_TEST0(test_data, rv_wanted, err_wanted, method, object) \
{ \
   test_data.rv_seen.long_rv = method(object); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_STD_TEST0U(test_data, rv_wanted, err_wanted, method, object) \
{ \
   test_data.rv_seen.ulong_rv = method(object); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_STD_TEST1(test_data, rv_wanted, err_wanted, method, object, arg1) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_STD_TEST2(test_data, rv_wanted, err_wanted, method, object, arg1, arg2) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1, arg2); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_STD_TEST3(test_data, rv_wanted, err_wanted, method, object, arg1, arg2, arg3) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1, arg2, arg3); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_STD_TEST5(test_data, rv_wanted, err_wanted, method, object, \
  arg1, arg2, arg3, arg4, arg5) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1, arg2, arg3, arg4, arg5); \
   rv_std_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_CODE_TEST3(test_data, err_wanted, method, object, arg1, arg2, arg3) \
{ \
   Marpa_Error_Code err_seen = method(object, arg1, arg2, arg3); \
   rv_code_report(&test_data, #method , err_seen, err_wanted); \
}

#define API_HIDDEN_TEST1(test_data, rv_wanted, err_wanted, method, object, arg1 ) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1 ); \
   rv_hidden_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_HIDDEN_TEST2(test_data, rv_wanted, err_wanted, method, object, arg1, arg2 ) \
{ \
   test_data.rv_seen.long_rv = method(object, arg1, arg2 ); \
   rv_hidden_report(&test_data, #method , rv_wanted, err_wanted); \
}

#define API_PTR_TEST1(test_data, err_wanted, method, object, arg1 ) \
{ \
   test_data.rv_seen.ptr_rv = method(object, arg1 ); \
   rv_ptr_report(&test_data, #method , err_wanted); \
}

#endif /* MARPA_M_TEST_H */
