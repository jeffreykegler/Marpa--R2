/*
 * Copyright 2015 Jeffrey Kegler
 * This file is part of Libmarpa.  Libmarpa is free software: you can
 * redistribute it and/or modify it under the terms of the GNU Lesser
 * General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Libmarpa is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser
 * General Public License along with Libmarpa.  If not, see
 * http://www.gnu.org/licenses/.
 */

struct marpa_error_description_s
{
  int error_code;
  const char *name;
  const char *suggested;
};

struct marpa_event_description_s
{
  Marpa_Event_Type event_code;
  const char *name;
  const char *suggested;
};

struct marpa_step_type_description_s
{
  Marpa_Step_Type step_type;
  const char *name;
};

/* vim: set expandtab shiftwidth=4: */
