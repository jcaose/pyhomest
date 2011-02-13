import sys, os
from unittest import TestCase
import numpy
import homest


class TestSimple(TestCase):

    def setUp(self):
        fn = 'tests/matches.txt'
        fp = open(fn, 'r')
        pts_pairs = []

        for line in fp:
            a = map(float, line.split())
            b = (a[0],a[1]), (a[2],a[3])
            pts_pairs.append(b)

        self.pts_pairs = pts_pairs

        fn = 'tests/H.txt'
        fp = open(fn, 'r')
        h = []
        for line in fp:
            a = map(float, line.split())
            h.append(a)

        self.h = numpy.array(h)


    def tearDown(self):
        pass


    def test_standard(self):
        h0, outliers = homest.homest(self.pts_pairs)
        self.assertTrue(numpy.sum(h0 - self.h)/9.0<0.1)

