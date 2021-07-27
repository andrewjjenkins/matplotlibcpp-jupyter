// Copyright 2021 Andrew Jenkins <andrewjjenkins@gmail.com>
//
// Use of this source code is governed by the MIT
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

#pragma once

// Python headers must be included before any system headers, since
// they define _POSIX_C_SOURCE
#include <Python.h>

#include <matplotlibcpp.h>
#include <nlohmann/json.hpp>

namespace matplotlibcpp {
namespace jupyter {
namespace detail {

struct _interpreter {
  PyObject *s_python_function_io_bytesio_constructor;
  PyObject *s_python_function_io_bufferedwriter_constructor;
  PyObject *s_python_function_base64_b64encode;
  PyObject *s_python_function_json_dumps;

  static _interpreter& get() {
    static _interpreter intr;
    return intr;
  }

  _interpreter() {
    PyObject* iomodname = PyString_FromString("io");
    PyObject* iomod = PyImport_Import(iomodname);

    s_python_function_io_bytesio_constructor = PyObject_GetAttrString(iomod, "BytesIO");
    s_python_function_io_bufferedwriter_constructor = PyObject_GetAttrString(iomod, "BufferedWriter");
    Py_DECREF(iomodname);

    PyObject* base64modname = PyString_FromString("base64");
    PyObject* base64mod = PyImport_Import(base64modname);
    s_python_function_base64_b64encode = PyObject_GetAttrString(base64mod, "b64encode");
    Py_DECREF(base64modname);

    PyObject* jsonmodname = PyString_FromString("json");
    PyObject* jsonmod = PyImport_Import(jsonmodname);
    s_python_function_json_dumps = PyObject_GetAttrString(jsonmod, "dumps");
    Py_DECREF(jsonmodname);
  }

  ~_interpreter() {
    Py_Finalize();
  }
};

} //namespace detail

struct shown {
  std::string imgbytes;
};

inline shown show() {
  namespace md = ::matplotlibcpp::detail;
  auto& intr = detail::_interpreter::get();
  auto& mplIntr = md::_interpreter::get();

  PyObject* res;
  
  /*
   * raw = io.BytesIO()
   * out = io.BufferedWriter(raw)
   *
   * plt.savefig(out)
   * out.flush()
   *
   * res = base64.b64encode(out.raw.getvalue())
   */
  PyObject* raw = PyObject_Call(
    intr.s_python_function_io_bytesio_constructor,
    mplIntr.s_python_empty_tuple,
    NULL
  );
  if (!raw) throw std::runtime_error("jupyter::show(): Call to BytesIO() failed.");

  PyObject* buffwriteargs = PyTuple_Pack(1, raw);
  Py_DECREF(raw);
  if (!buffwriteargs) throw std::runtime_error("jupyter::show(): Creating args to BufferedWriter() failed.");
  PyObject* out = PyObject_Call(
    intr.s_python_function_io_bufferedwriter_constructor,
    buffwriteargs,
    NULL
  );
  Py_DECREF(buffwriteargs);
  if (!out) throw std::runtime_error("jupyter::show(): Call to BytesIO() failed.");

  PyObject* savefigargs = PyTuple_Pack(1, out);
  if (!savefigargs) {
    Py_DECREF(out);
    throw std::runtime_error("jupyter::show(): Creating args to savefig() failed.");
  }
  // s_python_function_save is actually "savefig()"
  res = PyObject_Call(mplIntr.s_python_function_save, savefigargs, NULL);
  Py_DECREF(savefigargs);
  if (res != Py_None) {
    Py_DECREF(out);
    throw std::runtime_error("jupyter::show(): Call to savefig() failed.");
  }
  Py_DECREF(res);

  res = PyObject_CallMethod(out, "flush", NULL);
  Py_DECREF(savefigargs);
  if (res != Py_None) {
    Py_DECREF(out);
    throw std::runtime_error("jupyter::show(): Call to flush() failed.");
  }
  Py_DECREF(res);

  PyObject* outraw = PyObject_GetAttrString(out, "raw");
  if (!outraw) {
    Py_DECREF(out);
    throw std::runtime_error("jupyter::show(): Could not get out.raw.");
  }
  PyObject* rawbytes = PyObject_CallMethod(raw, "getvalue", NULL);
  Py_DECREF(outraw);
  Py_DECREF(out);
  if (!rawbytes) throw std::runtime_error("jupyter::show(): Call to out.raw.getBytes() failed.");

  PyObject* b64bytesargs = PyTuple_Pack(1, rawbytes);
  if (!b64bytesargs) throw std::runtime_error("jupyter::show(): Creating args to b64encode() failed.");
  PyObject* b64bytes = PyObject_Call(
    intr.s_python_function_base64_b64encode,
    b64bytesargs,
    NULL
  );
  Py_DECREF(b64bytesargs);
  if (!b64bytes) throw std::runtime_error("jupyter::show(): Call to b64encode() failed.");


  const char *b64bytes_cstr = PyBytes_AsString(b64bytes);
  shown s;
  s.imgbytes = std::string(b64bytes_cstr);
  Py_DECREF(b64bytes);
  if (!b64bytes_cstr) {
    throw std::runtime_error("jupyter::show(): Converting image to bytes failed.");
  }

  return s;
}

inline nlohmann::json mime_bundle_repr(const shown &s) {
  auto bundle = nlohmann::json::object();
  bundle["image/png"] = s.imgbytes;
  return bundle;
}

} //namespace jupyter
} //namespace matplotlibcpp
