from distutils.core import setup, Command
from distutils.extension import Extension
from Cython.Distutils import build_ext

from unittest import TextTestRunner, TestLoader
from glob import glob
import os
from os.path import splitext, basename, join as pjoin


class TestCommand(Command):
    """Custom distutils command to run the test suite."""

    user_options = []


    def initialize_options(self):
        self._dir = os.getcwd()


    def finalize_options(self):
        pass


    def run_unittest(self):
        testfiles = []
        for t in glob(pjoin(self._dir, 'tests', '*.py')):
            name = splitext(basename(t))[0]
            if name.startswith('test_'):
                testfiles.append('.'.join(['tests', name] ))
        tests = TestLoader().loadTestsFromNames(testfiles)
        t = TextTestRunner(verbosity = 2)
        t.run(tests)


    def run(self):
        try:
            import homest
        except ImportError:
            print_exec()
            print ("Could not import homest")
            print ("You probably need build pyhomest with 'python setup.py build_ext --inplace' beforehand")
            sys.exit(1)

        return self.run_unittest()


class CleanCommand(Command):
    """Custom distutils command to clean the .so and .pyc files."""

    user_options = []

    def initialize_options(self):
        self._clean_me = []
        for root, dirs, files in os.walk('.'):
            for f in files:
                if f.endswith('.pyc') or f.endswith('.so'):
                    self._clean_me.append(pjoin(root, f))

    def finalize_options(self):
        pass

    def run(self):
        for clean_me in self._clean_me:
            try:
                os.unlink(clean_me)
            except:
                pass

levmar_path = "homest/levmar-2.5"
levmar_sources = ["lm.c", "Axb.c", "misc.c", "lmlec.c",
                    "lmbc.c", "lmblec.c", "lmbleic.c"]
levmar_sources = map(lambda x: levmar_path + '/' + x,
                        levmar_sources)

homest_path = "homest/homest-1.3"
homest_sources = ["calc_2Dhomog_coeffs.c", "homest.c",
                "lqs.c", "linalg.c", "norm.c", "buckets.c"]
homest_sources = map(lambda x: homest_path+'/' + x,
                        homest_sources)

sources = ["homest/homest.pyx"]
sources.extend(levmar_sources)
sources.extend(homest_sources)


long_desc = \
'''
PyHomest is a binding for the homest library.
Homest is library for non-linear homography estimation in C
(http://www.ics.forth.gr/~lourakis/homest/)
'''

setup(
  name = 'pyhomest',
  version = '0.1',
  author = 'Jianhua Cao',
  author_email = 'jianhua.cao@cerisevision.com',
  description = 'Python binding for homest',
  long_description = long_desc,
  download_url = '',
  platforms = 'linux-x64',
  license = 'GPL',
  ext_modules=[
    Extension("homest",
              sources = sources,
              include_dirs = ['homest/levmar-2.5', 'homest/homest-1.3'],
              library_dirs = [levmar_path, homest_path, '/usr/lib/lapack'],
              libraries = ['lapack','blas'],
              define_macros = [],
              undef_macros = [],
              extra_compile_args = ["-O3", "-funroll-loops", "-Wall"],
              extra_link_args = [],
              language = "c"),
    ],
  cmdclass = {'build_ext': build_ext, 'test' : TestCommand },
  classifiers = []
)
