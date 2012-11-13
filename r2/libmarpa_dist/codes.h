/*
 * Copyright 2012 Jeffrey Kegler
 * This file is part of Marpa::R2.  Marpa::R2 is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Marpa::R2 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Marpa::R2.  If not, see
 * http://www.gnu.org/licenses/.
 */
/*
 * DO NOT EDIT DIRECTLY
 * This file is written by texi2proto.pl
 * It is not intended to be modified directly
 */

/*
 * This file is not part compiled into libmarpa
 * It exists for use by the higher levels,
 * which can either compile it as a C file,
 * or read it a a text file.
 */

struct s_marpa_error_description {
    Marpa_Error_Code error_code;
    const char* name;
    const char* suggested;
};
struct s_marpa_event_description {
    Marpa_Event_Type event_code;
    const char* name;
    const char* suggested;
};
struct s_marpa_step_type_description {
    Marpa_Step_Type step_type;
    const char* name;
};

